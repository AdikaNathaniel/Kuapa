import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { MicroserviceOptions, Transport } from '@nestjs/microservices';
import { ValidationPipe } from '@nestjs/common';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.useGlobalPipes(new ValidationPipe({ transform: true, whitelist: true }));
  app.enableCors();

  app.connectMicroservice<MicroserviceOptions>({
    transport: Transport.TCP,
    options: { host: '0.0.0.0', port: parseInt(process.env.TCP_PORT || '4009') },
  });

  await app.startAllMicroservices();
  await app.listen(parseInt(process.env.HTTP_PORT || '3009'));
  console.log(`Payment Service HTTP: ${process.env.HTTP_PORT || 3009}`);
}
bootstrap();
