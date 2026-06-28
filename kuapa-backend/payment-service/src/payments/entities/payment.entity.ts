import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export enum PaymentMethod {
  MTN_MOBILE_MONEY = 'MTN_MOBILE_MONEY',
  VODAFONE_CASH = 'VODAFONE_CASH',
  AIRTELTIGO_MONEY = 'AIRTELTIGO_MONEY',
  CARD = 'CARD',
}

export enum PaymentStatus {
  PENDING = 'PENDING',
  PROCESSING = 'PROCESSING',
  COMPLETED = 'COMPLETED',
  FAILED = 'FAILED',
  REFUNDED = 'REFUNDED',
}

@Schema({ timestamps: true, toJSON: { virtuals: true, versionKey: false } })
export class Payment {
  @Prop({ required: true })
  orderId: string;

  @Prop({ required: true })
  payerId: string;

  @Prop({ type: Number, required: true })
  amount: number;

  @Prop({ default: 'GHS' })
  currency: string;

  @Prop({ type: String, enum: PaymentMethod, default: PaymentMethod.MTN_MOBILE_MONEY })
  method: PaymentMethod;

  @Prop({ type: String, enum: PaymentStatus, default: PaymentStatus.PENDING })
  status: PaymentStatus;

  @Prop({ unique: true, required: true })
  transactionRef: string;

  @Prop()
  providerRef: string;

  @Prop()
  phoneNumber: string;

  @Prop()
  failureReason: string;
}

export type PaymentDocument = Payment & Document & { id: string };
export const PaymentSchema = SchemaFactory.createForClass(Payment);
