import { Inject, Injectable, NotFoundException, HttpException, HttpStatus } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { ClientProxy } from '@nestjs/microservices';
import axios from 'axios';
import { v4 as uuidv4 } from 'uuid';
import { Payment, PaymentDocument, PaymentMethod, PaymentStatus } from './entities/payment.entity';

const PAYSTACK_BASE = 'https://api.paystack.co';

@Injectable()
export class PaymentsService {
  constructor(
    @InjectModel(Payment.name) private paymentModel: Model<PaymentDocument>,
    @Inject('ORDER_SERVICE') private orderClient: ClientProxy,
  ) {}

  async initiatePayment(data: {
    orderId: string;
    payerId: string;
    payerEmail?: string;
    amount: number;
    method: PaymentMethod;
    phoneNumber?: string;
  }) {
    const transactionRef = `KUAPA-${uuidv4().split('-')[0].toUpperCase()}`;
    const amountInPesewas = Math.round(data.amount * 100);

    const channels = this._paystackChannels(data.method);

    let authorizationUrl: string | undefined;
    let paystackRef = transactionRef;

    try {
      const paystackRes = await axios.post(
        `${PAYSTACK_BASE}/transaction/initialize`,
        {
          email: data.payerEmail || `user-${data.payerId}@kuapa.app`,
          amount: amountInPesewas,
          currency: 'GHS',
          reference: transactionRef,
          channels,
          metadata: {
            orderId: data.orderId,
            payerId: data.payerId,
            method: data.method,
          },
        },
        {
          headers: {
            Authorization: `Bearer ${process.env.PAYSTACK_SECRET_KEY}`,
            'Content-Type': 'application/json',
          },
        },
      );

      authorizationUrl = paystackRes.data?.data?.authorization_url;
      paystackRef = paystackRes.data?.data?.reference ?? transactionRef;
    } catch (err) {
      throw new HttpException(
        err.response?.data?.message || 'Paystack initialization failed',
        err.response?.status || HttpStatus.BAD_GATEWAY,
      );
    }

    const saved = await new this.paymentModel({
      ...data,
      transactionRef: paystackRef,
      authorizationUrl,
      status: PaymentStatus.PENDING,
    }).save() as PaymentDocument;

    return {
      ...saved.toJSON(),
      authorizationUrl,
      message: 'Payment initialized. Open the authorization URL to complete payment.',
    };
  }

  async verifyPayment(reference: string) {
    const payment = await this.paymentModel.findOne({ transactionRef: reference });
    if (!payment) throw new NotFoundException('Payment record not found');

    if (payment.status === PaymentStatus.COMPLETED) {
      return { ...payment.toJSON(), alreadyVerified: true };
    }

    try {
      const res = await axios.get(
        `${PAYSTACK_BASE}/transaction/verify/${reference}`,
        {
          headers: { Authorization: `Bearer ${process.env.PAYSTACK_SECRET_KEY}` },
        },
      );

      const txData = res.data?.data;
      const paystackStatus: string = txData?.status;

      if (paystackStatus === 'success') {
        await this.paymentModel.findByIdAndUpdate(payment.id, {
          status: PaymentStatus.COMPLETED,
          providerRef: txData.id?.toString(),
        });

        this.orderClient.emit('ORDER_UPDATE_PAYMENT', {
          id: payment.orderId,
          paymentStatus: 'PAID',
          paymentRef: reference,
        });

        return { ...payment.toJSON(), status: PaymentStatus.COMPLETED, verified: true };
      }

      if (paystackStatus === 'failed' || paystackStatus === 'abandoned') {
        await this.paymentModel.findByIdAndUpdate(payment.id, {
          status: PaymentStatus.FAILED,
          failureReason: txData?.gateway_response || paystackStatus,
        });
        return { ...payment.toJSON(), status: PaymentStatus.FAILED, verified: false };
      }

      return { ...payment.toJSON(), status: PaymentStatus.PROCESSING, verified: false };
    } catch (err) {
      throw new HttpException(
        err.response?.data?.message || 'Paystack verification failed',
        err.response?.status || HttpStatus.BAD_GATEWAY,
      );
    }
  }

  async handleWebhook(body: any) {
    if (body.event === 'charge.success') {
      const reference = body.data?.reference;
      const payment = await this.paymentModel.findOne({ transactionRef: reference });
      if (payment && payment.status !== PaymentStatus.COMPLETED) {
        await this.paymentModel.findByIdAndUpdate(payment.id, {
          status: PaymentStatus.COMPLETED,
          providerRef: body.data?.id?.toString(),
        });
        this.orderClient.emit('ORDER_UPDATE_PAYMENT', {
          id: payment.orderId,
          paymentStatus: 'PAID',
          paymentRef: reference,
        });
      }
    }
    return { received: true };
  }

  async getPaymentStatus(id: string) {
    const payment = await this.paymentModel.findById(id);
    if (!payment) throw new NotFoundException('Payment not found');
    return payment;
  }

  async getByRef(ref: string) {
    return this.paymentModel.findOne({ transactionRef: ref });
  }

  async getUserPayments(payerId: string) {
    return this.paymentModel.find({ payerId }).sort({ createdAt: -1 });
  }

  async getOrderPayments(orderId: string) {
    return this.paymentModel.find({ orderId });
  }

  private _paystackChannels(method: PaymentMethod): string[] {
    switch (method) {
      case PaymentMethod.MTN_MOBILE_MONEY:
      case PaymentMethod.VODAFONE_CASH:
      case PaymentMethod.AIRTELTIGO_MONEY:
        return ['mobile_money'];
      case PaymentMethod.CARD:
        return ['card'];
      default:
        return ['mobile_money', 'card', 'bank'];
    }
  }
}
