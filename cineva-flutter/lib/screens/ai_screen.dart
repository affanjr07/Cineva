import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../api/gemini_client.dart';
import '../stores/chat_store.dart';
import '../theme/app_theme.dart';
import '../widgets/chat_input.dart';
import '../widgets/chat_message_bubble.dart';

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  bool _loading = false;
  bool _showHistory = false;
  final _scrollController = ScrollController();

  static const _suggestions = [
    (Icons.movie_filter_rounded, 'Recommend me a movie'),
    (Icons.travel_explore_rounded, 'I forgot the title...'),
    (Icons.nightlight_round, 'Good movies for tonight'),
    (Icons.favorite_rounded, 'Romantic movies'),
    (Icons.local_fire_department_rounded, 'Scary horror movies'),
    (Icons.public_rounded, 'Best Korean dramas'),
  ];

  @override
  void initState() {
    super.initState();
    ChatStore.instance.load();
    ChatStore.instance.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    ChatStore.instance.removeListener(_onStoreChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onStoreChanged() {
    if (!mounted) return;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _ensureConversation() {
    final id = ChatStore.instance.currentConversationId;
    if (id != null) return id;
    return ChatStore.instance.createConversation();
  }

  Future<void> _handleSend(String text) async {
    final convId = _ensureConversation();
    await ChatStore.instance.addMessage(
      convId,
      ChatMessageData(role: 'user', text: text),
    );
    setState(() => _loading = true);

    if (!GeminiClient.isMovieRelatedQuery(text)) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (mounted) setState(() => _loading = false);
      await ChatStore.instance.addMessage(
        convId,
        ChatMessageData(role: 'model', text: GeminiClient.offTopicReply),
      );
      return;
    }

    final conv = ChatStore.instance.conversations
        .where((c) => c.id == convId)
        .firstOrNull;
    final history = (conv?.messages ?? []).map((m) => m).toList(growable: true);

    try {
      final reply = await GeminiClient.sendChatMessage(history);
      await ChatStore.instance.addMessage(
        convId,
        ChatMessageData(role: 'model', text: reply),
      );
    } catch (_) {
      await ChatStore.instance.addMessage(
        convId,
        ChatMessageData(
          role: 'model',
          text: 'Sorry, something went wrong. Please try again.',
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _handleNewChat() {
    ChatStore.instance.setCurrentConversation(null);
    setState(() => _showHistory = false);
  }

  void _handleSelectHistory(String id) {
    ChatStore.instance.setCurrentConversation(id);
    setState(() => _showHistory = false);
  }

  void _handleDeleteHistory(String id) {
    ChatStore.instance.deleteConversation(id);
  }

  @override
  Widget build(BuildContext context) {
    final conv = ChatStore.instance.currentConversation;
    final messages = conv?.messages ?? <ChatMessageData>[];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                _header(),
                Expanded(
                  child: messages.isEmpty ? _welcome() : _messages(messages),
                ),
                _ChatInputWrapper(loading: _loading, onSend: _handleSend),
              ],
            ),
            if (_showHistory) _historyOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _historyOverlay() {
    final conversations = ChatStore.instance.conversations;
    final width = math.min(MediaQuery.sizeOf(context).width * 0.84, 330.0);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: MediaQuery.of(context).disableAnimations
          ? Duration.zero
          : const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _showHistory = false),
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.64 * value),
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Transform.translate(
                offset: Offset(width * (1 - value), 0),
                child: Container(
                  width: width,
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(AppRadius.xxl),
                    ),
                    border: Border(left: BorderSide(color: AppColors.border)),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xl,
                          AppSpacing.xl,
                          AppSpacing.md,
                          AppSpacing.md,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'HISTORY',
                                    style: AppType.caption.copyWith(
                                      color: AppColors.primarySoft,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Conversations',
                                    style: AppType.h3,
                                  ),
                                ],
                              ),
                            ),
                            _iconButton(
                              Icons.close_rounded,
                              'Close history',
                              () => setState(() => _showHistory = false),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _handleNewChat,
                            icon: const Icon(Icons.add_rounded, size: 19),
                            label: const Text('New chat'),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (conversations.isEmpty)
                        Expanded(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.xxxl),
                              child: Text(
                                'No conversations yet.\nAsk Cineva AI something.',
                                textAlign: TextAlign.center,
                                style: AppType.bodySmall.copyWith(height: 1.6),
                              ),
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.md,
                              AppSpacing.sm,
                              AppSpacing.md,
                              AppSpacing.xxxl,
                            ),
                            itemCount: conversations.length,
                            itemBuilder: (context, index) {
                              final c = conversations[index];
                              final isActive =
                                  c.id ==
                                  ChatStore.instance.currentConversationId;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Material(
                                  color: isActive
                                      ? AppColors.surfaceLight
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.md,
                                  ),
                                  child: InkWell(
                                    onTap: () => _handleSelectHistory(c.id),
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.md,
                                    ),
                                    child: Container(
                                      constraints: const BoxConstraints(
                                        minHeight: 50,
                                      ),
                                      padding: const EdgeInsets.only(
                                        left: AppSpacing.md,
                                        right: AppSpacing.xs,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.chat_bubble_outline_rounded,
                                            size: 16,
                                            color: isActive
                                                ? AppColors.primarySoft
                                                : AppColors.textMuted,
                                          ),
                                          const SizedBox(width: AppSpacing.sm),
                                          Expanded(
                                            child: Text(
                                              c.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppType.bodySmall.copyWith(
                                                fontSize: 13,
                                                color: isActive
                                                    ? AppColors.text
                                                    : AppColors.textSecondary,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            tooltip:
                                                'Delete conversation ${c.title}',
                                            onPressed: () =>
                                                _handleDeleteHistory(c.id),
                                            icon: const Icon(
                                              Icons.delete_outline_rounded,
                                              size: 18,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.6)),
      ),
      child: Row(
        children: [
          _iconButton(
            Icons.notes_rounded,
            'Open chat history',
            () => setState(() => _showHistory = true),
          ),
          const SizedBox(width: AppSpacing.md),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: AppGradients.ai,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondary.withValues(alpha: 0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 19,
              color: AppColors.text,
            ),
          ),
          const SizedBox(width: AppSpacing.sm + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Cineva AI', style: AppType.h3),
                Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'YOUR FILM CONCIERGE',
                      style: AppType.caption.copyWith(fontSize: 8.5),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _iconButton(Icons.add_rounded, 'Start a new chat', _handleNewChat),
        ],
      ),
    );
  }

  Widget _iconButton(IconData icon, String tooltip, VoidCallback onTap) {
    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(icon, size: 21, color: AppColors.text),
            ),
          ),
        ),
      ),
    );
  }

  Widget _welcome() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth =
            (constraints.maxWidth - AppSpacing.xxl * 2 - AppSpacing.sm) / 2;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxl,
            AppSpacing.xxxl,
            AppSpacing.xxl,
            AppSpacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.secondaryDeep, Color(0xFF172554)],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: AppColors.secondarySoft.withValues(alpha: 0.24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.28),
                      blurRadius: 42,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 38,
                  color: AppColors.secondarySoft,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'What should we\nwatch tonight?',
                style: AppType.h1.copyWith(
                  fontSize: 30,
                  height: 1.08,
                  letterSpacing: -0.8,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Describe a mood, a scene, or a half-remembered title. '
                'Cineva AI will find the match.',
                style: AppType.body.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.55,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxxl),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'TRY ASKING',
                  style: AppType.caption.copyWith(color: AppColors.primarySoft),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: _suggestions
                    .map(
                      (s) => _SuggestionTile(
                        width: cardWidth,
                        icon: s.$1,
                        text: s.$2,
                        onTap: () => _handleSend(s.$2),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _messages(List<ChatMessageData> messages) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.sm),
      itemCount: messages.length + (_loading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == messages.length) return const _TypingIndicator();
        return ChatMessageBubble(message: messages[index]);
      },
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({
    required this.width,
    required this.icon,
    required this.text,
    required this.onTap,
  });

  final double width;
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: text,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            width: width,
            constraints: const BoxConstraints(minHeight: 88),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 20, color: AppColors.secondarySoft),
                const SizedBox(height: AppSpacing.sm + 2),
                Text(
                  text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.bodySmall.copyWith(
                    color: AppColors.text,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatInputWrapper extends StatelessWidget {
  const _ChatInputWrapper({required this.loading, required this.onSend});

  final bool loading;
  final void Function(String text) onSend;

  @override
  Widget build(BuildContext context) {
    return ChatInput(onSend: onSend, loading: loading);
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              gradient: AppGradients.ai,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 14,
              color: AppColors.text,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadius.lg),
                topRight: Radius.circular(AppRadius.lg),
                bottomLeft: Radius.circular(AppRadius.sm),
                bottomRight: Radius.circular(AppRadius.lg),
              ),
            ),
            child: const _TypingDots(),
          ),
        ],
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (_controller.value * 3 - i).clamp(0.0, 1.0);
            final opacity = 0.3 + 0.7 * phase;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.secondarySoft,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
