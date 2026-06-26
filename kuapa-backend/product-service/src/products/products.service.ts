import { Injectable, NotFoundException, OnModuleInit } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Product } from './entities/product.entity';
import { Category } from './entities/category.entity';
import { CreateProductDto, ProductFilterDto } from './dto/create-product.dto';

const DEFAULT_CATEGORIES = [
  { name: 'Tomatoes', description: 'Fresh tomatoes' },
  { name: 'Peppers', description: 'Hot and sweet peppers' },
  { name: 'Garden Eggs', description: 'Eggplant varieties' },
  { name: 'Okra', description: 'Fresh okra' },
  { name: 'Leafy Greens', description: 'Spinach, lettuce, kontomire and other greens' },
  { name: 'Onions', description: 'All onion varieties' },
  { name: 'Yams', description: 'Fresh yams' },
  { name: 'Cassava', description: 'Fresh cassava' },
  { name: 'Plantain', description: 'Ripe and unripe plantain' },
  { name: 'Other Vegetables', description: 'Other vegetable produce' },
];

@Injectable()
export class ProductsService implements OnModuleInit {
  constructor(
    @InjectRepository(Product) private productRepo: Repository<Product>,
    @InjectRepository(Category) private categoryRepo: Repository<Category>,
  ) {}

  async onModuleInit() {
    for (const cat of DEFAULT_CATEGORIES) {
      const exists = await this.categoryRepo.findOne({ where: { name: cat.name } });
      if (!exists) await this.categoryRepo.save(this.categoryRepo.create(cat));
    }
  }

  async create(dto: CreateProductDto) {
    const product = this.productRepo.create(dto);
    return this.productRepo.save(product);
  }

  async findAll(filters: ProductFilterDto) {
    const page = filters.page || 1;
    const limit = filters.limit || 20;
    const skip = (page - 1) * limit;

    const query = this.productRepo
      .createQueryBuilder('p')
      .leftJoinAndSelect('p.category', 'category')
      .where('p.isAvailable = true');

    if (filters.search) {
      query.andWhere('(p.name ILIKE :search OR p.description ILIKE :search)', {
        search: `%${filters.search}%`,
      });
    }
    if (filters.region) {
      query.andWhere('p.region ILIKE :region', { region: `%${filters.region}%` });
    }
    if (filters.farmerId) {
      query.andWhere('p.farmerId = :farmerId', { farmerId: filters.farmerId });
    }
    if (filters.category) {
      query.andWhere('category.name ILIKE :cat', { cat: `%${filters.category}%` });
    }
    if (filters.minPrice) {
      query.andWhere('p.pricePerUnit >= :min', { min: filters.minPrice });
    }
    if (filters.maxPrice) {
      query.andWhere('p.pricePerUnit <= :max', { max: filters.maxPrice });
    }

    const [data, total] = await query
      .orderBy('p.createdAt', 'DESC')
      .skip(skip)
      .take(limit)
      .getManyAndCount();

    return { data, total, page, limit, pages: Math.ceil(total / limit) };
  }

  async findOne(id: string) {
    const product = await this.productRepo.findOne({
      where: { id },
      relations: ['category'],
    });
    if (!product) throw new NotFoundException('Product not found');
    return product;
  }

  async findByFarmer(farmerId: string) {
    return this.productRepo.find({
      where: { farmerId },
      relations: ['category'],
      order: { createdAt: 'DESC' },
    });
  }

  async update(id: string, farmerId: string, data: Partial<Product>) {
    const product = await this.productRepo.findOne({ where: { id, farmerId } });
    if (!product) throw new NotFoundException('Product not found');
    await this.productRepo.update(id, data);
    return this.findOne(id);
  }

  async remove(id: string, farmerId: string) {
    const product = await this.productRepo.findOne({ where: { id, farmerId } });
    if (!product) throw new NotFoundException('Product not found');
    await this.productRepo.remove(product);
    return { success: true };
  }

  async getCategories() {
    return this.categoryRepo.find({ order: { name: 'ASC' } });
  }

  async updateProductStats(id: string, sold: number) {
    await this.productRepo.increment({ id }, 'totalOrders', 1);
    const product = await this.productRepo.findOne({ where: { id } });
    if (product) {
      const newQty = product.quantity - sold;
      await this.productRepo.update(id, {
        quantity: newQty < 0 ? 0 : newQty,
        isAvailable: newQty > 0,
      });
    }
  }
}
