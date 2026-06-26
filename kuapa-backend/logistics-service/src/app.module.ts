import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ClientsModule, Transport } from '@nestjs/microservices';
import { LogisticsModule } from './logistics/logistics.module';
import { TransportRequest } from './logistics/entities/transport-request.entity';
import { TransportAssignment } from './logistics/entities/transport-assignment.entity';

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
        database: cfg.get('DB_NAME', 'kuapa_logistics'),
        entities: [TransportRequest, TransportAssignment],
        synchronize: true,
      }),
    }),
    ClientsModule.registerAsync([
      {
        name: 'NOTIFICATION_SERVICE',
        inject: [ConfigService],
        useFactory: (cfg: ConfigService) => ({
          transport: Transport.TCP,
          options: {
            host: cfg.get('NOTIFICATION_SERVICE_HOST', 'localhost'),
            port: cfg.get<number>('NOTIFICATION_SERVICE_PORT', 4006),
          },
        }),
      },
    ]),
    LogisticsModule,
  ],
})
export class AppModule {}
