import { Module } from '@nestjs/common';
import { ReviewsGatewayController } from './reviews.controller';

@Module({ controllers: [ReviewsGatewayController] })
export class ReviewsGatewayModule {}
