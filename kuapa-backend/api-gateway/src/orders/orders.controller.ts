import {
  Body, Controller, Get, Inject, Param, Patch, Post, Request, UseGuards,
} from '@nestjs/common';
import { ClientProxy } from '@nestjs/microservices';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { firstValueFrom } from 'rxjs';
import { AuthGuard } from '../common/guards/auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';

@ApiTags('Orders')
@Controller('orders')
@UseGuards(AuthGuard, RolesGuard)
@ApiBearerAuth()
export class OrdersGatewayController {
  constructor(@Inject('ORDER_SERVICE') private orderClient: ClientProxy) {}

  @Post()
  @Roles('BUYER')
  @ApiOperation({ summary: 'Buyer: place an order' })
  create(@Request() req, @Body() body: any) {
    return firstValueFrom(this.orderClient.send('ORDER_CREATE', { ...body, buyerId: req.user.id }));
  }

  @Get('my-orders')
  @Roles('BUYER')
  @ApiOperation({ summary: "Buyer: get own orders" })
  getMyOrders(@Request() req) {
    return firstValueFrom(this.orderClient.send('ORDER_FIND_BUYER', { buyerId: req.user.id }));
  }

  @Get('farmer-orders')
  @Roles('FARMER')
  @ApiOperation({ summary: "Farmer: get incoming orders" })
  getFarmerOrders(@Request() req) {
    return firstValueFrom(this.orderClient.send('ORDER_FIND_FARMER', { farmerId: req.user.id }));
  }

  @Get('farmer-stats')
  @Roles('FARMER')
  getFarmerStats(@Request() req) {
    return firstValueFrom(this.orderClient.send('ORDER_FARMER_STATS', { farmerId: req.user.id }));
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return firstValueFrom(this.orderClient.send('ORDER_FIND_ONE', { id }));
  }

  @Patch(':id/status')
  @Roles('FARMER', 'BUYER', 'TRANSPORTER')
  @ApiOperation({ summary: 'Update order status' })
  updateStatus(@Request() req, @Param('id') id: string, @Body() body: { status: string }) {
    return firstValueFrom(this.orderClient.send('ORDER_UPDATE_STATUS', { id, status: body.status, actorId: req.user.id }));
  }
}
