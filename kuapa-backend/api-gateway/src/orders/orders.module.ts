import { Module } from '@nestjs/common';
import { OrdersGatewayController } from './orders.controller';

@Module({ controllers: [OrdersGatewayController] })
export class OrdersGatewayModule {}
