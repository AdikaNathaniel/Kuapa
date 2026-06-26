import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UsersModule } from './users/users.module';
import { FarmerProfile } from './users/entities/farmer-profile.entity';
import { BuyerProfile } from './users/entities/buyer-profile.entity';
import { TransporterProfile } from './users/entities/transporter-profile.entity';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    TypeOrmModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (cfg: ConfigService) => ({
        type: 'postgres',
        host: cfg.get('DB_HOST', 'localhost'),
        port: cfg.get<number>('DB_PORT', 5432),
        username: cfg.get('DB_USER', 'kuapa'),
        password: cfg.get('DB_PASS', 'kuapa_pass'),
        database: cfg.get('DB_NAME', 'kuapa_users'),
        entities: [FarmerProfile, BuyerProfile, TransporterProfile],
        synchronize: true,
      }),
    }),
    UsersModule,
  ],
})
export class AppModule {}
