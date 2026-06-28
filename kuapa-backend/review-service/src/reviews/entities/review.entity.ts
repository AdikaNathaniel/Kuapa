import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export enum RevieweeType {
  FARMER = 'FARMER',
  BUYER = 'BUYER',
  TRANSPORTER = 'TRANSPORTER',
}

@Schema({ timestamps: true, toJSON: { virtuals: true, versionKey: false } })
export class Review {
  @Prop({ required: true })
  reviewerId: string;

  @Prop({ required: true })
  reviewerName: string;

  @Prop({ required: true })
  revieweeId: string;

  @Prop({ required: true })
  revieweeName: string;

  @Prop({ type: String, enum: RevieweeType, default: RevieweeType.FARMER })
  revieweeType: RevieweeType;

  @Prop()
  orderId: string;

  @Prop({ type: Number, required: true })
  rating: number;

  @Prop()
  comment: string;
}

export type ReviewDocument = Review & Document & { id: string };
export const ReviewSchema = SchemaFactory.createForClass(Review);
