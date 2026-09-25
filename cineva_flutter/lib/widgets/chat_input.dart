import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ChatInput extends StatefulWidget {
  final void Function(String text) onSend;
  final bool loading;

  const ChatInput({super.key, required this.onSend, required this.loading});

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSend() {
    final trimmed = _controller.text.trim();
    if (trimmed.isEmpty || widget.loading) return;
    widget.onSend(trimmed);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _controller.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: AppColors.text, fontSize: 15),
              maxLines: 4,
              minLines: 1,
              maxLength: 1000,
              buildCounter: (context, {required currentLength, maxLength, required isFocused}) =>
                  null,
              enabled: !widget.loading,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _handleSend(),
              textInputAction: TextInputAction.send,
              decoration: InputDecoration(
                hintText: 'Ask about movies...',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.surfaceLight,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (widget.loading)
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(17),
              ),
              alignment: Alignment.center,
              child: const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primarySoft,
                ),
              ),
            )
          else
            GestureDetector(
              onTap: hasText ? _handleSend : null,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: hasText ? AppColors.primary : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(17),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.arrow_upward,
                  size: 18,
                  color: hasText ? AppColors.text : AppColors.textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}