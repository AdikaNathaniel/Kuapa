import { Body, Controller, Get, Inject, Param, Post, Query, Request, UseGuards } from '@nestjs/common';
import { ClientProxy } from '@nestjs/microservices';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { firstValueFrom } from 'rxjs';
import { AuthGuard } from '../common/guards/auth.guard';

@ApiTags('Chat')
@Controller('chat')
@UseGuards(AuthGuard)
@ApiBearerAuth()
export class ChatGatewayController {
  constructor(@Inject('CHAT_SERVICE') private chatClient: ClientProxy) {}

  @Post('conversations')
  @ApiOperation({ summary: 'Start or resume a conversation with another user' })
  getOrCreate(@Request() req, @Body() body: { p2Id: string; p2Name: string }) {
    return firstValueFrom(this.chatClient.send('CHAT_GET_OR_CREATE_CONVERSATION', {
      p1Id: req.user.id,
      p1Name: req.user.email || req.user.phone,
      p2Id: body.p2Id,
      p2Name: body.p2Name,
    }));
  }

  @Get('conversations')
  getMyConversations(@Request() req) {
    return firstValueFrom(this.chatClient.send('CHAT_GET_USER_CONVERSATIONS', { userId: req.user.id }));
  }

  @Get('conversations/:id/messages')
  getMessages(@Param('id') id: string, @Query('page') page = 1) {
    return firstValueFrom(this.chatClient.send('CHAT_GET_MESSAGES', { conversationId: id, page: +page }));
  }

  @Post('conversations/:id/messages')
  sendMessage(@Request() req, @Param('id') id: string, @Body() body: { content: string; senderName: string }) {
    return firstValueFrom(this.chatClient.send('CHAT_SEND_MESSAGE', {
      conversationId: id,
      senderId: req.user.id,
      senderName: body.senderName,
      content: body.content,
    }));
  }
}
