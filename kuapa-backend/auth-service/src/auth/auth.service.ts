import {
  ConflictException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcrypt';
import { User, UserDocument } from './entities/user.entity';
import { RegisterDto } from './dto/register.dto';
import { LoginDto, RefreshTokenDto } from './dto/login.dto';

@Injectable()
export class AuthService {
  constructor(
    @InjectModel(User.name) private userModel: Model<UserDocument>,
    private jwt: JwtService,
    private cfg: ConfigService,
  ) {}

  async register(dto: RegisterDto) {
    if (!dto.email && !dto.phone) {
      throw new ConflictException('Email or phone required');
    }

    const orConditions = [];
    if (dto.email) orConditions.push({ email: dto.email });
    if (dto.phone) orConditions.push({ phone: dto.phone });

    const existing = await this.userModel.findOne({ $or: orConditions });
    if (existing) throw new ConflictException('User already exists');

    const passwordHash = await bcrypt.hash(dto.password, 12);
    const saved = await new this.userModel({ ...dto, passwordHash }).save();

    return this.buildTokens(saved);
  }

  async login(dto: LoginDto) {
    const query = dto.email ? { email: dto.email } : { phone: dto.phone };
    const user = await this.userModel.findOne(query);

    if (!user || !(await bcrypt.compare(dto.password, user.passwordHash))) {
      throw new UnauthorizedException('Invalid credentials');
    }
    if (!user.isActive) throw new UnauthorizedException('Account is disabled');

    return this.buildTokens(user);
  }

  async refresh(dto: RefreshTokenDto) {
    try {
      const payload = this.jwt.verify(dto.refreshToken, {
        secret: this.cfg.get('JWT_REFRESH_SECRET'),
      });
      const user = await this.userModel.findById(payload.sub);
      if (!user || user.refreshToken !== dto.refreshToken) {
        throw new UnauthorizedException('Invalid refresh token');
      }
      return this.buildTokens(user);
    } catch {
      throw new UnauthorizedException('Invalid or expired refresh token');
    }
  }

  async logout(userId: string) {
    await this.userModel.findByIdAndUpdate(userId, { refreshToken: null });
    return { message: 'Logged out successfully' };
  }

  async validateToken(token: string) {
    try {
      const payload = this.jwt.verify(token);
      const user = await this.userModel.findById(payload.sub);
      if (!user || !user.isActive) return null;
      return { id: user.id, email: user.email, phone: user.phone, role: user.role };
    } catch {
      return null;
    }
  }

  async getUserById(id: string) {
    const user = await this.userModel.findById(id);
    if (!user) return null;
    return { id: user.id, email: user.email, phone: user.phone, role: user.role, isVerified: user.isVerified };
  }

  private async buildTokens(user: UserDocument) {
    const payload = { sub: user.id, email: user.email, phone: user.phone, role: user.role };

    const accessToken = this.jwt.sign(payload);
    const refreshToken = this.jwt.sign(payload, {
      secret: this.cfg.get('JWT_REFRESH_SECRET'),
      expiresIn: this.cfg.get('JWT_REFRESH_EXPIRY', '30d'),
    });

    await this.userModel.findByIdAndUpdate(user.id, { refreshToken });

    return {
      accessToken,
      refreshToken,
      user: { id: user.id, username: user.username, email: user.email, phone: user.phone, role: user.role },
    };
  }
}
