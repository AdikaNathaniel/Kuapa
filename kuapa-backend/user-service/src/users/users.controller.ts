import { Body, Controller, Get, Param, Patch, Post, Query } from '@nestjs/common';
import { MessagePattern, Payload } from '@nestjs/microservices';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { UsersService } from './users.service';
import {
  CreateBuyerProfileDto,
  CreateFarmerProfileDto,
  CreateTransporterProfileDto,
} from './dto/create-profile.dto';

@ApiTags('Users')
@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  // ─── HTTP ────────────────────────────────────────────────────────────────

  @Post('farmer')
  @ApiOperation({ summary: 'Create farmer profile' })
  createFarmer(@Body() dto: CreateFarmerProfileDto) {
    return this.usersService.createFarmerProfile(dto);
  }

  @Get('farmer/:userId')
  @ApiOperation({ summary: 'Get farmer profile by userId' })
  getFarmer(@Param('userId') userId: string) {
    return this.usersService.getFarmerProfile(userId);
  }

  @Patch('farmer/:userId')
  updateFarmer(@Param('userId') userId: string, @Body() data: any) {
    return this.usersService.updateFarmerProfile(userId, data);
  }

  @Get('farmers')
  @ApiOperation({ summary: 'List all farmers, optionally filtered by region' })
  getFarmers(@Query('region') region?: string) {
    return this.usersService.getFarmers(region);
  }

  @Post('buyer')
  createBuyer(@Body() dto: CreateBuyerProfileDto) {
    return this.usersService.createBuyerProfile(dto);
  }

  @Get('buyer/:userId')
  getBuyer(@Param('userId') userId: string) {
    return this.usersService.getBuyerProfile(userId);
  }

  @Patch('buyer/:userId')
  updateBuyer(@Param('userId') userId: string, @Body() data: any) {
    return this.usersService.updateBuyerProfile(userId, data);
  }

  @Post('transporter')
  createTransporter(@Body() dto: CreateTransporterProfileDto) {
    return this.usersService.createTransporterProfile(dto);
  }

  @Get('transporter/:userId')
  getTransporter(@Param('userId') userId: string) {
    return this.usersService.getTransporterProfile(userId);
  }

  @Patch('transporter/:userId')
  updateTransporter(@Param('userId') userId: string, @Body() data: any) {
    return this.usersService.updateTransporterProfile(userId, data);
  }

  @Get('transporters/available')
  getAvailableTransporters(@Query('region') region?: string) {
    return this.usersService.getAvailableTransporters(region);
  }

  // ─── TCP ─────────────────────────────────────────────────────────────────

  @MessagePattern('USER_CREATE_FARMER_PROFILE')
  tcpCreateFarmer(@Payload() dto: CreateFarmerProfileDto) {
    return this.usersService.createFarmerProfile(dto);
  }

  @MessagePattern('USER_GET_FARMER_PROFILE')
  tcpGetFarmer(@Payload() data: { userId: string }) {
    return this.usersService.getFarmerProfile(data.userId);
  }

  @MessagePattern('USER_CREATE_BUYER_PROFILE')
  tcpCreateBuyer(@Payload() dto: CreateBuyerProfileDto) {
    return this.usersService.createBuyerProfile(dto);
  }

  @MessagePattern('USER_GET_BUYER_PROFILE')
  tcpGetBuyer(@Payload() data: { userId: string }) {
    return this.usersService.getBuyerProfile(data.userId);
  }

  @MessagePattern('USER_CREATE_TRANSPORTER_PROFILE')
  tcpCreateTransporter(@Payload() dto: CreateTransporterProfileDto) {
    return this.usersService.createTransporterProfile(dto);
  }

  @MessagePattern('USER_GET_TRANSPORTER_PROFILE')
  tcpGetTransporter(@Payload() data: { userId: string }) {
    return this.usersService.getTransporterProfile(data.userId);
  }

  @MessagePattern('USER_GET_AVAILABLE_TRANSPORTERS')
  tcpGetTransporters(@Payload() data: { region?: string }) {
    return this.usersService.getAvailableTransporters(data.region);
  }

  @MessagePattern('USER_UPDATE_TRANSPORTER_LOCATION')
  tcpUpdateLocation(@Payload() data: { userId: string; lat: number; lng: number }) {
    return this.usersService.updateTransporterLocation(data.userId, data.lat, data.lng);
  }

  @MessagePattern('USER_UPDATE_TRANSPORTER_AVAILABILITY')
  tcpUpdateAvailability(@Payload() data: { userId: string; isAvailable: boolean }) {
    return this.usersService.updateTransporterAvailability(data.userId, data.isAvailable);
  }

  @MessagePattern('USER_UPDATE_RATING')
  tcpUpdateRating(@Payload() data: { userId: string; role: string; rating: number }) {
    return this.usersService.updateRating(data.userId, data.role, data.rating);
  }
}
