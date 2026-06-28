import { Inject, Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { ClientProxy } from '@nestjs/microservices';
import { Order, OrderDocument, OrderStatus } from './entities/order.entity';
import { CreateOrderDto } from './dto/create-order.dto';

@Injectable()
export class OrdersService {
  constructor(
    @InjectModel(Order.name) private orderModel: Model<OrderDocument>,
    @Inject('PRODUCT_SERVICE') private productClient: ClientProxy,
    @Inject('NOTIFICATION_SERVICE') private notificationClient: ClientProxy,
  ) {}

  async create(dto: CreateOrderDto) {
    const items = dto.items.map((i) => ({
      productId: i.productId,
      productName: i.productName,
      quantity: i.quantity,
      unit: i.unit,
      unitPrice: i.unitPrice,
      totalPrice: parseFloat((i.quantity * i.unitPrice).toFixed(2)),
    }));

    const subtotal = parseFloat(items.reduce((sum, i) => sum + i.totalPrice, 0).toFixed(2));

    const saved = await new this.orderModel({
      ...dto,
      items,
      subtotal,
      totalAmount: subtotal,
    }).save() as OrderDocument;

    for (const item of dto.items) {
      this.productClient.emit('PRODUCT_UPDATE_STATS', { id: item.productId, sold: item.quantity });
    }

    this.notificationClient.emit('NOTIFY_NEW_ORDER', {
      userId: dto.farmerId,
      orderId: saved.id,
      buyerName: dto.buyerName,
    });

    return saved;
  }

  async findBuyerOrders(buyerId: string) {
    return this.orderModel.find({ buyerId }).sort({ createdAt: -1 });
  }

  async findFarmerOrders(farmerId: string) {
    return this.orderModel.find({ farmerId }).sort({ createdAt: -1 });
  }

  async findOne(id: string) {
    const order = await this.orderModel.findById(id);
    if (!order) throw new NotFoundException('Order not found');
    return order;
  }

  async updateStatus(id: string, status: OrderStatus, actorId: string) {
    const order = await this.findOne(id);
    await this.orderModel.findByIdAndUpdate(id, { status });

    const notifyUserId = actorId === order.farmerId ? order.buyerId : order.farmerId;
    this.notificationClient.emit('NOTIFY_ORDER_STATUS', { userId: notifyUserId, orderId: id, status });

    return this.findOne(id);
  }

  async updatePaymentStatus(id: string, paymentStatus: string, paymentRef?: string) {
    await this.orderModel.findByIdAndUpdate(id, { paymentStatus, paymentRef });
    if (paymentStatus === 'PAID') {
      await this.updateStatus(id, OrderStatus.CONFIRMED, 'system');
    }
    return this.findOne(id);
  }

  async getOrderStats(farmerId: string) {
    const [total, pending, delivered] = await Promise.all([
      this.orderModel.countDocuments({ farmerId }),
      this.orderModel.countDocuments({ farmerId, status: OrderStatus.PENDING }),
      this.orderModel.countDocuments({ farmerId, status: OrderStatus.DELIVERED }),
    ]);
    return { total, pending, delivered };
  }
}
