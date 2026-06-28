import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

@Schema({ timestamps: true, toJSON: { virtuals: true, versionKey: false } })
export class Message {
  @Prop({ required: true })
  conversationId: string;

  @Prop({ required: true })
  senderId: string;

  @Prop({ required: true })
  senderName: string;

  @Prop({ required: true })
  content: string;

  @Prop({ default: 'TEXT' })
  type: string;

  @Prop({ default: false })
  isRead: boolean;
}

export type MessageDocument = Message & Document & { id: string };
export const MessageSchema = SchemaFactory.createForClass(Message);
