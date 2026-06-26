import { Inject, Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ClientProxy } from '@nestjs/microservices';
import { TransportRequest, TransportStatus } from './entities/transport-request.entity';
import { TransportAssignment } from './entities/transport-assignment.entity';

const COST_PER_KM = 2.5; // GHS per km base rate

function haversineKm(lat1: number, lng1: number, lat2: number, lng2: number) {
  const R = 6371;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLng = ((lng2 - lng1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((lat1 * Math.PI) / 180) * Math.cos((lat2 * Math.PI) / 180) * Math.sin(dLng / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

@Injectable()
export class LogisticsService {
  constructor(
    @InjectRepository(TransportRequest) private requestRepo: Repository<TransportRequest>,
    @InjectRepository(TransportAssignment) private assignmentRepo: Repository<TransportAssignment>,
    @Inject('NOTIFICATION_SERVICE') private notificationClient: ClientProxy,
  ) {}

  async createRequest(data: any) {
    let estimatedCost = null;
    if (data.pickupLat && data.deliveryLat) {
      const km = haversineKm(data.pickupLat, data.pickupLng, data.deliveryLat, data.deliveryLng);
      estimatedCost = parseFloat((km * COST_PER_KM).toFixed(2));
    }

    const request = this.requestRepo.create({ ...data, estimatedCost });
    const saved = await this.requestRepo.save(request);

    this.notificationClient.emit('NOTIFY_NEW_TRANSPORT_REQUEST', {
      region: data.region,
      requestId: saved.id,
      pickup: data.pickupAddress,
      delivery: data.deliveryAddress,
    });

    return saved;
  }

  async getAvailableRequests(region?: string) {
    const query = this.requestRepo
      .createQueryBuilder('r')
      .where('r.status = :status', { status: TransportStatus.PENDING });

    if (region) query.andWhere('r.region ILIKE :region', { region: `%${region}%` });

    return query.orderBy('r.createdAt', 'DESC').getMany();
  }

  async getRequesterRequests(requesterId: string) {
    return this.requestRepo.find({
      where: { requesterId },
      order: { createdAt: 'DESC' },
    });
  }

  async getTransporterAssignments(transporterId: string) {
    return this.assignmentRepo.find({
      where: { transporterId },
      relations: ['request'],
      order: { updatedAt: 'DESC' },
    });
  }

  async findOne(id: string) {
    const req = await this.requestRepo.findOne({ where: { id }, relations: ['assignment'] });
    if (!req) throw new NotFoundException('Transport request not found');
    return req;
  }

  async acceptRequest(requestId: string, transporterData: any) {
    const request = await this.findOne(requestId);
    if (request.status !== TransportStatus.PENDING) {
      throw new Error('Request is no longer available');
    }

    const assignment = this.assignmentRepo.create({
      request,
      transporterId: transporterData.transporterId,
      transporterName: transporterData.transporterName,
      transporterPhone: transporterData.transporterPhone,
      vehicleType: transporterData.vehicleType,
      vehicleNumber: transporterData.vehicleNumber,
      acceptedAt: new Date(),
    });
    await this.assignmentRepo.save(assignment);

    await this.requestRepo.update(requestId, { status: TransportStatus.ACCEPTED });

    this.notificationClient.emit('NOTIFY_TRANSPORT_ACCEPTED', {
      userId: request.requesterId,
      requestId,
      transporterName: transporterData.transporterName,
    });

    return this.findOne(requestId);
  }

  async updateStatus(requestId: string, status: TransportStatus) {
    const request = await this.findOne(requestId);
    await this.requestRepo.update(requestId, { status });

    if (status === TransportStatus.PICKED_UP && request.assignment) {
      await this.assignmentRepo.update(request.assignment.id, { pickedUpAt: new Date() });
    }
    if (status === TransportStatus.DELIVERED && request.assignment) {
      await this.assignmentRepo.update(request.assignment.id, { deliveredAt: new Date() });
    }

    this.notificationClient.emit('NOTIFY_TRANSPORT_STATUS', {
      userId: request.requesterId,
      requestId,
      status,
    });

    return this.findOne(requestId);
  }

  async updateTransporterLocation(requestId: string, lat: number, lng: number) {
    const request = await this.findOne(requestId);
    if (request.assignment) {
      await this.assignmentRepo.update(request.assignment.id, { currentLat: lat, currentLng: lng });
    }
    return { success: true };
  }

  async estimateCost(pickupLat: number, pickupLng: number, deliveryLat: number, deliveryLng: number) {
    const km = haversineKm(pickupLat, pickupLng, deliveryLat, deliveryLng);
    return {
      distanceKm: parseFloat(km.toFixed(2)),
      estimatedCost: parseFloat((km * COST_PER_KM).toFixed(2)),
      currency: 'GHS',
    };
  }
}
