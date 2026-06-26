import { Body, Controller, Get, Inject, Param, Patch, Post, Query, Request, UseGuards } from '@nestjs/common';
import { ClientProxy } from '@nestjs/microservices';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { firstValueFrom } from 'rxjs';
import { AuthGuard } from '../common/guards/auth.guard';

@ApiTags('Notifications')
@Controller('notifications')
@UseGuards(AuthGuard)
@ApiBearerAuth()
export class NotificationsGatewayController {
  constructor(@Inject('NOTIFICATION_SERVICE') private notifClient: ClientProxy) {}

  @Get()
  getMyNotifications(@Request() req, @Query('page') page = 1, @Query('limit') limit = 20) {
    return firstValueFrom(this.notifClient.send('NOTIFICATION_GET_USER', { userId: req.user.id, page: +page, limit: +limit }));
  }

  @Patch(':id/read')
  markRead(@Param('id') id: string) {
    return firstValueFrom(this.notifClient.send('NOTIFICATION_MARK_READ', { id }));
  }

  @Patch('read-all')
  markAllRead(@Request() req) {
    return firstValueFrom(this.notifClient.send('NOTIFICATION_MARK_ALL_READ', { userId: req.user.id }));
  }

  @Post('fcm-token')
  registerFcmToken(@Request() req, @Body() body: { token: string; deviceType: string }) {
    return firstValueFrom(this.notifClient.send('NOTIFICATION_REGISTER_FCM', { userId: req.user.id, ...body }));
  }
}
