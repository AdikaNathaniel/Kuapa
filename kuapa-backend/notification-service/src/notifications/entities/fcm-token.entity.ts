import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

@Schema({ timestamps: true, toJSON: { virtuals: true, versionKey: false } })
export class FcmToken {
  @Prop({ required: true })
  userId: string;

  @Prop({ unique: true, required: true })
  token: string;

  @Prop({ default: 'ANDROID' })
  deviceType: string;
}

export type FcmTokenDocument = FcmToken & Document & { id: string };
export const FcmTokenSchema = SchemaFactory.createForClass(FcmToken);
