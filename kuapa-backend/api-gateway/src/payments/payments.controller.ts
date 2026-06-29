import { Body, Controller, Get, Inject, Param, Post, Request, UseGuards } from '@nestjs/common';
import { ClientProxy } from '@nestjs/microservices';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { firstValueFrom } from 'rxjs';
import { AuthGuard } from '../common/guards/auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';

@ApiTags('Payments')
@Controller('payments')
@UseGuards(AuthGuard, RolesGuard)
@ApiBearerAuth()
export class PaymentsGatewayController {
  constructor(@Inject('PAYMENT_SERVICE') private paymentClient: ClientProxy) {}

  @Post('initiate')
  @Roles('BUYER')
  @ApiOperation({ summary: 'Initiate Paystack payment for an order' })
  initiate(@Request() req, @Body() body: any) {
    return firstValueFrom(
      this.paymentClient.send('PAYMENT_INITIATE', {
        ...body,
        payerId: req.user.id,
        payerEmail: req.user.email,
      }),
    );
  }

  @Get('verify/:reference')
  @ApiOperation({ summary: 'Verify Paystack payment by reference' })
  verify(@Param('reference') reference: string) {
    return firstValueFrom(this.paymentClient.send('PAYMENT_VERIFY', { reference }));
  }

  @Get(':id/status')
  getStatus(@Param('id') id: string) {
    return firstValueFrom(this.paymentClient.send('PAYMENT_STATUS', { id }));
  }

  @Get('history')
  getHistory(@Request() req) {
    return firstValueFrom(this.paymentClient.send('PAYMENT_USER_HISTORY', { payerId: req.user.id }));
  }

  @Post('webhook')
  webhook(@Body() body: any) {
    return firstValueFrom(this.paymentClient.send('PAYMENT_WEBHOOK', body));
  }
}
