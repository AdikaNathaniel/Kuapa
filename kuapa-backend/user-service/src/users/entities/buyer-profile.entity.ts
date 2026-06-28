import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export enum BusinessType {
  RETAILER = 'RETAILER',
  RESTAURANT = 'RESTAURANT',
  PROCESSOR = 'PROCESSOR',
  EXPORTER = 'EXPORTER',
  HOUSEHOLD = 'HOUSEHOLD',
  OTHER = 'OTHER',
}

@Schema({ timestamps: true, toJSON: { virtuals: true, versionKey: false } })
export class BuyerProfile {
  @Prop({ unique: true, required: true })
  userId: string;

  @Prop({ required: true })
  fullName: string;

  @Prop()
  phone: string;

  @Prop()
  businessName: string;

  @Prop({ type: String, enum: BusinessType, default: BusinessType.HOUSEHOLD })
  businessType: BusinessType;

  @Prop()
  region: string;

  @Prop()
  address: string;

  @Prop({ type: Number })
  locationLat: number;

  @Prop({ type: Number })
  locationLng: number;

  @Prop()
  avatarUrl: string;

  @Prop({ type: Number, default: 0 })
  rating: number;

  @Prop({ default: 0 })
  totalReviews: number;
}

export type BuyerProfileDocument = BuyerProfile & Document & { id: string };
export const BuyerProfileSchema = SchemaFactory.createForClass(BuyerProfile);
