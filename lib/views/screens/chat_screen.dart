import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/mock_data.dart';
import '../../models/models.dart';
import '../../controllers/providers.dart';
import '../../theme.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final app = ref.read(appControllerProvider);
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    await app.sendChatMessage(text);
    _controller.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appControllerProvider);
    _scrollToBottom();

    return SafeArea(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
            decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: AppColors.hairline))),
            child: Row(
              children: [
                GestureDetector(
                  onTap: app.back,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.cardBorder, width: 1.5)),
                    child: const Icon(Icons.arrow_back_ios_new, size: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: const Icon(Icons.support_agent, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(supportAgentName, style: AppText.body(size: 15, weight: FontWeight.w700)),
                      Row(
                        children: [
                          Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle)),
                          const SizedBox(width: 5),
                          Text('Online · typically replies in 2 min', style: AppText.body(size: 11, weight: FontWeight.w500, color: AppColors.bodyGrey)),
                        ],
                      ),
                    ],
                  ),
                ),
                const CircleIconButtonSmall(icon: Icons.call_outlined),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: const Color(0xFFF7F4F0),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
                itemCount: app.chatMessages.length + (app.agentTyping ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i == app.chatMessages.length) {
                    return const _TypingBubble();
                  }
                  final m = app.chatMessages[i];
                  return _MessageBubble(message: m);
                },
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
            decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.hairline))),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFF7F4F0), borderRadius: BorderRadius.circular(24)),
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      style: AppText.body(size: 14.5, weight: FontWeight.w500),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: 'Type a message…',
                        hintStyle: AppText.body(size: 14.5, weight: FontWeight.w500, color: AppColors.lightGreyText),
                      ),
                      onSubmitted: (_) async => _send(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(gradient: AppColors.accentGradient, shape: BoxShape.circle),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final fromCustomer = message.fromCustomer;
    final text = message.text;
    final time = message.time;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: fromCustomer ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
            child: Column(
              crossAxisAlignment: fromCustomer ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: fromCustomer ? AppColors.accentGradient : null,
                    color: fromCustomer ? null : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(fromCustomer ? 16 : 4),
                      bottomRight: Radius.circular(fromCustomer ? 4 : 16),
                    ),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: Text(
                    text,
                    style: AppText.body(size: 14, weight: FontWeight.w500, color: fromCustomer ? Colors.white : AppColors.ink, height: 1.35),
                  ),
                ),
                const SizedBox(height: 3),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(time, style: AppText.body(size: 10.5, weight: FontWeight.w500, color: AppColors.lightGreyText)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) => Padding(
                    padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
                    child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.lightGreyText, shape: BoxShape.circle)),
                  )),
            ),
          ),
        ],
      ),
    );
  }
}

class CircleIconButtonSmall extends StatelessWidget {
  final IconData icon;
  const CircleIconButtonSmall({super.key, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.cardBorder, width: 1.5)),
      child: Icon(icon, size: 17, color: AppColors.accent),
    );
  }
}
