import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Conversation } from './entities/conversation.entity';
import { Message } from './entities/message.entity';

@Injectable()
export class ChatService {
  constructor(
    @InjectRepository(Conversation) private convRepo: Repository<Conversation>,
    @InjectRepository(Message) private msgRepo: Repository<Message>,
  ) {}

  async getOrCreateConversation(p1Id: string, p1Name: string, p2Id: string, p2Name: string) {
    let conv = await this.convRepo.findOne({
      where: [
        { participant1Id: p1Id, participant2Id: p2Id },
        { participant1Id: p2Id, participant2Id: p1Id },
      ],
    });

    if (!conv) {
      conv = this.convRepo.create({
        participant1Id: p1Id,
        participant1Name: p1Name,
        participant2Id: p2Id,
        participant2Name: p2Name,
      });
      conv = await this.convRepo.save(conv);
    }
    return conv;
  }

  async getUserConversations(userId: string) {
    return this.convRepo
      .createQueryBuilder('c')
      .where('c.participant1Id = :uid OR c.participant2Id = :uid', { uid: userId })
      .orderBy('c.lastMessageAt', 'DESC', 'NULLS LAST')
      .getMany();
  }

  async getMessages(conversationId: string, page = 1, limit = 50) {
    const skip = (page - 1) * limit;
    const [data, total] = await this.msgRepo.findAndCount({
      where: { conversation: { id: conversationId } },
      order: { createdAt: 'DESC' },
      skip,
      take: limit,
    });
    return { data: data.reverse(), total, page };
  }

  async sendMessage(conversationId: string, senderId: string, senderName: string, content: string, type = 'TEXT') {
    const conv = await this.convRepo.findOne({ where: { id: conversationId } });
    if (!conv) throw new NotFoundException('Conversation not found');

    const message = this.msgRepo.create({ conversation: conv, senderId, senderName, content, type });
    const saved = await this.msgRepo.save(message);

    await this.convRepo.update(conversationId, {
      lastMessage: content.substring(0, 100),
      lastMessageAt: new Date(),
    });

    return saved;
  }

  async markMessagesRead(conversationId: string, userId: string) {
    await this.msgRepo
      .createQueryBuilder()
      .update()
      .set({ isRead: true })
      .where('conversationId = :cid AND senderId != :uid AND isRead = false', {
        cid: conversationId,
        uid: userId,
      })
      .execute();
    return { success: true };
  }
}
