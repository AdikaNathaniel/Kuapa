import { Body, Controller, Get, Param, Patch, Post, Query } from '@nestjs/common';
import { MessagePattern, Payload } from '@nestjs/microservices';
import { ApiTags } from '@nestjs/swagger';
import { OrdersService } from './orders.service';
import { CreateOrderDto } from './dto/create-order.dto';
import { OrderStatus } from './entities/order.entity';

@ApiTags('Orders')
@Controller('orders')
export class OrdersController {
  constructor(private readonly ordersService: OrdersService) {}

  @Post()
  create(@Body() dto: CreateOrderDto) {
    return this.ordersService.create(dto);
  }

  @Get('buyer/:buyerId')
  findBuyerOrders(@Param('buyerId') buyerId: string) {
    return this.ordersService.findBuyerOrders(buyerId);
  }

  @Get('farmer/:farmerId')
  findFarmerOrders(@Param('farmerId') farmerId: string) {
    return this.ordersService.findFarmerOrders(farmerId);
  }

  @Get('farmer/:farmerId/stats')
  getOrderStats(@Param('farmerId') farmerId: string) {
    return this.ordersService.getOrderStats(farmerId);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.ordersService.findOne(id);
  }

  @Patch(':id/status')
  updateStatus(
    @Param('id') id: string,
    @Body() body: { status: OrderStatus; actorId: string },
  ) {
    return this.ordersService.updateStatus(id, body.status, body.actorId);
  }

  // ─── TCP ─────────────────────────────────────────────────────────────────

  @MessagePattern('ORDER_CREATE')
  tcpCreate(@Payload() dto: CreateOrderDto) {
    return this.ordersService.create(dto);
  }

  @MessagePattern('ORDER_FIND_BUYER')
  tcpFindBuyer(@Payload() data: { buyerId: string }) {
    return this.ordersService.findBuyerOrders(data.buyerId);
  }

  @MessagePattern('ORDER_FIND_FARMER')
  tcpFindFarmer(@Payload() data: { farmerId: string }) {
    return this.ordersService.findFarmerOrders(data.farmerId);
  }

  @MessagePattern('ORDER_FIND_ONE')
  tcpFindOne(@Payload() data: { id: string }) {
    return this.ordersService.findOne(data.id);
  }

  @MessagePattern('ORDER_UPDATE_STATUS')
  tcpUpdateStatus(@Payload() data: { id: string; status: OrderStatus; actorId: string }) {
    return this.ordersService.updateStatus(data.id, data.status, data.actorId);
  }

  @MessagePattern('ORDER_UPDATE_PAYMENT')
  tcpUpdatePayment(@Payload() data: { id: string; paymentStatus: string; paymentRef?: string }) {
    return this.ordersService.updatePaymentStatus(data.id, data.paymentStatus, data.paymentRef);
  }

  @MessagePattern('ORDER_FARMER_STATS')
  tcpStats(@Payload() data: { farmerId: string }) {
    return this.ordersService.getOrderStats(data.farmerId);
  }
}
