import { Body, Controller, Get, Inject, Param, Post, Request, UseGuards } from '@nestjs/common';
import { ClientProxy } from '@nestjs/microservices';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { firstValueFrom } from 'rxjs';
import { AuthGuard } from '../common/guards/auth.guard';

@ApiTags('Reviews')
@Controller('reviews')
@UseGuards(AuthGuard)
@ApiBearerAuth()
export class ReviewsGatewayController {
  constructor(@Inject('REVIEW_SERVICE') private reviewClient: ClientProxy) {}

  @Post()
  create(@Request() req, @Body() body: any) {
    return firstValueFrom(this.reviewClient.send('REVIEW_CREATE', { ...body, reviewerId: req.user.id }));
  }

  @Get('user/:userId')
  getForUser(@Param('userId') userId: string) {
    return firstValueFrom(this.reviewClient.send('REVIEW_GET_FOR_USER', { revieweeId: userId }));
  }

  @Get('my-reviews')
  getMyReviews(@Request() req) {
    return firstValueFrom(this.reviewClient.send('REVIEW_GET_BY_REVIEWER', { reviewerId: req.user.id }));
  }
}
