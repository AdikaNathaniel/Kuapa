import { Module } from '@nestjs/common';
import { NotificationsGatewayController } from './notifications.controller';

@Module({ controllers: [NotificationsGatewayController] })
export class NotificationsGatewayModule {}
