import { BadRequestException, Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Review, ReviewDocument, RevieweeType } from './entities/review.entity';

@Injectable()
export class ReviewsService {
  constructor(@InjectModel(Review.name) private reviewModel: Model<ReviewDocument>) {}

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
      const existing = await this.reviewModel.findOne({
        reviewerId: data.reviewerId,
        orderId: data.orderId,
        revieweeId: data.revieweeId,
      });
      if (existing) throw new BadRequestException('Already reviewed for this order');
    }

    return new this.reviewModel(data).save();
  }

  async getReviewsForUser(revieweeId: string) {
    const reviews = await this.reviewModel.find({ revieweeId }).sort({ createdAt: -1 });
    const avg = reviews.length > 0
      ? parseFloat((reviews.reduce((s, r) => s + r.rating, 0) / reviews.length).toFixed(2))
      : 0;
    return { reviews, averageRating: avg, total: reviews.length };
  }

  async getReviewsByReviewer(reviewerId: string) {
    return this.reviewModel.find({ reviewerId }).sort({ createdAt: -1 });
  }
}
