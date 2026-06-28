import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/chat_socket_service.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String otherName;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherName,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _msgCtrl      = TextEditingController();
  final _scrollCtrl   = ScrollController();
  final List<Map<String, dynamic>> _messages = [];

  StreamSubscription? _msgSub;
  StreamSubscription? _typingSub;
  Timer? _typingTimer;

  bool _loading    = true;
  bool _sending    = false;
  bool _otherTyping = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _setupSocket();
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    _typingSub?.cancel();
    _typingTimer?.cancel();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final res = await ApiClient.instance.get(
        '${ApiConstants.conversations}/${widget.conversationId}/messages',
      );
      final data = res.data as Map<String, dynamic>;
      final msgs = (data['data'] as List?) ?? [];
      setState(() {
        _messages.addAll(msgs.cast<Map<String, dynamic>>());
        _loading = false;
      });
      _scrollToBottom();

      // Mark read
      final user = ref.read(authUserProvider).valueOrNull;
      if (user != null) {
        ApiClient.instance.post(
          '${ApiConstants.conversations}/${widget.conversationId}/read',
          data: {'userId': user.id},
        ).ignore();
      }
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _setupSocket() {
    final user = ref.read(authUserProvider).valueOrNull;
    if (user == null) return;

    ChatSocketService.instance.connect(user.id);
    ChatSocketService.instance.joinConversation(widget.conversationId);

    _msgSub = ChatSocketService.instance.messageStream.listen((msg) {
      if (msg['conversationId'] == widget.conversationId) {
        setState(() => _messages.add(msg));
        _scrollToBottom();
      }
    });

    _typingSub = ChatSocketService.instance.typingStream.listen((data) {
      if (data['userId'] != user.id) {
        setState(() => _otherTyping = data['isTyping'] == true);
        if (_otherTyping) {
          _typingTimer?.cancel();
          _typingTimer = Timer(const Duration(seconds: 4), () {
            if (mounted) setState(() => _otherTyping = false);
          });
        }
      }
    });
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        if (animate) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
        }
      }
    });
  }

  void _onTypingChanged(String value) {
    final user = ref.read(authUserProvider).valueOrNull;
    if (user == null) return;
    ChatSocketService.instance.sendTyping(
      conversationId: widget.conversationId,
      userId: user.id,
      isTyping: value.isNotEmpty,
    );
  }

  Future<void> _send() async {
    final content = _msgCtrl.text.trim();
    if (content.isEmpty) return;

    final user = ref.read(authUserProvider).valueOrNull;
    if (user == null) return;

    setState(() => _sending = true);
    _msgCtrl.clear();

    // Stop typing indicator
    ChatSocketService.instance.sendTyping(
      conversationId: widget.conversationId,
      userId: user.id,
      isTyping: false,
    );

    try {
      ChatSocketService.instance.sendMessage(
        conversationId: widget.conversationId,
        senderId: user.id,
        senderName: user.displayName,
        content: content,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user  = ref.watch(authUserProvider).valueOrNull;
    final myId  = user?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            if (_otherTyping)
              const Text(
                'typing…',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppTheme.primary),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Message list ────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const LoadingView(message: 'Loading messages…')
                : _error != null
                    ? ErrorView(message: _error!, onRetry: _loadHistory)
                    : _messages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.waving_hand_outlined, size: 48, color: Colors.grey.shade300),
                                const SizedBox(height: 12),
                                Text(
                                  'Say hello to ${widget.otherName}!',
                                  style: const TextStyle(color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollCtrl,
                            padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                            itemCount: _messages.length,
                            itemBuilder: (_, i) {
                              final msg    = _messages[i];
                              final isMe   = msg['senderId'] == myId;
                              final prev   = i > 0 ? _messages[i - 1] : null;
                              final showDate = prev == null ||
                                  !_sameDay(
                                    DateTime.tryParse(prev['createdAt']?.toString() ?? ''),
                                    DateTime.tryParse(msg['createdAt']?.toString() ?? ''),
                                  );

                              return Column(
                                children: [
                                  if (showDate) _DateDivider(msg['createdAt']?.toString()),
                                  _MessageBubble(message: msg, isMe: isMe),
                                ],
                              );
                            },
                          ),
          ),

          // ── Typing indicator dot ─────────────────────────────────────
          if (_otherTyping)
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(left: 16, bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Dot(delay: 0),
                    SizedBox(width: 4),
                    _Dot(delay: 150),
                    SizedBox(width: 4),
                    _Dot(delay: 300),
                  ],
                ),
              ),
            ),

          // ── Input bar ────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(
              12, 10, 12,
              MediaQuery.of(context).viewInsets.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    onChanged: _onTypingChanged,
                    onSubmitted: (_) => _send(),
                    textInputAction: TextInputAction.send,
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: 'Type a message…',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: Material(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      onTap: _sending ? null : _send,
                      borderRadius: BorderRadius.circular(24),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: _sending
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _sameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

// ─── Message bubble ───────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final content   = message['content']?.toString() ?? '';
    final timestamp = DateTime.tryParse(message['createdAt']?.toString() ?? '');
    final timeStr   = timestamp != null ? DateFormat('HH:mm').format(timestamp) : '';
    final isRead    = message['isRead'] == true;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 4,
          bottom: 4,
          left: isMe ? 60 : 0,
          right: isMe ? 0 : 60,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.primary : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft:     const Radius.circular(18),
            topRight:    const Radius.circular(18),
            bottomLeft:  Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              content,
              style: TextStyle(
                color: isMe ? Colors.white : AppTheme.textPrimary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe ? Colors.white70 : AppTheme.textSecondary,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    isRead ? Icons.done_all : Icons.done,
                    size: 12,
                    color: isRead ? Colors.lightBlueAccent : Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Date divider ─────────────────────────────────────────────────────────────

class _DateDivider extends StatelessWidget {
  final String? isoDate;
  const _DateDivider(this.isoDate);

  @override
  Widget build(BuildContext context) {
    final dt = isoDate != null ? DateTime.tryParse(isoDate!) : null;
    final label = dt != null ? DateFormat('MMMM d, y').format(dt) : '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}

// ─── Animated typing dot ─────────────────────────────────────────────────────

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _anim,
        child: Container(
          width: 7, height: 7,
          decoration: const BoxDecoration(
            color: AppTheme.textSecondary,
            shape: BoxShape.circle,
          ),
        ),
      );
}
