import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Notification, NotificationType } from './entities/notification.entity';
import { FcmToken } from './entities/fcm-token.entity';

@Injectable()
export class NotificationsService {
  constructor(
    @InjectRepository(Notification) private notifRepo: Repository<Notification>,
    @InjectRepository(FcmToken) private fcmRepo: Repository<FcmToken>,
  ) {}

  async createNotification(userId: string, title: string, body: string, type: NotificationType, referenceId?: string, data?: object) {
    const notif = this.notifRepo.create({ userId, title, body, type, referenceId, data });
    const saved = await this.notifRepo.save(notif);
    await this.sendPush(userId, title, body);
    return saved;
  }

  async getUserNotifications(userId: string, page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    const [data, total] = await this.notifRepo.findAndCount({
      where: { userId },
      order: { createdAt: 'DESC' },
      skip,
      take: limit,
    });
    return { data, total, unread: data.filter((n) => !n.isRead).length };
  }

  async markRead(id: string) {
    await this.notifRepo.update(id, { isRead: true });
    return { success: true };
  }

  async markAllRead(userId: string) {
    await this.notifRepo.update({ userId, isRead: false }, { isRead: true });
    return { success: true };
  }

  async registerFcmToken(userId: string, token: string, deviceType: string) {
    const existing = await this.fcmRepo.findOne({ where: { token } });
    if (existing) {
      await this.fcmRepo.update(existing.id, { userId });
    } else {
      await this.fcmRepo.save(this.fcmRepo.create({ userId, token, deviceType }));
    }
    return { success: true };
  }

  // ─── Event Handlers (from other services) ────────────────────────────────

  async handleNewOrder(data: { userId: string; orderId: string; buyerName: string }) {
    return this.createNotification(
      data.userId,
      'New Order Received',
      `${data.buyerName} placed a new order`,
      NotificationType.ORDER,
      data.orderId,
    );
  }

  async handleOrderStatus(data: { userId: string; orderId: string; status: string }) {
    return this.createNotification(
      data.userId,
      'Order Status Updated',
      `Your order is now ${data.status.toLowerCase().replace('_', ' ')}`,
      NotificationType.ORDER,
      data.orderId,
    );
  }

  async handleTransportRequest(data: { region: string; requestId: string; pickup: string; delivery: string }) {
    // In production, broadcast to transporters in the region
    console.log(`New transport request in ${data.region}: ${data.pickup} → ${data.delivery}`);
    return { success: true };
  }

  async handleTransportAccepted(data: { userId: string; requestId: string; transporterName: string }) {
    return this.createNotification(
      data.userId,
      'Transport Accepted',
      `${data.transporterName} accepted your transport request`,
      NotificationType.TRANSPORT,
      data.requestId,
    );
  }

  async handleTransportStatus(data: { userId: string; requestId: string; status: string }) {
    return this.createNotification(
      data.userId,
      'Delivery Update',
      `Your delivery is now ${data.status.toLowerCase().replace('_', ' ')}`,
      NotificationType.TRANSPORT,
      data.requestId,
    );
  }

  async handleNewMessage(data: { userId: string; senderName: string; conversationId: string }) {
    return this.createNotification(
      data.userId,
      'New Message',
      `${data.senderName} sent you a message`,
      NotificationType.MESSAGE,
      data.conversationId,
    );
  }

  private async sendPush(userId: string, title: string, body: string) {
    const tokens = await this.fcmRepo.find({ where: { userId } });
    if (tokens.length === 0) return;
    // In production: call FCM API with server key
    console.log(`[FCM] Sending push to ${userId}: ${title}`);
  }
}
