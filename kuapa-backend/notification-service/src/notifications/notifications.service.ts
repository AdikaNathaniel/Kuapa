import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import * as admin from 'firebase-admin';
import { Notification, NotificationDocument, NotificationType } from './entities/notification.entity';
import { FcmToken, FcmTokenDocument } from './entities/fcm-token.entity';

@Injectable()
export class NotificationsService {
  private firebaseApp: admin.app.App | null = null;

  constructor(
    @InjectModel(Notification.name) private notifModel: Model<NotificationDocument>,
    @InjectModel(FcmToken.name) private fcmModel: Model<FcmTokenDocument>,
  ) {
    this._initFirebase();
  }

  private _initFirebase() {
    const projectId  = process.env.FIREBASE_PROJECT_ID;
    const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
    const privateKey  = process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n');

    if (!projectId || !clientEmail || !privateKey) {
      console.warn('[FCM] Firebase credentials not configured — push disabled. Set FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, FIREBASE_PRIVATE_KEY.');
      return;
    }

    try {
      // Reuse existing app if already initialized
      this.firebaseApp = admin.apps.length
        ? admin.app()
        : admin.initializeApp({ credential: admin.credential.cert({ projectId, clientEmail, privateKey }) });
    } catch (e) {
      console.error('[FCM] Failed to initialize Firebase Admin:', e);
    }
  }

  async createNotification(
    userId: string,
    title: string,
    body: string,
    type: NotificationType,
    referenceId?: string,
    data?: object,
  ) {
    const saved = await new this.notifModel({ userId, title, body, type, referenceId, data }).save();
    await this._sendPush(userId, title, body, type, referenceId);
    return saved;
  }

  async getUserNotifications(userId: string, page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    const [data, total] = await Promise.all([
      this.notifModel.find({ userId }).sort({ createdAt: -1 }).skip(skip).limit(limit),
      this.notifModel.countDocuments({ userId }),
    ]);
    return { data, total, unread: await this.notifModel.countDocuments({ userId, isRead: false }) };
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

  // ─── Event handlers ────────────────────────────────────────────────────────

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
      `Your order is now ${data.status.toLowerCase().replace(/_/g, ' ')}`,
      NotificationType.ORDER,
      data.orderId,
    );
  }

  async handleTransportRequest(data: { region: string; requestId: string; pickup: string; delivery: string }) {
    // Broadcast to all available transporters in region (future: query user-service)
    console.log(`[Notify] New transport request in ${data.region}: ${data.pickup} → ${data.delivery}`);
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
    const labels: Record<string, string> = {
      PICKED_UP:  'Cargo has been picked up',
      IN_TRANSIT: 'Your delivery is on the way',
      DELIVERED:  'Your delivery has been delivered',
      CANCELLED:  'Your transport request was cancelled',
    };
    const body = labels[data.status] ?? `Delivery status: ${data.status.toLowerCase().replace(/_/g, ' ')}`;
    return this.createNotification(
      data.userId,
      'Delivery Update',
      body,
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

  // ─── FCM push ──────────────────────────────────────────────────────────────

  private async _sendPush(userId: string, title: string, body: string, type?: string, referenceId?: string) {
    if (!this.firebaseApp) return;

    const tokenDocs = await this.fcmModel.find({ userId });
    if (tokenDocs.length === 0) return;

    const tokens = tokenDocs.map((t) => t.token);
    try {
      const response = await this.firebaseApp.messaging().sendEachForMulticast({
        tokens,
        notification: { title, body },
        data: {
          ...(type        && { type }),
          ...(referenceId && { referenceId }),
        },
        android: { priority: 'high', notification: { sound: 'default', channelId: 'kuapa_notifications' } },
        apns:    { payload: { aps: { sound: 'default', badge: 1 } } },
      });

      // Remove stale tokens
      const staleTokens: string[] = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          const code = resp.error?.code ?? '';
          if (code === 'messaging/registration-token-not-registered' || code === 'messaging/invalid-registration-token') {
            staleTokens.push(tokens[idx]);
          }
        }
      });
      if (staleTokens.length > 0) {
        await this.fcmModel.deleteMany({ token: { $in: staleTokens } });
      }
    } catch (e) {
      console.error('[FCM] sendEachForMulticast failed:', e);
    }
  }
}
