import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { LogisticsController } from './logistics.controller';
import { LogisticsService } from './logistics.service';
import { TransportRequest, TransportRequestSchema } from './entities/transport-request.entity';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: TransportRequest.name, schema: TransportRequestSchema }]),
  ],
  controllers: [LogisticsController],
  providers: [LogisticsService],
})
export class LogisticsModule {}
