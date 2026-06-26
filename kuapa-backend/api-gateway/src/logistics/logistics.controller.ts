import {
  Body, Controller, Get, Inject, Param, Patch, Post, Query, Request, UseGuards,
} from '@nestjs/common';
import { ClientProxy } from '@nestjs/microservices';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { firstValueFrom } from 'rxjs';
import { AuthGuard } from '../common/guards/auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';

@ApiTags('Logistics')
@Controller('logistics')
@UseGuards(AuthGuard, RolesGuard)
@ApiBearerAuth()
export class LogisticsGatewayController {
  constructor(@Inject('LOGISTICS_SERVICE') private logisticsClient: ClientProxy) {}

  @Post('requests')
  @Roles('FARMER', 'BUYER')
  @ApiOperation({ summary: 'Create a transport request' })
  createRequest(@Request() req, @Body() body: any) {
    return firstValueFrom(this.logisticsClient.send('LOGISTICS_CREATE_REQUEST', {
      ...body,
      requesterId: req.user.id,
      requesterType: req.user.role,
    }));
  }

  @Get('requests/available')
  @Roles('TRANSPORTER')
  @ApiOperation({ summary: 'Transporter: browse available requests' })
  getAvailable(@Query('region') region?: string) {
    return firstValueFrom(this.logisticsClient.send('LOGISTICS_GET_AVAILABLE', { region }));
  }

  @Get('requests/mine')
  @Roles('FARMER', 'BUYER')
  getMyRequests(@Request() req) {
    return firstValueFrom(this.logisticsClient.send('LOGISTICS_GET_REQUESTER', { requesterId: req.user.id }));
  }

  @Get('assignments/mine')
  @Roles('TRANSPORTER')
  @ApiOperation({ summary: 'Transporter: get own assignments' })
  getMyAssignments(@Request() req) {
    return firstValueFrom(this.logisticsClient.send('LOGISTICS_GET_TRANSPORTER', { transporterId: req.user.id }));
  }

  @Get('requests/:id')
  findOne(@Param('id') id: string) {
    return firstValueFrom(this.logisticsClient.send('LOGISTICS_FIND_ONE', { id }));
  }

  @Post('requests/:id/accept')
  @Roles('TRANSPORTER')
  @ApiOperation({ summary: 'Transporter: accept a request' })
  accept(@Request() req, @Param('id') id: string, @Body() body: any) {
    return firstValueFrom(this.logisticsClient.send('LOGISTICS_ACCEPT', {
      requestId: id,
      transporterData: { transporterId: req.user.id, ...body },
    }));
  }

  @Patch('requests/:id/status')
  @Roles('TRANSPORTER')
  updateStatus(@Param('id') id: string, @Body() body: { status: string }) {
    return firstValueFrom(this.logisticsClient.send('LOGISTICS_UPDATE_STATUS', { requestId: id, status: body.status }));
  }

  @Patch('requests/:id/location')
  @Roles('TRANSPORTER')
  updateLocation(@Param('id') id: string, @Body() body: { lat: number; lng: number }) {
    return firstValueFrom(this.logisticsClient.send('LOGISTICS_UPDATE_LOCATION', { requestId: id, ...body }));
  }

  @Get('estimate-cost')
  estimateCost(@Query() q: any) {
    return firstValueFrom(this.logisticsClient.send('LOGISTICS_ESTIMATE_COST', {
      pickupLat: +q.pickupLat, pickupLng: +q.pickupLng,
      deliveryLat: +q.deliveryLat, deliveryLng: +q.deliveryLng,
    }));
  }
}
