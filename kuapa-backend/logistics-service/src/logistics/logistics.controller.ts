import { Body, Controller, Get, Param, Patch, Post, Query } from '@nestjs/common';
import { MessagePattern, Payload } from '@nestjs/microservices';
import { ApiTags } from '@nestjs/swagger';
import { LogisticsService } from './logistics.service';
import { TransportStatus } from './entities/transport-request.entity';

@ApiTags('Logistics')
@Controller('logistics')
export class LogisticsController {
  constructor(private readonly logisticsService: LogisticsService) {}

  @Post('requests')
  createRequest(@Body() data: any) {
    return this.logisticsService.createRequest(data);
  }

  @Get('requests/available')
  getAvailable(@Query('region') region?: string) {
    return this.logisticsService.getAvailableRequests(region);
  }

  @Get('requests/mine/:requesterId')
  getMyRequests(@Param('requesterId') requesterId: string) {
    return this.logisticsService.getRequesterRequests(requesterId);
  }

  @Get('assignments/:transporterId')
  getAssignments(@Param('transporterId') transporterId: string) {
    return this.logisticsService.getTransporterAssignments(transporterId);
  }

  @Get('requests/:id')
  findOne(@Param('id') id: string) {
    return this.logisticsService.findOne(id);
  }

  @Post('requests/:id/accept')
  accept(@Param('id') id: string, @Body() data: any) {
    return this.logisticsService.acceptRequest(id, data);
  }

  @Patch('requests/:id/status')
  updateStatus(@Param('id') id: string, @Body() body: { status: TransportStatus }) {
    return this.logisticsService.updateStatus(id, body.status);
  }

  @Patch('requests/:id/location')
  updateLocation(@Param('id') id: string, @Body() body: { lat: number; lng: number }) {
    return this.logisticsService.updateTransporterLocation(id, body.lat, body.lng);
  }

  @Get('estimate-cost')
  estimateCost(@Query() q: { pickupLat: number; pickupLng: number; deliveryLat: number; deliveryLng: number }) {
    return this.logisticsService.estimateCost(+q.pickupLat, +q.pickupLng, +q.deliveryLat, +q.deliveryLng);
  }

  // ─── TCP ─────────────────────────────────────────────────────────────────

  @MessagePattern('LOGISTICS_CREATE_REQUEST')
  tcpCreate(@Payload() data: any) {
    return this.logisticsService.createRequest(data);
  }

  @MessagePattern('LOGISTICS_GET_AVAILABLE')
  tcpGetAvailable(@Payload() data: { region?: string }) {
    return this.logisticsService.getAvailableRequests(data.region);
  }

  @MessagePattern('LOGISTICS_GET_REQUESTER')
  tcpGetRequester(@Payload() data: { requesterId: string }) {
    return this.logisticsService.getRequesterRequests(data.requesterId);
  }

  @MessagePattern('LOGISTICS_GET_TRANSPORTER')
  tcpGetTransporter(@Payload() data: { transporterId: string }) {
    return this.logisticsService.getTransporterAssignments(data.transporterId);
  }

  @MessagePattern('LOGISTICS_FIND_ONE')
  tcpFindOne(@Payload() data: { id: string }) {
    return this.logisticsService.findOne(data.id);
  }

  @MessagePattern('LOGISTICS_ACCEPT')
  tcpAccept(@Payload() data: { requestId: string; transporterData: any }) {
    return this.logisticsService.acceptRequest(data.requestId, data.transporterData);
  }

  @MessagePattern('LOGISTICS_UPDATE_STATUS')
  tcpUpdateStatus(@Payload() data: { requestId: string; status: TransportStatus }) {
    return this.logisticsService.updateStatus(data.requestId, data.status);
  }

  @MessagePattern('LOGISTICS_UPDATE_LOCATION')
  tcpUpdateLocation(@Payload() data: { requestId: string; lat: number; lng: number }) {
    return this.logisticsService.updateTransporterLocation(data.requestId, data.lat, data.lng);
  }

  @MessagePattern('LOGISTICS_ESTIMATE_COST')
  tcpEstimate(@Payload() data: { pickupLat: number; pickupLng: number; deliveryLat: number; deliveryLng: number }) {
    return this.logisticsService.estimateCost(data.pickupLat, data.pickupLng, data.deliveryLat, data.deliveryLng);
  }
}
