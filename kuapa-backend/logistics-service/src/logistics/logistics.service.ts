import { Inject, Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { ClientProxy } from '@nestjs/microservices';
import { TransportRequest, TransportRequestDocument, TransportStatus } from './entities/transport-request.entity';

const COST_PER_KM = 2.5;

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
    @InjectModel(TransportRequest.name) private requestModel: Model<TransportRequestDocument>,
    @Inject('NOTIFICATION_SERVICE') private notificationClient: ClientProxy,
  ) {}

  async createRequest(data: any) {
    let estimatedCost = null;
    if (data.pickupLat && data.deliveryLat) {
      const km = haversineKm(data.pickupLat, data.pickupLng, data.deliveryLat, data.deliveryLng);
      estimatedCost = parseFloat((km * COST_PER_KM).toFixed(2));
    }

    const saved = await new this.requestModel({ ...data, estimatedCost }).save() as TransportRequestDocument;

    this.notificationClient.emit('NOTIFY_NEW_TRANSPORT_REQUEST', {
      region: data.region,
      requestId: saved.id,
      pickup: data.pickupAddress,
      delivery: data.deliveryAddress,
    });

    return saved;
  }

  async getAvailableRequests(region?: string) {
    const filter: any = { status: TransportStatus.PENDING };
    if (region) filter.region = new RegExp(region, 'i');
    return this.requestModel.find(filter).sort({ createdAt: -1 });
  }

  async getRequesterRequests(requesterId: string) {
    return this.requestModel.find({ requesterId }).sort({ createdAt: -1 });
  }

  async getTransporterAssignments(transporterId: string) {
    return this.requestModel
      .find({ 'assignment.transporterId': transporterId })
      .sort({ updatedAt: -1 });
  }

  async findOne(id: string) {
    const req = await this.requestModel.findById(id);
    if (!req) throw new NotFoundException('Transport request not found');
    return req;
  }

  async acceptRequest(requestId: string, transporterData: any) {
    const request = await this.findOne(requestId);
    if (request.status !== TransportStatus.PENDING) {
      throw new Error('Request is no longer available');
    }

    await this.requestModel.findByIdAndUpdate(requestId, {
      status: TransportStatus.ACCEPTED,
      assignment: {
        transporterId: transporterData.transporterId,
        transporterName: transporterData.transporterName,
        transporterPhone: transporterData.transporterPhone,
        vehicleType: transporterData.vehicleType,
        vehicleNumber: transporterData.vehicleNumber,
        acceptedAt: new Date(),
        updatedAt: new Date(),
      },
    });

    this.notificationClient.emit('NOTIFY_TRANSPORT_ACCEPTED', {
      userId: request.requesterId,
      requestId,
      transporterName: transporterData.transporterName,
    });

    return this.findOne(requestId);
  }

  async updateStatus(requestId: string, status: TransportStatus) {
    const request = await this.findOne(requestId);
    const update: any = { status };

    if (status === TransportStatus.PICKED_UP && request.assignment) {
      update['assignment.pickedUpAt'] = new Date();
      update['assignment.updatedAt'] = new Date();
    }
    if (status === TransportStatus.DELIVERED && request.assignment) {
      update['assignment.deliveredAt'] = new Date();
      update['assignment.updatedAt'] = new Date();
    }

    await this.requestModel.findByIdAndUpdate(requestId, update);

    this.notificationClient.emit('NOTIFY_TRANSPORT_STATUS', {
      userId: request.requesterId,
      requestId,
      status,
    });

    return this.findOne(requestId);
  }

  async updateTransporterLocation(requestId: string, lat: number, lng: number) {
    await this.requestModel.findByIdAndUpdate(requestId, {
      'assignment.currentLat': lat,
      'assignment.currentLng': lng,
      'assignment.updatedAt': new Date(),
    });
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
