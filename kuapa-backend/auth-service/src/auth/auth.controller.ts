import { Body, Controller, Post, UseGuards, Request } from '@nestjs/common';
import { MessagePattern, Payload } from '@nestjs/microservices';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { AuthService } from './auth.service';
import { RegisterDto } from './dto/register.dto';
import { ForgotPasswordDto, LoginDto, RefreshTokenDto, ResetPasswordDto } from './dto/login.dto';
import { JwtAuthGuard } from './guards/jwt-auth.guard';

@ApiTags('Auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  // ─── HTTP Endpoints ──────────────────────────────────────────────────────────

  @Post('register')
  @ApiOperation({ summary: 'Register a new user' })
  register(@Body() dto: RegisterDto) {
    return this.authService.register(dto);
  }

  @Post('login')
  @ApiOperation({ summary: 'Login with email/phone and password' })
  login(@Body() dto: LoginDto) {
    return this.authService.login(dto);
  }

  @Post('refresh')
  @ApiOperation({ summary: 'Refresh access token' })
  refresh(@Body() dto: RefreshTokenDto) {
    return this.authService.refresh(dto);
  }

  @Post('logout')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Logout current user' })
  logout(@Request() req) {
    return this.authService.logout(req.user.sub);
  }

  // ─── TCP Message Patterns (for inter-service calls) ──────────────────────────

  @MessagePattern('AUTH_REGISTER')
  tcpRegister(@Payload() dto: RegisterDto) {
    return this.authService.register(dto);
  }

  @MessagePattern('AUTH_LOGIN')
  tcpLogin(@Payload() dto: LoginDto) {
    return this.authService.login(dto);
  }

  @MessagePattern('AUTH_REFRESH')
  tcpRefresh(@Payload() dto: RefreshTokenDto) {
    return this.authService.refresh(dto);
  }

  @MessagePattern('AUTH_LOGOUT')
  tcpLogout(@Payload() data: { userId: string }) {
    return this.authService.logout(data.userId);
  }

  @MessagePattern('AUTH_VALIDATE_TOKEN')
  tcpValidateToken(@Payload() data: { token: string }) {
    return this.authService.validateToken(data.token);
  }

  @MessagePattern('AUTH_GET_USER_BY_ID')
  tcpGetUserById(@Payload() data: { id: string }) {
    return this.authService.getUserById(data.id);
  }
}
