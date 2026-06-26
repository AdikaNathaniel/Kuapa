import { Body, Controller, Inject, Post, Request, UseGuards } from '@nestjs/common';
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
  register(@Body() body: any) {
    return firstValueFrom(this.authClient.send('AUTH_REGISTER', body));
  }

  @Post('login')
  @ApiOperation({ summary: 'Login with email/phone + password' })
  login(@Body() body: any) {
    return firstValueFrom(this.authClient.send('AUTH_LOGIN', body));
  }

  @Post('refresh')
  refresh(@Body() body: any) {
    return firstValueFrom(this.authClient.send('AUTH_REFRESH', body));
  }

  @Post('logout')
  @UseGuards(AuthGuard)
  @ApiBearerAuth()
  logout(@Request() req) {
    return firstValueFrom(this.authClient.send('AUTH_LOGOUT', { userId: req.user.id }));
  }
}
