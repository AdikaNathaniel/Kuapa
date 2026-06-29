import { Body, Controller, Get, Param, Patch, Post, Query } from '@nestjs/common';
import { EventPattern, MessagePattern, Payload } from '@nestjs/microservices';
import { ApiTags } from '@nestjs/swagger';
import { NotificationsService } from './notifications.service';

@ApiTags('Notifications')
@Controller('notifications')
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  @Get(':userId')
  getUserNotifications(@Param('userId') userId: string, @Query('page') page = 1, @Query('limit') limit = 20) {
    return this.notificationsService.getUserNotifications(userId, +page, +limit);
  }

  @Patch(':id/read')
  markRead(@Param('id') id: string) {
    return this.notificationsService.markRead(id);
  }

  @Patch('user/:userId/read-all')
  markAllRead(@Param('userId') userId: string) {
    return this.notificationsService.markAllRead(userId);
  }

  @Post('fcm-token')
  registerToken(@Body() body: { userId: string; token: string; deviceType: string }) {
    return this.notificationsService.registerFcmToken(body.userId, body.token, body.deviceType);
  }

  // ─── TCP Request-Response ────────────────────────────────────────────────

  @MessagePattern('NOTIFICATION_GET_USER')
  tcpGetUser(@Payload() data: { userId: string; page?: number; limit?: number }) {
    return this.notificationsService.getUserNotifications(data.userId, data.page, data.limit);
  }

  @MessagePattern('NOTIFICATION_MARK_READ')
  tcpMarkRead(@Payload() data: { id: string }) {
    return this.notificationsService.markRead(data.id);
  }

  @MessagePattern('NOTIFICATION_MARK_ALL_READ')
  tcpMarkAllRead(@Payload() data: { userId: string }) {
    return this.notificationsService.markAllRead(data.userId);
  }

  @MessagePattern('NOTIFICATION_REGISTER_FCM')
  tcpRegisterFcm(@Payload() data: { userId: string; token: string; deviceType: string }) {
    return this.notificationsService.registerFcmToken(data.userId, data.token, data.deviceType);
  }

  // ─── TCP Events (fired-and-forgotten from other services) ────────────────

  @EventPattern('NOTIFY_NEW_ORDER')
  evtNewOrder(@Payload() data: any) {
    return this.notificationsService.handleNewOrder(data);
  }

  @EventPattern('NOTIFY_ORDER_STATUS')
  evtOrderStatus(@Payload() data: any) {
    return this.notificationsService.handleOrderStatus(data);
  }

  @EventPattern('NOTIFY_NEW_TRANSPORT_REQUEST')
  evtTransportRequest(@Payload() data: any) {
    return this.notificationsService.handleTransportRequest(data);
  }

  @EventPattern('NOTIFY_TRANSPORT_ACCEPTED')
  evtTransportAccepted(@Payload() data: any) {
    return this.notificationsService.handleTransportAccepted(data);
  }

  @EventPattern('NOTIFY_TRANSPORT_STATUS')
  evtTransportStatus(@Payload() data: any) {
    return this.notificationsService.handleTransportStatus(data);
  }

  @EventPattern('NOTIFY_NEW_MESSAGE')
  evtNewMessage(@Payload() data: any) {
    return this.notificationsService.handleNewMessage(data);
  }
}
