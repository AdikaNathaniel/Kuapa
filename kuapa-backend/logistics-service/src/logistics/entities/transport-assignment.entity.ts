import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

@Schema({ _id: false })
export class TransportAssignment {
  @Prop({ required: true })
  transporterId: string;

  @Prop({ required: true })
  transporterName: string;

  @Prop()
  transporterPhone: string;

  @Prop()
  vehicleType: string;

  @Prop()
  vehicleNumber: string;

  @Prop({ type: Number })
  currentLat: number;

  @Prop({ type: Number })
  currentLng: number;

  @Prop({ type: Date })
  acceptedAt: Date;

  @Prop({ type: Date })
  pickedUpAt: Date;

  @Prop({ type: Date })
  deliveredAt: Date;

  @Prop({ type: Date })
  updatedAt: Date;
}

export const TransportAssignmentSchema = SchemaFactory.createForClass(TransportAssignment);
