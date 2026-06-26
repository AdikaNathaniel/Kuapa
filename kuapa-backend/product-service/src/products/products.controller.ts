import { Body, Controller, Delete, Get, Param, Patch, Post, Query } from '@nestjs/common';
import { MessagePattern, Payload } from '@nestjs/microservices';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { ProductsService } from './products.service';
import { CreateProductDto, ProductFilterDto } from './dto/create-product.dto';

@ApiTags('Products')
@Controller('products')
export class ProductsController {
  constructor(private readonly productsService: ProductsService) {}

  // ─── HTTP ────────────────────────────────────────────────────────────────

  @Post()
  @ApiOperation({ summary: 'Create a produce listing' })
  create(@Body() dto: CreateProductDto) {
    return this.productsService.create(dto);
  }

  @Get()
  @ApiOperation({ summary: 'Search and filter produce listings' })
  findAll(@Query() filters: ProductFilterDto) {
    return this.productsService.findAll(filters);
  }

  @Get('categories')
  @ApiOperation({ summary: 'Get all produce categories' })
  getCategories() {
    return this.productsService.getCategories();
  }

  @Get('farmer/:farmerId')
  @ApiOperation({ summary: "Get farmer's own listings" })
  findByFarmer(@Param('farmerId') farmerId: string) {
    return this.productsService.findByFarmer(farmerId);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.productsService.findOne(id);
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() data: any) {
    return this.productsService.update(id, data.farmerId, data);
  }

  @Delete(':id')
  remove(@Param('id') id: string, @Query('farmerId') farmerId: string) {
    return this.productsService.remove(id, farmerId);
  }

  // ─── TCP ─────────────────────────────────────────────────────────────────

  @MessagePattern('PRODUCT_CREATE')
  tcpCreate(@Payload() dto: CreateProductDto) {
    return this.productsService.create(dto);
  }

  @MessagePattern('PRODUCT_FIND_ALL')
  tcpFindAll(@Payload() filters: ProductFilterDto) {
    return this.productsService.findAll(filters);
  }

  @MessagePattern('PRODUCT_FIND_ONE')
  tcpFindOne(@Payload() data: { id: string }) {
    return this.productsService.findOne(data.id);
  }

  @MessagePattern('PRODUCT_FIND_BY_FARMER')
  tcpFindByFarmer(@Payload() data: { farmerId: string }) {
    return this.productsService.findByFarmer(data.farmerId);
  }

  @MessagePattern('PRODUCT_UPDATE')
  tcpUpdate(@Payload() data: { id: string; farmerId: string; updates: any }) {
    return this.productsService.update(data.id, data.farmerId, data.updates);
  }

  @MessagePattern('PRODUCT_DELETE')
  tcpDelete(@Payload() data: { id: string; farmerId: string }) {
    return this.productsService.remove(data.id, data.farmerId);
  }

  @MessagePattern('PRODUCT_GET_CATEGORIES')
  tcpGetCategories() {
    return this.productsService.getCategories();
  }

  @MessagePattern('PRODUCT_UPDATE_STATS')
  tcpUpdateStats(@Payload() data: { id: string; sold: number }) {
    return this.productsService.updateProductStats(data.id, data.sold);
  }
}
