import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

@Schema({ timestamps: true, toJSON: { virtuals: true, versionKey: false } })
export class Conversation {
  @Prop({ required: true })
  participant1Id: string;

  @Prop({ required: true })
  participant1Name: string;

  @Prop({ required: true })
  participant2Id: string;

  @Prop({ required: true })
  participant2Name: string;

  @Prop()
  lastMessage: string;

  @Prop({ type: Date })
  lastMessageAt: Date;
}

export type ConversationDocument = Conversation & Document & { id: string };
export const ConversationSchema = SchemaFactory.createForClass(Conversation);
