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
        vertical: AppSpacing.xs + 2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                gradient: AppGradients.ai,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 14,
                color: AppColors.text,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 360),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                gradient: isUser ? AppGradients.accent : null,
                color: isUser ? null : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppRadius.lg),
                  topRight: const Radius.circular(AppRadius.lg),
                  bottomLeft: Radius.circular(isUser ? AppRadius.lg : 6),
                  bottomRight: Radius.circular(isUser ? 6 : AppRadius.lg),
                ),
                border: isUser
                    ? Border.all(
                        color: AppColors.primarySoft.withValues(alpha: 0.2),
                      )
                    : Border.all(color: AppColors.border),
              ),
              child: _RichText(text: message.text, isUser: isUser),
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
        spans.add(
          TextSpan(
            text: part.substring(2, part.length - 2),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: isUser ? AppColors.text : AppColors.primarySoft,
            ),
          ),
        );
      } else {
        spans.add(TextSpan(text: part));
      }
    }
    return Text.rich(
      TextSpan(
        style: AppType.body.copyWith(
          fontSize: 14,
          height: 1.5,
          color: isUser ? AppColors.text : AppColors.text,
        ),
        children: spans,
      ),
    );
  }
}
