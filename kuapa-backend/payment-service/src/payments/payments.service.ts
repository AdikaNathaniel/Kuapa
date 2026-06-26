import { Inject, Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ClientProxy } from '@nestjs/microservices';
import { Payment, PaymentMethod, PaymentStatus } from './entities/payment.entity';
import { v4 as uuidv4 } from 'uuid';
import { firstValueFrom } from 'rxjs';

@Injectable()
export class PaymentsService {
  constructor(
    @InjectRepository(Payment) private paymentRepo: Repository<Payment>,
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

    const payment = this.paymentRepo.create({
      ...data,
      transactionRef,
      status: PaymentStatus.PROCESSING,
    });
    const saved = await this.paymentRepo.save(payment);

    // In production: call Paystack / Hub Mobile Money API
    // For MVP: simulate successful payment after a delay
    setTimeout(() => this.simulatePaymentSuccess(saved.id), 3000);

    return { ...saved, message: 'Payment initiated. You will receive a prompt on your phone.' };
  }

  private async simulatePaymentSuccess(paymentId: string) {
    const payment = await this.paymentRepo.findOne({ where: { id: paymentId } });
    if (!payment) return;

    const providerRef = `PAY-${uuidv4().split('-')[0].toUpperCase()}`;
    await this.paymentRepo.update(paymentId, {
      status: PaymentStatus.COMPLETED,
      providerRef,
    });

    this.orderClient.emit('ORDER_UPDATE_PAYMENT', {
      id: payment.orderId,
      paymentStatus: 'PAID',
      paymentRef: providerRef,
    });
  }

  async getPaymentStatus(id: string) {
    const payment = await this.paymentRepo.findOne({ where: { id } });
    if (!payment) throw new NotFoundException('Payment not found');
    return payment;
  }

  async getByRef(ref: string) {
    return this.paymentRepo.findOne({ where: { transactionRef: ref } });
  }

  async getUserPayments(payerId: string) {
    return this.paymentRepo.find({
      where: { payerId },
      order: { createdAt: 'DESC' },
    });
  }

  async getOrderPayments(orderId: string) {
    return this.paymentRepo.find({ where: { orderId } });
  }

  async handleWebhook(body: any) {
    if (body.event === 'charge.success') {
      const payment = await this.getByRef(body.data?.reference);
      if (payment) {
        await this.paymentRepo.update(payment.id, {
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
