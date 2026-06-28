import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

@Schema({ toJSON: { virtuals: true, versionKey: false } })
export class Category {
  @Prop({ unique: true, required: true })
  name: string;

  @Prop()
  description: string;

  @Prop()
  iconUrl: string;
}

export type CategoryDocument = Category & Document & { id: string };
export const CategorySchema = SchemaFactory.createForClass(Category);
