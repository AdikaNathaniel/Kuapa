import { Inject, Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { ClientProxy } from '@nestjs/microservices';
import { Payment, PaymentDocument, PaymentMethod, PaymentStatus } from './entities/payment.entity';
import { v4 as uuidv4 } from 'uuid';

@Injectable()
export class PaymentsService {
  constructor(
    @InjectModel(Payment.name) private paymentModel: Model<PaymentDocument>,
    @Inject('ORDER_SERVICE') private orderClient: ClientProxy,
  ) {}

  async initiatePayment(data: {
    orderId: string;
    payerId: string;
    amount: number;
    method: PaymentMethod;
    phoneNumber?: string;
  }) {
    const transactionRef = `AGRO-${uuidv4().split('-')[0].toUpperCase()}`;
    const saved = await new this.paymentModel({ ...data, transactionRef, status: PaymentStatus.PROCESSING }).save() as PaymentDocument;

    setTimeout(() => this.simulatePaymentSuccess(saved.id), 3000);

    return { ...saved.toJSON(), message: 'Payment initiated. You will receive a prompt on your phone.' };
  }

  private async simulatePaymentSuccess(paymentId: string) {
    const payment = await this.paymentModel.findById(paymentId);
    if (!payment) return;

    const providerRef = `PAY-${uuidv4().split('-')[0].toUpperCase()}`;
    await this.paymentModel.findByIdAndUpdate(paymentId, { status: PaymentStatus.COMPLETED, providerRef });

    this.orderClient.emit('ORDER_UPDATE_PAYMENT', {
      id: payment.orderId,
      paymentStatus: 'PAID',
      paymentRef: providerRef,
    });
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

  async handleWebhook(body: any) {
    if (body.event === 'charge.success') {
      const payment = await this.getByRef(body.data?.reference);
      if (payment) {
        await this.paymentModel.findByIdAndUpdate(payment.id, {
          status: PaymentStatus.COMPLETED,
          providerRef: body.data?.id?.toString(),
        });
        this.orderClient.emit('ORDER_UPDATE_PAYMENT', {
          id: payment.orderId,
          paymentStatus: 'PAID',
          paymentRef: body.data?.reference,
        });
      }
    }
    return { received: true };
  }
}
