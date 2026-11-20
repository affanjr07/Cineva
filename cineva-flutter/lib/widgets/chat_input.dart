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
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _controller.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm + 2,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Semantics(
              textField: true,
              label: 'Message Cineva AI',
              child: TextField(
                controller: _controller,
                style: AppType.body.copyWith(color: AppColors.text),
                maxLines: 4,
                minLines: 1,
                maxLength: 1000,
                buildCounter: (
                  context, {
                  required currentLength,
                  maxLength,
                  required isFocused,
                }) => null,
                enabled: !widget.loading,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _handleSend(),
                textInputAction: TextInputAction.send,
                decoration: InputDecoration(
                  hintText: 'Ask about movies...',
                  hintStyle: AppType.body.copyWith(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
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
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.3,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Semantics(
            button: true,
            label: widget.loading ? 'Sending message' : 'Send message',
            child: Tooltip(
              message: widget.loading ? 'Sending...' : 'Send',
              child: Material(
                color: hasText && !widget.loading
                    ? AppColors.primary
                    : AppColors.surfaceLight,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: hasText && !widget.loading ? _handleSend : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: hasText && !widget.loading
                            ? AppColors.primarySoft.withValues(alpha: 0.28)
                            : AppColors.border,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: widget.loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primarySoft,
                            ),
                          )
                        : Icon(
                            Icons.arrow_upward_rounded,
                            size: 20,
                            color: hasText
                                ? AppColors.text
                                : AppColors.textMuted,
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
