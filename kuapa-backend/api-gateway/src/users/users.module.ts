import { Module } from '@nestjs/common';
import { UsersGatewayController } from './users.controller';

@Module({ controllers: [UsersGatewayController] })
export class UsersGatewayModule {}
