import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';
import { TransportAssignment, TransportAssignmentSchema } from './transport-assignment.entity';

export enum TransportStatus {
  PENDING = 'PENDING',
  MATCHED = 'MATCHED',
  ACCEPTED = 'ACCEPTED',
  PICKED_UP = 'PICKED_UP',
  IN_TRANSIT = 'IN_TRANSIT',
  DELIVERED = 'DELIVERED',
  CANCELLED = 'CANCELLED',
}

export enum RequesterType {
  FARMER = 'FARMER',
  BUYER = 'BUYER',
}

@Schema({ timestamps: true, toJSON: { virtuals: true, versionKey: false } })
export class TransportRequest {
  @Prop()
  orderId: string;

  @Prop({ required: true })
  requesterId: string;

  @Prop({ required: true })
  requesterName: string;

  @Prop({ type: String, enum: RequesterType, default: RequesterType.FARMER })
  requesterType: RequesterType;

  @Prop({ required: true })
  pickupAddress: string;

  @Prop({ type: Number })
  pickupLat: number;

  @Prop({ type: Number })
  pickupLng: number;

  @Prop({ required: true })
  deliveryAddress: string;

  @Prop({ type: Number })
  deliveryLat: number;

  @Prop({ type: Number })
  deliveryLng: number;

  @Prop()
  cargoDescription: string;

  @Prop({ type: Number })
  weightKg: number;

  @Prop({ type: String, enum: TransportStatus, default: TransportStatus.PENDING })
  status: TransportStatus;

  @Prop({ type: Number })
  estimatedCost: number;

  @Prop({ type: Number })
  actualCost: number;

  @Prop({ default: 'GHS' })
  currency: string;

  @Prop()
  region: string;

  @Prop({ type: Date })
  scheduledPickupAt: Date;

  @Prop()
  scheduleNote: string;

  @Prop({ type: TransportAssignmentSchema })
  assignment: TransportAssignment;
}

export type TransportRequestDocument = TransportRequest & Document & { id: string };
export const TransportRequestSchema = SchemaFactory.createForClass(TransportRequest);
