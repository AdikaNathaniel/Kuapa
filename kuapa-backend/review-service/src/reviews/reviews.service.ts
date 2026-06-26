import { BadRequestException, Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Review, RevieweeType } from './entities/review.entity';

@Injectable()
export class ReviewsService {
  constructor(@InjectRepository(Review) private reviewRepo: Repository<Review>) {}

  async create(data: {
    reviewerId: string;
    reviewerName: string;
    revieweeId: string;
    revieweeName: string;
    revieweeType: RevieweeType;
    orderId?: string;
    rating: number;
    comment?: string;
  }) {
    if (data.rating < 1 || data.rating > 5) {
      throw new BadRequestException('Rating must be between 1 and 5');
    }

    if (data.orderId) {
      const existing = await this.reviewRepo.findOne({
        where: { reviewerId: data.reviewerId, orderId: data.orderId, revieweeId: data.revieweeId },
      });
      if (existing) throw new BadRequestException('Already reviewed for this order');
    }

    const review = this.reviewRepo.create(data);
    return this.reviewRepo.save(review);
  }

  async getReviewsForUser(revieweeId: string) {
    const reviews = await this.reviewRepo.find({
      where: { revieweeId },
      order: { createdAt: 'DESC' },
    });

    const avg = reviews.length > 0
      ? parseFloat((reviews.reduce((s, r) => s + r.rating, 0) / reviews.length).toFixed(2))
      : 0;

    return { reviews, averageRating: avg, total: reviews.length };
  }

  async getReviewsByReviewer(reviewerId: string) {
    return this.reviewRepo.find({
      where: { reviewerId },
      order: { createdAt: 'DESC' },
    });
  }
}
