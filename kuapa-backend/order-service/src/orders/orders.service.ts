import { Inject, Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ClientProxy } from '@nestjs/microservices';
import { Order, OrderStatus } from './entities/order.entity';
import { OrderItem } from './entities/order-item.entity';
import { CreateOrderDto } from './dto/create-order.dto';
import { firstValueFrom } from 'rxjs';

@Injectable()
export class OrdersService {
  constructor(
    @InjectRepository(Order) private orderRepo: Repository<Order>,
    @InjectRepository(OrderItem) private itemRepo: Repository<OrderItem>,
    @Inject('PRODUCT_SERVICE') private productClient: ClientProxy,
    @Inject('NOTIFICATION_SERVICE') private notificationClient: ClientProxy,
  ) {}

  async create(dto: CreateOrderDto) {
    const items = dto.items.map((i) => {
      const item = new OrderItem();
      item.productId = i.productId;
      item.productName = i.productName;
      item.quantity = i.quantity;
      item.unit = i.unit;
      item.unitPrice = i.unitPrice;
      item.totalPrice = parseFloat((i.quantity * i.unitPrice).toFixed(2));
      return item;
    });

    const subtotal = items.reduce((sum, i) => sum + Number(i.totalPrice), 0);

    const order = this.orderRepo.create({
      ...dto,
      items,
      subtotal: parseFloat(subtotal.toFixed(2)),
      totalAmount: parseFloat(subtotal.toFixed(2)),
    });

    const saved = await this.orderRepo.save(order);

    // Update product stock for each item
    for (const item of dto.items) {
      this.productClient.emit('PRODUCT_UPDATE_STATS', { id: item.productId, sold: item.quantity });
    }

    // Notify farmer of new order
    this.notificationClient.emit('NOTIFY_NEW_ORDER', {
      userId: dto.farmerId,
      orderId: saved.id,
      buyerName: dto.buyerName,
    });

    return saved;
  }

  async findBuyerOrders(buyerId: string) {
    return this.orderRepo.find({
      where: { buyerId },
      order: { createdAt: 'DESC' },
    });
  }

  async findFarmerOrders(farmerId: string) {
    return this.orderRepo.find({
      where: { farmerId },
      order: { createdAt: 'DESC' },
    });
  }

  async findOne(id: string) {
    const order = await this.orderRepo.findOne({ where: { id } });
    if (!order) throw new NotFoundException('Order not found');
    return order;
  }

  async updateStatus(id: string, status: OrderStatus, actorId: string) {
    const order = await this.findOne(id);
    await this.orderRepo.update(id, { status });

    const notifyUserId = actorId === order.farmerId ? order.buyerId : order.farmerId;
    this.notificationClient.emit('NOTIFY_ORDER_STATUS', {
      userId: notifyUserId,
      orderId: id,
      status,
    });

    return this.findOne(id);
  }

  async updatePaymentStatus(id: string, paymentStatus: string, paymentRef?: string) {
    await this.orderRepo.update(id, { paymentStatus: paymentStatus as any, paymentRef });
    if (paymentStatus === 'PAID') {
      await this.updateStatus(id, OrderStatus.CONFIRMED, 'system');
    }
    return this.findOne(id);
  }

  async getOrderStats(farmerId: string) {
    const total = await this.orderRepo.count({ where: { farmerId } });
    const pending = await this.orderRepo.count({ where: { farmerId, status: OrderStatus.PENDING } });
    const delivered = await this.orderRepo.count({ where: { farmerId, status: OrderStatus.DELIVERED } });
    return { total, pending, delivered };
  }
}
