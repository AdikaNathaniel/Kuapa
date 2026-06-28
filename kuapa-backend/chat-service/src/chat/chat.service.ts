import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Conversation, ConversationDocument } from './entities/conversation.entity';
import { Message, MessageDocument } from './entities/message.entity';

@Injectable()
export class ChatService {
  constructor(
    @InjectModel(Conversation.name) private convModel: Model<ConversationDocument>,
    @InjectModel(Message.name) private msgModel: Model<MessageDocument>,
  ) {}

  async getOrCreateConversation(p1Id: string, p1Name: string, p2Id: string, p2Name: string) {
    let conv = await this.convModel.findOne({
      $or: [
        { participant1Id: p1Id, participant2Id: p2Id },
        { participant1Id: p2Id, participant2Id: p1Id },
      ],
    });

    if (!conv) {
      conv = await new this.convModel({ participant1Id: p1Id, participant1Name: p1Name, participant2Id: p2Id, participant2Name: p2Name }).save();
    }
    return conv;
  }

  async getUserConversations(userId: string) {
    return this.convModel
      .find({ $or: [{ participant1Id: userId }, { participant2Id: userId }] })
      .sort({ lastMessageAt: -1 });
  }

  async getMessages(conversationId: string, page = 1, limit = 50) {
    const skip = (page - 1) * limit;
    const [data, total] = await Promise.all([
      this.msgModel.find({ conversationId }).sort({ createdAt: -1 }).skip(skip).limit(limit),
      this.msgModel.countDocuments({ conversationId }),
    ]);
    return { data: data.reverse(), total, page };
  }

  async sendMessage(conversationId: string, senderId: string, senderName: string, content: string, type = 'TEXT') {
    const conv = await this.convModel.findById(conversationId);
    if (!conv) throw new NotFoundException('Conversation not found');

    const saved = await new this.msgModel({ conversationId, senderId, senderName, content, type }).save();

    await this.convModel.findByIdAndUpdate(conversationId, {
      lastMessage: content.substring(0, 100),
      lastMessageAt: new Date(),
    });

    return saved;
  }

  async markMessagesRead(conversationId: string, userId: string) {
    await this.msgModel.updateMany(
      { conversationId, senderId: { $ne: userId }, isRead: false },
      { isRead: true },
    );
    return { success: true };
  }
}
