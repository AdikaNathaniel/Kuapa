import { Column, CreateDateColumn, Entity, PrimaryGeneratedColumn } from 'typeorm';

export enum RevieweeType {
  FARMER = 'FARMER',
  BUYER = 'BUYER',
  TRANSPORTER = 'TRANSPORTER',
}

@Entity('reviews')
export class Review {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  reviewerId: string;

  @Column()
  reviewerName: string;

  @Column()
  revieweeId: string;

  @Column()
  revieweeName: string;

  @Column({ type: 'varchar', default: RevieweeType.FARMER })
  revieweeType: RevieweeType;

  @Column({ nullable: true })
  orderId: string;

  @Column({ type: 'int' })
  rating: number;

  @Column({ nullable: true })
  comment: string;

  @CreateDateColumn()
  createdAt: Date;
}
