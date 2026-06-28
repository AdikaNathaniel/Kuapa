import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export enum ProductUnit {
  KG = 'KG',
  BAG = 'BAG',
  CRATE = 'CRATE',
  BUNCH = 'BUNCH',
  PIECE = 'PIECE',
  BASKET = 'BASKET',
  TUBER = 'TUBER',
}

@Schema({ timestamps: true, toJSON: { virtuals: true, versionKey: false } })
export class Product {
  @Prop({ required: true })
  farmerId: string;

  @Prop({ required: true })
  farmerName: string;

  @Prop()
  categoryId: string;

  @Prop()
  categoryName: string;

  @Prop({ required: true })
  name: string;

  @Prop()
  description: string;

  @Prop({ type: Number, required: true })
  quantity: number;

  @Prop({ type: String, enum: ProductUnit, default: ProductUnit.KG })
  unit: ProductUnit;

  @Prop({ type: Number, required: true })
  pricePerUnit: number;

  @Prop({ default: 'GHS' })
  currency: string;

  @Prop({ type: [String], default: [] })
  images: string[];

  @Prop()
  region: string;

  @Prop()
  district: string;

  @Prop({ type: Number })
  locationLat: number;

  @Prop({ type: Number })
  locationLng: number;

  @Prop({ default: true })
  isAvailable: boolean;

  @Prop({ type: Date })
  harvestDate: Date;

  @Prop({ type: Date })
  expiryDate: Date;

  @Prop({ type: Number, default: 0 })
  rating: number;

  @Prop({ default: 0 })
  totalOrders: number;
}

export type ProductDocument = Product & Document & { id: string };
export const ProductSchema = SchemaFactory.createForClass(Product);
