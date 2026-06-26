import { Body, Controller, Get, Param, Post } from '@nestjs/common';
import { MessagePattern, Payload } from '@nestjs/microservices';
import { ApiTags } from '@nestjs/swagger';
import { PaymentsService } from './payments.service';
import { PaymentMethod } from './entities/payment.entity';

@ApiTags('Payments')
@Controller('payments')
export class PaymentsController {
  constructor(private readonly paymentsService: PaymentsService) {}

  @Post('initiate')
  initiate(@Body() data: { orderId: string; payerId: string; amount: number; method: PaymentMethod; phoneNumber?: string }) {
    return this.paymentsService.initiatePayment(data);
  }

  @Get(':id/status')
  getStatus(@Param('id') id: string) {
    return this.paymentsService.getPaymentStatus(id);
  }

  @Get('user/:payerId')
  getUserPayments(@Param('payerId') payerId: string) {
    return this.paymentsService.getUserPayments(payerId);
  }

  @Get('order/:orderId')
  getOrderPayments(@Param('orderId') orderId: string) {
    return this.paymentsService.getOrderPayments(orderId);
  }

  @Post('webhook')
  webhook(@Body() body: any) {
    return this.paymentsService.handleWebhook(body);
  }

  @MessagePattern('PAYMENT_INITIATE')
  tcpInitiate(@Payload() data: any) {
    return this.paymentsService.initiatePayment(data);
  }

  @MessagePattern('PAYMENT_STATUS')
  tcpStatus(@Payload() data: { id: string }) {
    return this.paymentsService.getPaymentStatus(data.id);
  }

  @MessagePattern('PAYMENT_USER_HISTORY')
  tcpHistory(@Payload() data: { payerId: string }) {
    return this.paymentsService.getUserPayments(data.payerId);
  }
}
