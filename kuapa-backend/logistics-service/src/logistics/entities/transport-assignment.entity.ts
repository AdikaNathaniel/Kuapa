import {
  Column,
  Entity,
  JoinColumn,
  OneToOne,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { TransportRequest } from './transport-request.entity';

@Entity('transport_assignments')
export class TransportAssignment {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @OneToOne(() => TransportRequest, (r) => r.assignment)
  @JoinColumn()
  request: TransportRequest;

  @Column()
  transporterId: string;

  @Column()
  transporterName: string;

  @Column({ nullable: true })
  transporterPhone: string;

  @Column({ nullable: true })
  vehicleType: string;

  @Column({ nullable: true })
  vehicleNumber: string;

  @Column({ type: 'decimal', precision: 10, scale: 7, nullable: true })
  currentLat: number;

  @Column({ type: 'decimal', precision: 10, scale: 7, nullable: true })
  currentLng: number;

  @Column({ nullable: true })
  acceptedAt: Date;

  @Column({ nullable: true })
  pickedUpAt: Date;

  @Column({ nullable: true })
  deliveredAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
