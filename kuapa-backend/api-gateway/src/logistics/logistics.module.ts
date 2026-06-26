import { Module } from '@nestjs/common';
import { LogisticsGatewayController } from './logistics.controller';

@Module({ controllers: [LogisticsGatewayController] })
export class LogisticsGatewayModule {}
