import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { UsersController } from './users.controller';
import { UsersService } from './users.service';
import { FarmerProfile, FarmerProfileSchema } from './entities/farmer-profile.entity';
import { BuyerProfile, BuyerProfileSchema } from './entities/buyer-profile.entity';
import { TransporterProfile, TransporterProfileSchema } from './entities/transporter-profile.entity';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: FarmerProfile.name, schema: FarmerProfileSchema },
      { name: BuyerProfile.name, schema: BuyerProfileSchema },
      { name: TransporterProfile.name, schema: TransporterProfileSchema },
    ]),
  ],
  controllers: [UsersController],
  providers: [UsersService],
})
export class UsersModule {}
