import { ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { FarmerProfile, FarmerProfileDocument } from './entities/farmer-profile.entity';
import { BuyerProfile, BuyerProfileDocument } from './entities/buyer-profile.entity';
import { TransporterProfile, TransporterProfileDocument } from './entities/transporter-profile.entity';
import {
  CreateBuyerProfileDto,
  CreateFarmerProfileDto,
  CreateTransporterProfileDto,
} from './dto/create-profile.dto';

@Injectable()
export class UsersService {
  constructor(
    @InjectModel(FarmerProfile.name) private farmerModel: Model<FarmerProfileDocument>,
    @InjectModel(BuyerProfile.name) private buyerModel: Model<BuyerProfileDocument>,
    @InjectModel(TransporterProfile.name) private transporterModel: Model<TransporterProfileDocument>,
  ) {}

  async createFarmerProfile(dto: CreateFarmerProfileDto) {
    const existing = await this.farmerModel.findOne({ userId: dto.userId });
    if (existing) throw new ConflictException('Farmer profile already exists');
    return new this.farmerModel(dto).save();
  }

  async getFarmerProfile(userId: string) {
    const profile = await this.farmerModel.findOne({ userId });
    if (!profile) throw new NotFoundException('Farmer profile not found');
    return profile;
  }

  async getFarmerById(id: string) {
    return this.farmerModel.findById(id);
  }

  async updateFarmerProfile(userId: string, data: Partial<FarmerProfile>) {
    await this.farmerModel.findOneAndUpdate({ userId }, data);
    return this.getFarmerProfile(userId);
  }

  async getFarmers(region?: string) {
    const filter: any = {};
    if (region) filter.region = new RegExp(region, 'i');
    return this.farmerModel.find(filter).sort({ rating: -1 });
  }

  async createBuyerProfile(dto: CreateBuyerProfileDto) {
    const existing = await this.buyerModel.findOne({ userId: dto.userId });
    if (existing) throw new ConflictException('Buyer profile already exists');
    return new this.buyerModel(dto).save();
  }

  async getBuyerProfile(userId: string) {
    const profile = await this.buyerModel.findOne({ userId });
    if (!profile) throw new NotFoundException('Buyer profile not found');
    return profile;
  }

  async updateBuyerProfile(userId: string, data: Partial<BuyerProfile>) {
    await this.buyerModel.findOneAndUpdate({ userId }, data);
    return this.getBuyerProfile(userId);
  }

  async createTransporterProfile(dto: CreateTransporterProfileDto) {
    const existing = await this.transporterModel.findOne({ userId: dto.userId });
    if (existing) throw new ConflictException('Transporter profile already exists');
    return new this.transporterModel(dto).save();
  }

  async getTransporterProfile(userId: string) {
    const profile = await this.transporterModel.findOne({ userId });
    if (!profile) throw new NotFoundException('Transporter profile not found');
    return profile;
  }

  async updateTransporterProfile(userId: string, data: Partial<TransporterProfile>) {
    await this.transporterModel.findOneAndUpdate({ userId }, data);
    return this.getTransporterProfile(userId);
  }

  async getAvailableTransporters(region?: string) {
    const filter: any = { isAvailable: true };
    if (region) filter.region = new RegExp(region, 'i');
    return this.transporterModel.find(filter).sort({ rating: -1 });
  }

  async updateTransporterLocation(userId: string, lat: number, lng: number) {
    await this.transporterModel.findOneAndUpdate({ userId }, { currentLat: lat, currentLng: lng });
    return { success: true };
  }

  async updateTransporterAvailability(userId: string, isAvailable: boolean) {
    await this.transporterModel.findOneAndUpdate({ userId }, { isAvailable });
    return { success: true };
  }

  async updateRating(userId: string, role: string, newRating: number) {
    const updateAvg = async (model: Model<any>) => {
      const profile = await model.findOne({ userId });
      if (profile) {
        const total = profile.totalReviews + 1;
        const avg = parseFloat(((profile.rating * profile.totalReviews + newRating) / total).toFixed(2));
        await model.findOneAndUpdate({ userId }, { rating: avg, totalReviews: total });
      }
    };

    if (role === 'FARMER') await updateAvg(this.farmerModel);
    else if (role === 'BUYER') await updateAvg(this.buyerModel);
    else if (role === 'TRANSPORTER') await updateAvg(this.transporterModel);

    return { success: true };
  }
}
