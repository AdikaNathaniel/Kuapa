import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ClientsModule, Transport } from '@nestjs/microservices';
import { PaymentsModule } from './payments/payments.module';
import { Payment } from './payments/entities/payment.entity';

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
        database: cfg.get('DB_NAME', 'kuapa_payments'),
        entities: [Payment],
        synchronize: true,
      }),
    }),
    ClientsModule.registerAsync([
      {
        name: 'ORDER_SERVICE',
        inject: [ConfigService],
        useFactory: (cfg: ConfigService) => ({
          transport: Transport.TCP,
          options: {
            host: cfg.get('ORDER_SERVICE_HOST', 'localhost'),
            port: cfg.get<number>('ORDER_SERVICE_PORT', 4004),
          },
        }),
      },
    ]),
    PaymentsModule,
  ],
})
export class AppModule {}
