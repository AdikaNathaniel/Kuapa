import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

@Schema({ timestamps: true, toJSON: { virtuals: true, versionKey: false } })
export class FarmerProfile {
  @Prop({ unique: true, required: true })
  userId: string;

  @Prop({ required: true })
  fullName: string;

  @Prop()
  phone: string;

  @Prop()
  farmName: string;

  @Prop()
  region: string;

  @Prop()
  district: string;

  @Prop({ type: Number })
  locationLat: number;

  @Prop({ type: Number })
  locationLng: number;

  @Prop({ type: Number })
  farmSizeAcres: number;

  @Prop({ type: [String], default: [] })
  mainCrops: string[];

  @Prop()
  bio: string;

  @Prop()
  avatarUrl: string;

  @Prop({ default: false })
  isVerified: boolean;

  @Prop({ type: Number, default: 0 })
  rating: number;

  @Prop({ default: 0 })
  totalReviews: number;
}

export type FarmerProfileDocument = FarmerProfile & Document & { id: string };
export const FarmerProfileSchema = SchemaFactory.createForClass(FarmerProfile);
