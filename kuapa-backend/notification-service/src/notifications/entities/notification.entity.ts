import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export enum NotificationType {
  ORDER = 'ORDER',
  TRANSPORT = 'TRANSPORT',
  MESSAGE = 'MESSAGE',
  PAYMENT = 'PAYMENT',
  SYSTEM = 'SYSTEM',
}

@Schema({ timestamps: true, toJSON: { virtuals: true, versionKey: false } })
export class Notification {
  @Prop({ required: true })
  userId: string;

  @Prop({ required: true })
  title: string;

  @Prop({ required: true })
  body: string;

  @Prop({ type: String, enum: NotificationType, default: NotificationType.SYSTEM })
  type: NotificationType;

  @Prop()
  referenceId: string;

  @Prop({ type: Object })
  data: object;

  @Prop({ default: false })
  isRead: boolean;
}

export type NotificationDocument = Notification & Document & { id: string };
export const NotificationSchema = SchemaFactory.createForClass(Notification);
