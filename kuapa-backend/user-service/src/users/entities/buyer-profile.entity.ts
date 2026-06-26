import { Column, CreateDateColumn, Entity, PrimaryGeneratedColumn, UpdateDateColumn } from 'typeorm';

export enum BusinessType {
  RETAILER = 'RETAILER',
  RESTAURANT = 'RESTAURANT',
  PROCESSOR = 'PROCESSOR',
  EXPORTER = 'EXPORTER',
  HOUSEHOLD = 'HOUSEHOLD',
  OTHER = 'OTHER',
}

@Entity('buyer_profiles')
export class BuyerProfile {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  userId: string;

  @Column()
  fullName: string;

  @Column({ nullable: true })
  phone: string;

  @Column({ nullable: true })
  businessName: string;

  @Column({ type: 'varchar', default: BusinessType.HOUSEHOLD })
  businessType: BusinessType;

  @Column({ nullable: true })
  region: string;

  @Column({ nullable: true })
  address: string;

  @Column({ type: 'decimal', precision: 10, scale: 7, nullable: true })
  locationLat: number;

  @Column({ type: 'decimal', precision: 10, scale: 7, nullable: true })
  locationLng: number;

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
