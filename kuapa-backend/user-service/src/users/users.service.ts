import { ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { FarmerProfile } from './entities/farmer-profile.entity';
import { BuyerProfile } from './entities/buyer-profile.entity';
import { TransporterProfile } from './entities/transporter-profile.entity';
import {
  CreateBuyerProfileDto,
  CreateFarmerProfileDto,
  CreateTransporterProfileDto,
} from './dto/create-profile.dto';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(FarmerProfile) private farmerRepo: Repository<FarmerProfile>,
    @InjectRepository(BuyerProfile) private buyerRepo: Repository<BuyerProfile>,
    @InjectRepository(TransporterProfile) private transporterRepo: Repository<TransporterProfile>,
  ) {}

  // ─── Farmer ───────────────────────────────────────────────────────────────

  async createFarmerProfile(dto: CreateFarmerProfileDto) {
    const existing = await this.farmerRepo.findOne({ where: { userId: dto.userId } });
    if (existing) throw new ConflictException('Farmer profile already exists');
    const profile = this.farmerRepo.create(dto);
    return this.farmerRepo.save(profile);
  }

  async getFarmerProfile(userId: string) {
    const profile = await this.farmerRepo.findOne({ where: { userId } });
    if (!profile) throw new NotFoundException('Farmer profile not found');
    return profile;
  }

  async getFarmerById(id: string) {
    return this.farmerRepo.findOne({ where: { id } });
  }

  async updateFarmerProfile(userId: string, data: Partial<FarmerProfile>) {
    await this.farmerRepo.update({ userId }, data);
    return this.getFarmerProfile(userId);
  }

  async getFarmers(region?: string) {
    const query = this.farmerRepo.createQueryBuilder('f');
    if (region) query.where('f.region ILIKE :region', { region: `%${region}%` });
    return query.orderBy('f.rating', 'DESC').getMany();
  }

  // ─── Buyer ────────────────────────────────────────────────────────────────

  async createBuyerProfile(dto: CreateBuyerProfileDto) {
    const existing = await this.buyerRepo.findOne({ where: { userId: dto.userId } });
    if (existing) throw new ConflictException('Buyer profile already exists');
    const profile = this.buyerRepo.create(dto);
    return this.buyerRepo.save(profile);
  }

  async getBuyerProfile(userId: string) {
    const profile = await this.buyerRepo.findOne({ where: { userId } });
    if (!profile) throw new NotFoundException('Buyer profile not found');
    return profile;
  }

  async updateBuyerProfile(userId: string, data: Partial<BuyerProfile>) {
    await this.buyerRepo.update({ userId }, data);
    return this.getBuyerProfile(userId);
  }

  // ─── Transporter ──────────────────────────────────────────────────────────

  async createTransporterProfile(dto: CreateTransporterProfileDto) {
    const existing = await this.transporterRepo.findOne({ where: { userId: dto.userId } });
    if (existing) throw new ConflictException('Transporter profile already exists');
    const profile = this.transporterRepo.create(dto);
    return this.transporterRepo.save(profile);
  }

  async getTransporterProfile(userId: string) {
    const profile = await this.transporterRepo.findOne({ where: { userId } });
    if (!profile) throw new NotFoundException('Transporter profile not found');
    return profile;
  }

  async updateTransporterProfile(userId: string, data: Partial<TransporterProfile>) {
    await this.transporterRepo.update({ userId }, data);
    return this.getTransporterProfile(userId);
  }

  async getAvailableTransporters(region?: string) {
    const query = this.transporterRepo.createQueryBuilder('t').where('t.isAvailable = true');
    if (region) query.andWhere('t.region ILIKE :region', { region: `%${region}%` });
    return query.orderBy('t.rating', 'DESC').getMany();
  }

  async updateTransporterLocation(userId: string, lat: number, lng: number) {
    await this.transporterRepo.update({ userId }, { currentLat: lat, currentLng: lng });
    return { success: true };
  }

  async updateTransporterAvailability(userId: string, isAvailable: boolean) {
    await this.transporterRepo.update({ userId }, { isAvailable });
    return { success: true };
  }

  async updateRating(userId: string, role: string, newRating: number) {
    if (role === 'FARMER') {
      const profile = await this.farmerRepo.findOne({ where: { userId } });
      if (profile) {
        const total = profile.totalReviews + 1;
        const avg = (profile.rating * profile.totalReviews + newRating) / total;
        await this.farmerRepo.update({ userId }, { rating: parseFloat(avg.toFixed(2)), totalReviews: total });
      }
    } else if (role === 'BUYER') {
      const profile = await this.buyerRepo.findOne({ where: { userId } });
      if (profile) {
        const total = profile.totalReviews + 1;
        const avg = (profile.rating * profile.totalReviews + newRating) / total;
        await this.buyerRepo.update({ userId }, { rating: parseFloat(avg.toFixed(2)), totalReviews: total });
      }
    } else if (role === 'TRANSPORTER') {
      const profile = await this.transporterRepo.findOne({ where: { userId } });
      if (profile) {
        const total = profile.totalReviews + 1;
        const avg = (profile.rating * profile.totalReviews + newRating) / total;
        await this.transporterRepo.update({ userId }, { rating: parseFloat(avg.toFixed(2)), totalReviews: total });
      }
    }
    return { success: true };
  }
}
