import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { LogisticsController } from './logistics.controller';
import { LogisticsService } from './logistics.service';
import { TransportRequest } from './entities/transport-request.entity';
import { TransportAssignment } from './entities/transport-assignment.entity';

@Module({
  imports: [TypeOrmModule.forFeature([TransportRequest, TransportAssignment])],
  controllers: [LogisticsController],
  providers: [LogisticsService],
})
export class LogisticsModule {}
