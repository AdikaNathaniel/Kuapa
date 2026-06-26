import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { MicroserviceOptions, Transport } from '@nestjs/microservices';
import { ValidationPipe } from '@nestjs/common';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.useGlobalPipes(new ValidationPipe({ transform: true, whitelist: true }));
  app.enableCors({ origin: '*' });

  app.connectMicroservice<MicroserviceOptions>({
    transport: Transport.TCP,
    options: { host: '0.0.0.0', port: parseInt(process.env.TCP_PORT || '4007') },
  });

  await app.startAllMicroservices();
  await app.listen(parseInt(process.env.HTTP_PORT || '3007'));
  console.log(`Chat Service HTTP+WS: ${process.env.HTTP_PORT || 3007}`);
}
bootstrap();
