import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export enum VehicleType {
  MOTORCYCLE = 'MOTORCYCLE',
  PICKUP = 'PICKUP',
  MINIVAN = 'MINIVAN',
  TRUCK = 'TRUCK',
}

@Schema({ timestamps: true, toJSON: { virtuals: true, versionKey: false } })
export class TransporterProfile {
  @Prop({ unique: true, required: true })
  userId: string;

  @Prop({ required: true })
  fullName: string;

  @Prop()
  phone: string;

  @Prop({ type: String, enum: VehicleType, default: VehicleType.PICKUP })
  vehicleType: VehicleType;

  @Prop()
  vehicleNumber: string;

  @Prop({ type: Number })
  capacityKg: number;

  @Prop()
  region: string;

  @Prop({ type: Number })
  currentLat: number;

  @Prop({ type: Number })
  currentLng: number;

  @Prop({ default: true })
  isAvailable: boolean;

  @Prop()
  avatarUrl: string;

  @Prop({ type: Number, default: 0 })
  rating: number;

  @Prop({ default: 0 })
  totalReviews: number;
}

export type TransporterProfileDocument = TransporterProfile & Document & { id: string };
export const TransporterProfileSchema = SchemaFactory.createForClass(TransporterProfile);
