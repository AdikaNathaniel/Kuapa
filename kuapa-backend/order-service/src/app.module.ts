import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { MongooseModule } from '@nestjs/mongoose';
import { ClientsModule, Transport } from '@nestjs/microservices';
import { OrdersModule } from './orders/orders.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    MongooseModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (cfg: ConfigService) => ({ uri: cfg.get('MONGODB_URI') }),
    }),
    ClientsModule.registerAsync({
      isGlobal: true,
      clients: [
        {
          name: 'PRODUCT_SERVICE',
          inject: [ConfigService],
          useFactory: (cfg: ConfigService) => ({
            transport: Transport.TCP as Transport.TCP,
            options: {
              host: cfg.get('PRODUCT_SERVICE_HOST', 'localhost'),
              port: cfg.get<number>('PRODUCT_SERVICE_PORT', 4003),
            },
          }),
        },
        {
          name: 'NOTIFICATION_SERVICE',
          inject: [ConfigService],
          useFactory: (cfg: ConfigService) => ({
            transport: Transport.TCP as Transport.TCP,
            options: {
              host: cfg.get('NOTIFICATION_SERVICE_HOST', 'localhost'),
              port: cfg.get<number>('NOTIFICATION_SERVICE_PORT', 4006),
            },
          }),
        },
      ],
    }),
    OrdersModule,
  ],
})
export class AppModule {}
