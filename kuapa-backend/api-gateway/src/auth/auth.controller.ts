import {
  BadRequestException,
  Body,
  ConflictException,
  Controller,
  Inject,
  InternalServerErrorException,
  Post,
  Request,
  UnauthorizedException,
  UseGuards,
} from '@nestjs/common';
import { ClientProxy } from '@nestjs/microservices';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { firstValueFrom } from 'rxjs';
import { AuthGuard } from '../common/guards/auth.guard';

@ApiTags('Auth')
@Controller('auth')
export class AuthGatewayController {
  constructor(@Inject('AUTH_SERVICE') private authClient: ClientProxy) {}

  @Post('register')
  @ApiOperation({ summary: 'Register — role: FARMER | BUYER | TRANSPORTER' })
  async register(@Body() body: any) {
    try {
      return await firstValueFrom(this.authClient.send('AUTH_REGISTER', body));
    } catch (err: any) {
      this.handleRpcError(err);
    }
  }

  @Post('login')
  @ApiOperation({ summary: 'Login with email/phone + password' })
  async login(@Body() body: any) {
    try {
      return await firstValueFrom(this.authClient.send('AUTH_LOGIN', body));
    } catch (err: any) {
      this.handleRpcError(err);
    }
  }

  @Post('refresh')
  async refresh(@Body() body: any) {
    try {
      return await firstValueFrom(this.authClient.send('AUTH_REFRESH', body));
    } catch (err: any) {
      this.handleRpcError(err);
    }
  }

  @Post('logout')
  @UseGuards(AuthGuard)
  @ApiBearerAuth()
  async logout(@Request() req) {
    try {
      return await firstValueFrom(
        this.authClient.send('AUTH_LOGOUT', { userId: req.user.id }),
      );
    } catch (err: any) {
      this.handleRpcError(err);
    }
  }

  /** Translates TCP/RPC errors into proper HTTP exceptions. */
  private handleRpcError(err: any): never {
    const status: number = err?.statusCode ?? err?.status ?? 0;
    const message: string =
      err?.message ?? 'An error occurred. Please try again.';

    if (status === 400) throw new BadRequestException(message);
    if (status === 401) throw new UnauthorizedException(message);
    if (status === 409) throw new ConflictException(message);
    throw new InternalServerErrorException(
      'Service temporarily unavailable. Please try again.',
    );
  }
}
