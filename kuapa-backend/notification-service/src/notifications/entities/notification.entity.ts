import { Column, CreateDateColumn, Entity, PrimaryGeneratedColumn } from 'typeorm';

export enum NotificationType {
  ORDER = 'ORDER',
  TRANSPORT = 'TRANSPORT',
  MESSAGE = 'MESSAGE',
  PAYMENT = 'PAYMENT',
  SYSTEM = 'SYSTEM',
}

@Entity('notifications')
export class Notification {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  userId: string;

  @Column()
  title: string;

  @Column()
  body: string;

  @Column({ type: 'varchar', default: NotificationType.SYSTEM })
  type: NotificationType;

  @Column({ nullable: true })
  referenceId: string;

  @Column({ nullable: true, type: 'jsonb' })
  data: object;

  @Column({ default: false })
  isRead: boolean;

  @CreateDateColumn()
  createdAt: Date;
}
