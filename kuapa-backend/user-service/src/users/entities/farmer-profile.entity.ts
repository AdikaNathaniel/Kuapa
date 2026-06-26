import { Column, CreateDateColumn, Entity, PrimaryGeneratedColumn, UpdateDateColumn } from 'typeorm';

@Entity('farmer_profiles')
export class FarmerProfile {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  userId: string;

  @Column()
  fullName: string;

  @Column({ nullable: true })
  phone: string;

  @Column({ nullable: true })
  farmName: string;

  @Column({ nullable: true })
  region: string;

  @Column({ nullable: true })
  district: string;

  @Column({ type: 'decimal', precision: 10, scale: 7, nullable: true })
  locationLat: number;

  @Column({ type: 'decimal', precision: 10, scale: 7, nullable: true })
  locationLng: number;

  @Column({ type: 'decimal', nullable: true })
  farmSizeAcres: number;

  @Column('simple-array', { nullable: true })
  mainCrops: string[];

  @Column({ nullable: true })
  bio: string;

  @Column({ nullable: true })
  avatarUrl: string;

  @Column({ default: false })
  isVerified: boolean;

  @Column({ type: 'decimal', precision: 3, scale: 2, default: 0 })
  rating: number;

  @Column({ default: 0 })
  totalReviews: number;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
