import { Column, CreateDateColumn, Entity, PrimaryGeneratedColumn, UpdateDateColumn } from 'typeorm';

export enum VehicleType {
  MOTORCYCLE = 'MOTORCYCLE',
  PICKUP = 'PICKUP',
  MINIVAN = 'MINIVAN',
  TRUCK = 'TRUCK',
}

@Entity('transporter_profiles')
export class TransporterProfile {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  userId: string;

  @Column()
  fullName: string;

  @Column({ nullable: true })
  phone: string;

  @Column({ type: 'varchar', default: VehicleType.PICKUP })
  vehicleType: VehicleType;

  @Column({ nullable: true })
  vehicleNumber: string;

  @Column({ type: 'decimal', nullable: true })
  capacityKg: number;

  @Column({ nullable: true })
  region: string;

  @Column({ type: 'decimal', precision: 10, scale: 7, nullable: true })
  currentLat: number;

  @Column({ type: 'decimal', precision: 10, scale: 7, nullable: true })
  currentLng: number;

  @Column({ default: true })
  isAvailable: boolean;

  @Column({ nullable: true })
  avatarUrl: string;

  @Column({ type: 'decimal', precision: 3, scale: 2, default: 0 })
  rating: number;

  @Column({ default: 0 })
  totalReviews: number;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
