import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ValidationPipe } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.useGlobalPipes(new ValidationPipe({ transform: true, whitelist: true }));
  app.enableCors({ origin: '*' });
  app.setGlobalPrefix('api/v1');

  const config = new DocumentBuilder()
    .setTitle('Kuapa API')
    .setDescription('Farmer-to-Buyer Digital Marketplace — Ghana')
    .setVersion('1.0')
    .addBearerAuth()
    .build();
  SwaggerModule.setup('docs', app, SwaggerModule.createDocument(app, config));

  await app.listen(parseInt(process.env.PORT || '3000'));
  console.log(`Kuapa API Gateway running on port ${process.env.PORT || 3000}`);
  console.log(`Swagger docs: http://localhost:${process.env.PORT || 3000}/docs`);
}
bootstrap();
