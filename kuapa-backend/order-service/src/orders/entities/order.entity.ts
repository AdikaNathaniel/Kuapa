import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';
import { OrderItem, OrderItemSchema } from './order-item.entity';

export enum OrderStatus {
  PENDING = 'PENDING',
  CONFIRMED = 'CONFIRMED',
  PROCESSING = 'PROCESSING',
  READY_FOR_PICKUP = 'READY_FOR_PICKUP',
  IN_TRANSIT = 'IN_TRANSIT',
  DELIVERED = 'DELIVERED',
  CANCELLED = 'CANCELLED',
  DISPUTED = 'DISPUTED',
}

export enum PaymentStatus {
  PENDING = 'PENDING',
  PAID = 'PAID',
  FAILED = 'FAILED',
  REFUNDED = 'REFUNDED',
}

@Schema({ timestamps: true, toJSON: { virtuals: true, versionKey: false } })
export class Order {
  @Prop({ required: true })
  buyerId: string;

  @Prop({ required: true })
  buyerName: string;

  @Prop({ required: true })
  farmerId: string;

  @Prop({ required: true })
  farmerName: string;

  @Prop({ type: String, enum: OrderStatus, default: OrderStatus.PENDING })
  status: OrderStatus;

  @Prop({ type: [OrderItemSchema], default: [] })
  items: OrderItem[];

  @Prop({ type: Number, default: 0 })
  subtotal: number;

  @Prop({ type: Number, default: 0 })
  deliveryFee: number;

  @Prop({ type: Number, default: 0 })
  totalAmount: number;

  @Prop({ default: 'GHS' })
  currency: string;

  @Prop()
  deliveryAddress: string;

  @Prop({ type: Number })
  deliveryLat: number;

  @Prop({ type: Number })
  deliveryLng: number;

  @Prop()
  notes: string;

  @Prop({ type: String, enum: PaymentStatus, default: PaymentStatus.PENDING })
  paymentStatus: PaymentStatus;

  @Prop()
  paymentRef: string;
}

export type OrderDocument = Order & Document & { id: string };
export const OrderSchema = SchemaFactory.createForClass(Order);
