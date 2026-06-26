import { Module } from '@nestjs/common';
import { AuthGatewayController } from './auth.controller';

@Module({ controllers: [AuthGatewayController] })
export class AuthGatewayModule {}
