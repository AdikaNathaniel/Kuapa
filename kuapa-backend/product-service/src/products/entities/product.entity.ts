import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { Category } from './category.entity';

export enum ProductUnit {
  KG = 'KG',
  BAG = 'BAG',
  CRATE = 'CRATE',
  BUNCH = 'BUNCH',
  PIECE = 'PIECE',
  BASKET = 'BASKET',
}

@Entity('products')
export class Product {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  farmerId: string;

  @Column()
  farmerName: string;

  @Column({ nullable: true })
  categoryId: string;

  @ManyToOne(() => Category, { nullable: true, eager: true })
  @JoinColumn({ name: 'categoryId' })
  category: Category;

  @Column()
  name: string;

  @Column({ nullable: true })
  description: string;

  @Column({ type: 'decimal', precision: 10, scale: 2 })
  quantity: number;

  @Column({ type: 'varchar', default: ProductUnit.KG })
  unit: ProductUnit;

  @Column({ type: 'decimal', precision: 10, scale: 2 })
  pricePerUnit: number;

  @Column({ default: 'GHS' })
  currency: string;

  @Column('simple-array', { nullable: true })
  images: string[];

  @Column({ nullable: true })
  region: string;

  @Column({ nullable: true })
  district: string;

  @Column({ type: 'decimal', precision: 10, scale: 7, nullable: true })
  locationLat: number;

  @Column({ type: 'decimal', precision: 10, scale: 7, nullable: true })
  locationLng: number;

  @Column({ default: true })
  isAvailable: boolean;

  @Column({ type: 'date', nullable: true })
  harvestDate: Date;

  @Column({ type: 'date', nullable: true })
  expiryDate: Date;

  @Column({ type: 'decimal', precision: 3, scale: 2, default: 0 })
  rating: number;

  @Column({ default: 0 })
  totalOrders: number;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
