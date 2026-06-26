import { Body, Controller, Get, Param, Post, Query } from '@nestjs/common';
import { MessagePattern, Payload } from '@nestjs/microservices';
import { ApiTags } from '@nestjs/swagger';
import { ChatService } from './chat.service';

@ApiTags('Chat')
@Controller('chat')
export class ChatController {
  constructor(private readonly chatService: ChatService) {}

  @Post('conversations')
  getOrCreate(@Body() body: { p1Id: string; p1Name: string; p2Id: string; p2Name: string }) {
    return this.chatService.getOrCreateConversation(body.p1Id, body.p1Name, body.p2Id, body.p2Name);
  }

  @Get('conversations/:userId')
  getUserConversations(@Param('userId') userId: string) {
    return this.chatService.getUserConversations(userId);
  }

  @Get('conversations/:id/messages')
  getMessages(@Param('id') id: string, @Query('page') page = 1, @Query('limit') limit = 50) {
    return this.chatService.getMessages(id, +page, +limit);
  }

  @Post('conversations/:id/messages')
  sendMessage(@Param('id') id: string, @Body() body: { senderId: string; senderName: string; content: string }) {
    return this.chatService.sendMessage(id, body.senderId, body.senderName, body.content);
  }

  @Post('conversations/:id/read')
  markRead(@Param('id') id: string, @Body() body: { userId: string }) {
    return this.chatService.markMessagesRead(id, body.userId);
  }

  // ─── TCP ─────────────────────────────────────────────────────────────────

  @MessagePattern('CHAT_GET_OR_CREATE_CONVERSATION')
  tcpGetOrCreate(@Payload() data: any) {
    return this.chatService.getOrCreateConversation(data.p1Id, data.p1Name, data.p2Id, data.p2Name);
  }

  @MessagePattern('CHAT_GET_USER_CONVERSATIONS')
  tcpGetConvs(@Payload() data: { userId: string }) {
    return this.chatService.getUserConversations(data.userId);
  }

  @MessagePattern('CHAT_GET_MESSAGES')
  tcpGetMessages(@Payload() data: { conversationId: string; page?: number }) {
    return this.chatService.getMessages(data.conversationId, data.page);
  }

  @MessagePattern('CHAT_SEND_MESSAGE')
  tcpSend(@Payload() data: { conversationId: string; senderId: string; senderName: string; content: string }) {
    return this.chatService.sendMessage(data.conversationId, data.senderId, data.senderName, data.content);
  }
}
