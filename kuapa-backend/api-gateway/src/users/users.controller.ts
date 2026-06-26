import {
  Body, Controller, Get, Inject, Param, Patch, Post, Query, Request, UseGuards,
} from '@nestjs/common';
import { ClientProxy } from '@nestjs/microservices';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { firstValueFrom } from 'rxjs';
import { AuthGuard } from '../common/guards/auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';

@ApiTags('Users')
@Controller('users')
@UseGuards(AuthGuard, RolesGuard)
@ApiBearerAuth()
export class UsersGatewayController {
  constructor(@Inject('USER_SERVICE') private userClient: ClientProxy) {}

  // ─── Farmer ───────────────────────────────────────────────────────────────

  @Post('farmer/profile')
  @Roles('FARMER')
  @ApiOperation({ summary: 'Create farmer profile (first time after registration)' })
  createFarmer(@Request() req, @Body() body: any) {
    return firstValueFrom(this.userClient.send('USER_CREATE_FARMER_PROFILE', { ...body, userId: req.user.id }));
  }

  @Get('farmer/profile')
  @Roles('FARMER')
  getMyFarmerProfile(@Request() req) {
    return firstValueFrom(this.userClient.send('USER_GET_FARMER_PROFILE', { userId: req.user.id }));
  }

  @Patch('farmer/profile')
  @Roles('FARMER')
  updateFarmerProfile(@Request() req, @Body() body: any) {
    return firstValueFrom(this.userClient.send('USER_UPDATE_FARMER_PROFILE', { userId: req.user.id, ...body }));
  }

  @Get('farmers')
  @ApiOperation({ summary: 'List farmers by region' })
  getFarmers(@Query('region') region?: string) {
    return firstValueFrom(this.userClient.send('USER_GET_FARMERS', { region }));
  }

  @Get('farmer/:userId')
  getFarmerById(@Param('userId') userId: string) {
    return firstValueFrom(this.userClient.send('USER_GET_FARMER_PROFILE', { userId }));
  }

  // ─── Buyer ────────────────────────────────────────────────────────────────

  @Post('buyer/profile')
  @Roles('BUYER')
  createBuyer(@Request() req, @Body() body: any) {
    return firstValueFrom(this.userClient.send('USER_CREATE_BUYER_PROFILE', { ...body, userId: req.user.id }));
  }

  @Get('buyer/profile')
  @Roles('BUYER')
  getMyBuyerProfile(@Request() req) {
    return firstValueFrom(this.userClient.send('USER_GET_BUYER_PROFILE', { userId: req.user.id }));
  }

  @Patch('buyer/profile')
  @Roles('BUYER')
  updateBuyerProfile(@Request() req, @Body() body: any) {
    return firstValueFrom(this.userClient.send('USER_UPDATE_BUYER_PROFILE', { userId: req.user.id, ...body }));
  }

  // ─── Transporter ──────────────────────────────────────────────────────────

  @Post('transporter/profile')
  @Roles('TRANSPORTER')
  createTransporter(@Request() req, @Body() body: any) {
    return firstValueFrom(this.userClient.send('USER_CREATE_TRANSPORTER_PROFILE', { ...body, userId: req.user.id }));
  }

  @Get('transporter/profile')
  @Roles('TRANSPORTER')
  getMyTransporterProfile(@Request() req) {
    return firstValueFrom(this.userClient.send('USER_GET_TRANSPORTER_PROFILE', { userId: req.user.id }));
  }

  @Patch('transporter/profile')
  @Roles('TRANSPORTER')
  updateTransporterProfile(@Request() req, @Body() body: any) {
    return firstValueFrom(this.userClient.send('USER_UPDATE_TRANSPORTER_PROFILE', { userId: req.user.id, ...body }));
  }

  @Patch('transporter/location')
  @Roles('TRANSPORTER')
  updateLocation(@Request() req, @Body() body: { lat: number; lng: number }) {
    return firstValueFrom(this.userClient.send('USER_UPDATE_TRANSPORTER_LOCATION', { userId: req.user.id, ...body }));
  }

  @Patch('transporter/availability')
  @Roles('TRANSPORTER')
  updateAvailability(@Request() req, @Body() body: { isAvailable: boolean }) {
    return firstValueFrom(this.userClient.send('USER_UPDATE_TRANSPORTER_AVAILABILITY', { userId: req.user.id, ...body }));
  }

  @Get('transporters/available')
  getTransporters(@Query('region') region?: string) {
    return firstValueFrom(this.userClient.send('USER_GET_AVAILABLE_TRANSPORTERS', { region }));
  }
}
