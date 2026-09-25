import 'package:flutter/material.dart';

import '../api/gemini_client.dart';
import '../theme/app_theme.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessageData message;

  const ChatMessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.auto_awesome,
                size: 14,
                color: AppColors.primarySoft,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 380),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppRadius.lg),
                  topRight: const Radius.circular(AppRadius.lg),
                  bottomLeft: Radius.circular(
                    isUser ? AppRadius.lg : AppRadius.sm,
                  ),
                  bottomRight: Radius.circular(
                    isUser ? AppRadius.sm : AppRadius.lg,
                  ),
                ),
                border: isUser
                    ? null
                    : Border.all(color: AppColors.border),
              ),
              child: _RichText(
                text: message.text,
                isUser: isUser,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RichText extends StatelessWidget {
  final String text;
  final bool isUser;

  const _RichText({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];
    final parts = text.split(RegExp(r'(\*\*[^*]+\*\*)'));
    for (final part in parts) {
      if (part.startsWith('**') && part.endsWith('**')) {
        spans.add(TextSpan(
          text: part.substring(2, part.length - 2),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.primarySoft,
          ),
        ));
      } else {
        spans.add(TextSpan(text: part));
      }
    }
    return Text.rich(
      TextSpan(
        style: TextStyle(
          fontSize: 14,
          height: 20 / 14,
          color: isUser ? AppColors.text : AppColors.text,
        ),
        children: spans,
      ),
    );
  }
}