import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export enum UserRole {
  FARMER = 'FARMER',
  BUYER = 'BUYER',
  TRANSPORTER = 'TRANSPORTER',
  ADMIN = 'ADMIN',
}

@Schema({ timestamps: true, toJSON: { virtuals: true, versionKey: false } })
export class User {
  @Prop({ unique: true, sparse: true })
  username: string;

  @Prop({ unique: true, sparse: true })
  email: string;

  @Prop({ unique: true, sparse: true })
  phone: string;

  @Prop({ required: true })
  passwordHash: string;

  @Prop({ type: String, enum: UserRole, default: UserRole.BUYER })
  role: UserRole;

  @Prop({ default: false })
  isVerified: boolean;

  @Prop({ default: true })
  isActive: boolean;

  @Prop()
  refreshToken: string;
}

export type UserDocument = User & Document & { id: string };
export const UserSchema = SchemaFactory.createForClass(User);
