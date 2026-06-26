import { Module } from '@nestjs/common';
import { PaymentsGatewayController } from './payments.controller';

@Module({ controllers: [PaymentsGatewayController] })
export class PaymentsGatewayModule {}
