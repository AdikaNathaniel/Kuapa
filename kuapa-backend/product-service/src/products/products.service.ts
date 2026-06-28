import { Injectable, NotFoundException, OnModuleInit } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Product, ProductDocument } from './entities/product.entity';
import { Category, CategoryDocument } from './entities/category.entity';
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
    @InjectModel(Product.name) private productModel: Model<ProductDocument>,
    @InjectModel(Category.name) private categoryModel: Model<CategoryDocument>,
  ) {}

  async onModuleInit() {
    for (const cat of DEFAULT_CATEGORIES) {
      const exists = await this.categoryModel.findOne({ name: cat.name });
      if (!exists) await new this.categoryModel(cat).save();
    }
  }

  async create(dto: CreateProductDto) {
    return new this.productModel(dto).save();
  }

  async findAll(filters: ProductFilterDto) {
    const page = filters.page || 1;
    const limit = filters.limit || 20;
    const skip = (page - 1) * limit;

    const query: any = { isAvailable: true };

    if (filters.search) {
      const re = new RegExp(filters.search, 'i');
      query.$or = [{ name: re }, { description: re }];
    }
    if (filters.region) query.region = new RegExp(filters.region, 'i');
    if (filters.farmerId) query.farmerId = filters.farmerId;
    if (filters.category) query.categoryName = new RegExp(filters.category, 'i');
    if (filters.minPrice) query.pricePerUnit = { ...query.pricePerUnit, $gte: filters.minPrice };
    if (filters.maxPrice) query.pricePerUnit = { ...query.pricePerUnit, $lte: filters.maxPrice };

    const [data, total] = await Promise.all([
      this.productModel.find(query).sort({ createdAt: -1 }).skip(skip).limit(limit),
      this.productModel.countDocuments(query),
    ]);

    return { data, total, page, limit, pages: Math.ceil(total / limit) };
  }

  async findOne(id: string) {
    const product = await this.productModel.findById(id);
    if (!product) throw new NotFoundException('Product not found');
    return product;
  }

  async findByFarmer(farmerId: string) {
    return this.productModel.find({ farmerId }).sort({ createdAt: -1 });
  }

  async update(id: string, farmerId: string, data: Partial<Product>) {
    const product = await this.productModel.findOne({ _id: id, farmerId });
    if (!product) throw new NotFoundException('Product not found');
    return this.productModel.findByIdAndUpdate(id, data, { new: true });
  }

  async remove(id: string, farmerId: string) {
    const product = await this.productModel.findOne({ _id: id, farmerId });
    if (!product) throw new NotFoundException('Product not found');
    await this.productModel.findByIdAndDelete(id);
    return { success: true };
  }

  async getCategories() {
    return this.categoryModel.find().sort({ name: 1 });
  }

  async updateProductStats(id: string, sold: number) {
    const product = await this.productModel.findById(id);
    if (product) {
      const newQty = Math.max(0, product.quantity - sold);
      await this.productModel.findByIdAndUpdate(id, {
        $inc: { totalOrders: 1 },
        quantity: newQty,
        isAvailable: newQty > 0,
      });
    }
  }
}
