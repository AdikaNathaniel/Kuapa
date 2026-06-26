import { Module } from '@nestjs/common';
import { ChatGatewayController } from './chat.controller';

@Module({ controllers: [ChatGatewayController] })
export class ChatGatewayModule {}
