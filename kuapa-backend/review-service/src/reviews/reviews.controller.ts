import { Body, Controller, Get, Param, Post } from '@nestjs/common';
import { MessagePattern, Payload } from '@nestjs/microservices';
import { ApiTags } from '@nestjs/swagger';
import { ReviewsService } from './reviews.service';

@ApiTags('Reviews')
@Controller('reviews')
export class ReviewsController {
  constructor(private readonly reviewsService: ReviewsService) {}

  @Post()
  create(@Body() data: any) {
    return this.reviewsService.create(data);
  }

  @Get('user/:userId')
  getForUser(@Param('userId') userId: string) {
    return this.reviewsService.getReviewsForUser(userId);
  }

  @Get('by/:reviewerId')
  getByReviewer(@Param('reviewerId') reviewerId: string) {
    return this.reviewsService.getReviewsByReviewer(reviewerId);
  }

  @MessagePattern('REVIEW_CREATE')
  tcpCreate(@Payload() data: any) {
    return this.reviewsService.create(data);
  }

  @MessagePattern('REVIEW_GET_FOR_USER')
  tcpGetForUser(@Payload() data: { revieweeId: string }) {
    return this.reviewsService.getReviewsForUser(data.revieweeId);
  }

  @MessagePattern('REVIEW_GET_BY_REVIEWER')
  tcpGetByReviewer(@Payload() data: { reviewerId: string }) {
    return this.reviewsService.getReviewsByReviewer(data.reviewerId);
  }
}
