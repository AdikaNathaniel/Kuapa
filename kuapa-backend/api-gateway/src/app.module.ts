import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';
import { ClientsModule, Transport } from '@nestjs/microservices';
import { AuthGatewayModule } from './auth/auth.module';
import { UsersGatewayModule } from './users/users.module';
import { ProductsGatewayModule } from './products/products.module';
import { OrdersGatewayModule } from './orders/orders.module';
import { LogisticsGatewayModule } from './logistics/logistics.module';
import { NotificationsGatewayModule } from './notifications/notifications.module';
import { ChatGatewayModule } from './chat/chat.module';
import { ReviewsGatewayModule } from './reviews/reviews.module';
import { PaymentsGatewayModule } from './payments/payments.module';

const tcpClient = (name: string, hostEnv: string, portEnv: string, defaultHost: string, defaultPort: number) => ({
  name,
  inject: [ConfigService],
  useFactory: (cfg: ConfigService) => ({
    transport: Transport.TCP as Transport.TCP,
    options: {
      host: cfg.get(hostEnv, defaultHost),
      port: cfg.get<number>(portEnv, defaultPort),
    },
  }),
});

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    JwtModule.registerAsync({
      global: true,
      inject: [ConfigService],
      useFactory: (cfg: ConfigService) => ({
        secret: cfg.get('JWT_SECRET'),
      }),
    }),
    ClientsModule.registerAsync({
      isGlobal: true,
      clients: [
        tcpClient('AUTH_SERVICE', 'AUTH_SERVICE_HOST', 'AUTH_SERVICE_PORT', 'localhost', 4001),
        tcpClient('USER_SERVICE', 'USER_SERVICE_HOST', 'USER_SERVICE_PORT', 'localhost', 4002),
        tcpClient('PRODUCT_SERVICE', 'PRODUCT_SERVICE_HOST', 'PRODUCT_SERVICE_PORT', 'localhost', 4003),
        tcpClient('ORDER_SERVICE', 'ORDER_SERVICE_HOST', 'ORDER_SERVICE_PORT', 'localhost', 4004),
        tcpClient('LOGISTICS_SERVICE', 'LOGISTICS_SERVICE_HOST', 'LOGISTICS_SERVICE_PORT', 'localhost', 4005),
        tcpClient('NOTIFICATION_SERVICE', 'NOTIFICATION_SERVICE_HOST', 'NOTIFICATION_SERVICE_PORT', 'localhost', 4006),
        tcpClient('CHAT_SERVICE', 'CHAT_SERVICE_HOST', 'CHAT_SERVICE_PORT', 'localhost', 4007),
        tcpClient('REVIEW_SERVICE', 'REVIEW_SERVICE_HOST', 'REVIEW_SERVICE_PORT', 'localhost', 4008),
        tcpClient('PAYMENT_SERVICE', 'PAYMENT_SERVICE_HOST', 'PAYMENT_SERVICE_PORT', 'localhost', 4009),
      ],
    }),
    AuthGatewayModule,
    UsersGatewayModule,
    ProductsGatewayModule,
    OrdersGatewayModule,
    LogisticsGatewayModule,
    NotificationsGatewayModule,
    ChatGatewayModule,
    ReviewsGatewayModule,
    PaymentsGatewayModule,
  ],
})
export class AppModule {}
