import {
  Body, Controller, Delete, Get, Inject, Param, Patch, Post, Query, Request, UseGuards,
} from '@nestjs/common';
import { ClientProxy } from '@nestjs/microservices';
import { ApiBearerAuth, ApiOperation, ApiQuery, ApiTags } from '@nestjs/swagger';
import { firstValueFrom } from 'rxjs';
import { AuthGuard } from '../common/guards/auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';

@ApiTags('Products')
@Controller('products')
export class ProductsGatewayController {
  constructor(@Inject('PRODUCT_SERVICE') private productClient: ClientProxy) {}

  @Get()
  @ApiOperation({ summary: 'Browse marketplace — no auth required' })
  @ApiQuery({ name: 'search', required: false })
  @ApiQuery({ name: 'region', required: false })
  @ApiQuery({ name: 'category', required: false })
  @ApiQuery({ name: 'minPrice', required: false })
  @ApiQuery({ name: 'maxPrice', required: false })
  @ApiQuery({ name: 'page', required: false })
  @ApiQuery({ name: 'limit', required: false })
  findAll(@Query() query: any) {
    return firstValueFrom(this.productClient.send('PRODUCT_FIND_ALL', query));
  }

  @Get('categories')
  @ApiOperation({ summary: 'List all produce categories' })
  getCategories() {
    return firstValueFrom(this.productClient.send('PRODUCT_GET_CATEGORIES', {}));
  }

  @Get('my-listings')
  @UseGuards(AuthGuard, RolesGuard)
  @Roles('FARMER')
  @ApiBearerAuth()
  @ApiOperation({ summary: "Farmer: get own listings" })
  getMyListings(@Request() req) {
    return firstValueFrom(this.productClient.send('PRODUCT_FIND_BY_FARMER', { farmerId: req.user.id }));
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return firstValueFrom(this.productClient.send('PRODUCT_FIND_ONE', { id }));
  }

  @Post()
  @UseGuards(AuthGuard, RolesGuard)
  @Roles('FARMER')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Farmer: create a produce listing' })
  create(@Request() req, @Body() body: any) {
    return firstValueFrom(this.productClient.send('PRODUCT_CREATE', { ...body, farmerId: req.user.id }));
  }

  @Patch(':id')
  @UseGuards(AuthGuard, RolesGuard)
  @Roles('FARMER')
  @ApiBearerAuth()
  update(@Request() req, @Param('id') id: string, @Body() body: any) {
    return firstValueFrom(this.productClient.send('PRODUCT_UPDATE', { id, farmerId: req.user.id, updates: body }));
  }

  @Delete(':id')
  @UseGuards(AuthGuard, RolesGuard)
  @Roles('FARMER')
  @ApiBearerAuth()
  remove(@Request() req, @Param('id') id: string) {
    return firstValueFrom(this.productClient.send('PRODUCT_DELETE', { id, farmerId: req.user.id }));
  }
}
