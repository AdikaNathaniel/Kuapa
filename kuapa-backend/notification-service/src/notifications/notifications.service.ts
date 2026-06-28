import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Notification, NotificationDocument, NotificationType } from './entities/notification.entity';
import { FcmToken, FcmTokenDocument } from './entities/fcm-token.entity';

@Injectable()
export class NotificationsService {
  constructor(
    @InjectModel(Notification.name) private notifModel: Model<NotificationDocument>,
    @InjectModel(FcmToken.name) private fcmModel: Model<FcmTokenDocument>,
  ) {}

  async createNotification(userId: string, title: string, body: string, type: NotificationType, referenceId?: string, data?: object) {
    const saved = await new this.notifModel({ userId, title, body, type, referenceId, data }).save();
    await this.sendPush(userId, title, body);
    return saved;
  }

  async getUserNotifications(userId: string, page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    const [data, total] = await Promise.all([
      this.notifModel.find({ userId }).sort({ createdAt: -1 }).skip(skip).limit(limit),
      this.notifModel.countDocuments({ userId }),
    ]);
    return { data, total, unread: data.filter((n) => !n.isRead).length };
  }

  async markRead(id: string) {
    await this.notifModel.findByIdAndUpdate(id, { isRead: true });
    return { success: true };
  }

  async markAllRead(userId: string) {
    await this.notifModel.updateMany({ userId, isRead: false }, { isRead: true });
    return { success: true };
  }

  async registerFcmToken(userId: string, token: string, deviceType: string) {
    const existing = await this.fcmModel.findOne({ token });
    if (existing) {
      await this.fcmModel.findByIdAndUpdate(existing.id, { userId });
    } else {
      await new this.fcmModel({ userId, token, deviceType }).save();
    }
    return { success: true };
  }

  async handleNewOrder(data: { userId: string; orderId: string; buyerName: string }) {
    return this.createNotification(data.userId, 'New Order Received', `${data.buyerName} placed a new order`, NotificationType.ORDER, data.orderId);
  }

  async handleOrderStatus(data: { userId: string; orderId: string; status: string }) {
    return this.createNotification(data.userId, 'Order Status Updated', `Your order is now ${data.status.toLowerCase().replace('_', ' ')}`, NotificationType.ORDER, data.orderId);
  }

  async handleTransportRequest(data: { region: string; requestId: string; pickup: string; delivery: string }) {
    console.log(`New transport request in ${data.region}: ${data.pickup} → ${data.delivery}`);
    return { success: true };
  }

  async handleTransportAccepted(data: { userId: string; requestId: string; transporterName: string }) {
    return this.createNotification(data.userId, 'Transport Accepted', `${data.transporterName} accepted your transport request`, NotificationType.TRANSPORT, data.requestId);
  }

  async handleTransportStatus(data: { userId: string; requestId: string; status: string }) {
    return this.createNotification(data.userId, 'Delivery Update', `Your delivery is now ${data.status.toLowerCase().replace('_', ' ')}`, NotificationType.TRANSPORT, data.requestId);
  }

  async handleNewMessage(data: { userId: string; senderName: string; conversationId: string }) {
    return this.createNotification(data.userId, 'New Message', `${data.senderName} sent you a message`, NotificationType.MESSAGE, data.conversationId);
  }

  private async sendPush(userId: string, title: string, body: string) {
    const tokens = await this.fcmModel.find({ userId });
    if (tokens.length === 0) return;
    console.log(`[FCM] Sending push to ${userId}: ${title}`);
  }
}
