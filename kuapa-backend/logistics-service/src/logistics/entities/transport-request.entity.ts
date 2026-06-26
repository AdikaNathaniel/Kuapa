import {
  Column,
  CreateDateColumn,
  Entity,
  OneToOne,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { TransportAssignment } from './transport-assignment.entity';

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

@Entity('transport_requests')
export class TransportRequest {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ nullable: true })
  orderId: string;

  @Column()
  requesterId: string;

  @Column()
  requesterName: string;

  @Column({ type: 'varchar', default: RequesterType.FARMER })
  requesterType: RequesterType;

  @Column()
  pickupAddress: string;

  @Column({ type: 'decimal', precision: 10, scale: 7, nullable: true })
  pickupLat: number;

  @Column({ type: 'decimal', precision: 10, scale: 7, nullable: true })
  pickupLng: number;

  @Column()
  deliveryAddress: string;

  @Column({ type: 'decimal', precision: 10, scale: 7, nullable: true })
  deliveryLat: number;

  @Column({ type: 'decimal', precision: 10, scale: 7, nullable: true })
  deliveryLng: number;

  @Column({ nullable: true })
  cargoDescription: string;

  @Column({ type: 'decimal', nullable: true })
  weightKg: number;

  @Column({ type: 'varchar', default: TransportStatus.PENDING })
  status: TransportStatus;

  @Column({ type: 'decimal', precision: 10, scale: 2, nullable: true })
  estimatedCost: number;

  @Column({ type: 'decimal', precision: 10, scale: 2, nullable: true })
  actualCost: number;

  @Column({ default: 'GHS' })
  currency: string;

  @Column({ nullable: true })
  region: string;

  @OneToOne(() => TransportAssignment, (a) => a.request, { nullable: true, eager: true })
  assignment: TransportAssignment;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
