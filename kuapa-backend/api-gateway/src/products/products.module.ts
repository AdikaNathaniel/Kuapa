import { Module } from '@nestjs/common';
import { ProductsGatewayController } from './products.controller';

@Module({ controllers: [ProductsGatewayController] })
export class ProductsGatewayModule {}
