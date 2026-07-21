import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/mock_data.dart';
import '../../models/models.dart';
import '../../controllers/providers.dart';
import '../../core/responsive.dart';
import '../../theme.dart';

class HelpScreen extends ConsumerStatefulWidget {
  const HelpScreen({super.key});

  @override
  ConsumerState<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends ConsumerState<HelpScreen> {
  int? expandedIndex;

  @override
  Widget build(BuildContext context) {
    final app = ref.read(appControllerProvider);

    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
            color: Colors.white,
            child: Row(
              children: [
                GestureDetector(
                  onTap: app.back,
                  child: const Icon(Icons.arrow_back, size: 22, color: AppColors.ink),
                ),
                const SizedBox(width: 16),
                Text('Help & Support', style: AppText.display(size: 19)),
              ],
            ),
          ),
        ),
        Expanded(
          child: Container(
            width: double.infinity,
            color: const Color(0xFFF2EFEC),
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
                    ),
                    child: Column(
                      children: helpTopics.asMap().entries.map((e) {
                        final isLast = e.key == helpTopics.length - 1;
                        return _TopicRow(
                          topic: e.value,
                          expanded: expandedIndex == e.key,
                          isLast: isLast,
                          onTap: () {
                            if (e.value.expandable) {
                              setState(() => expandedIndex = expandedIndex == e.key ? null : e.key);
                            } else {
                              app.openChat(topic: e.value.label);
                            }
                          },
                          onChatTap: () => app.openChat(topic: e.value.label),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: 20,
                  child: FloatingActionButton(
                    onPressed: () async {
                      await app.openChat();
                    },
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    heroTag: 'support-fab',
                    child: const Icon(Icons.support_agent, size: 22),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TopicRow extends StatelessWidget {
  final HelpTopic topic;
  final bool expanded;
  final bool isLast;
  final VoidCallback onTap;
  final VoidCallback onChatTap;

  const _TopicRow({
    required this.topic,
    required this.expanded,
    required this.isLast,
    required this.onTap,
    required this.onChatTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            decoration: BoxDecoration(
              border: isLast && !expanded ? null : const Border(bottom: BorderSide(color: AppColors.hairline)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(topic.label, style: AppText.body(size: 14.5, weight: FontWeight.w600, height: 1.3)),
                ),
                const SizedBox(width: 10),
                AnimatedRotation(
                  turns: topic.expandable && expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    topic.expandable ? Icons.keyboard_arrow_down : Icons.chevron_right,
                    color: const Color(0xFF9A9296),
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (topic.expandable && expanded)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            decoration: BoxDecoration(
              border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.hairline)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (topic.answer != null)
                  Text(topic.answer!, style: AppText.body(size: 13, weight: FontWeight.w500, color: AppColors.bodyGrey, height: 1.4)),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: onChatTap,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.chat_bubble_outline, size: 15, color: AppColors.accent),
                      const SizedBox(width: 6),
                      Text('Chat with us', style: AppText.body(size: 13, weight: FontWeight.w700, color: AppColors.accent)),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
