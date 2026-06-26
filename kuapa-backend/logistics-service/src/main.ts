import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { MicroserviceOptions, Transport } from '@nestjs/microservices';
import { ValidationPipe } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.useGlobalPipes(new ValidationPipe({ transform: true, whitelist: true }));
  app.enableCors();

  app.connectMicroservice<MicroserviceOptions>({
    transport: Transport.TCP,
    options: { host: '0.0.0.0', port: parseInt(process.env.TCP_PORT || '4005') },
  });

  const config = new DocumentBuilder().setTitle('Kuapa Logistics Service').setVersion('1.0').build();
  SwaggerModule.setup('api', app, SwaggerModule.createDocument(app, config));

  await app.startAllMicroservices();
  await app.listen(parseInt(process.env.HTTP_PORT || '3005'));
  console.log(`Logistics Service HTTP: ${process.env.HTTP_PORT || 3005}`);
}
bootstrap();
