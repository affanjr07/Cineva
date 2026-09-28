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
    (Icons.movie, 'Recommend me a movie'),
    (Icons.search, 'I forgot the title...'),
    (Icons.nightlight_round, 'Good movies for tonight'),
    (Icons.favorite, 'Romantic movies'),
    (Icons.local_fire_department, 'Scary horror movies'),
    (Icons.public, 'Best Korean dramas'),
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
          duration: const Duration(milliseconds: 200),
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
    final history =
        (conv?.messages ?? []).map((m) => m).toList(growable: true);

    try {
      final reply = await GeminiClient.sendChatMessage(history);
      await ChatStore.instance.addMessage(
        convId,
        ChatMessageData(role: 'model', text: reply),
      );
    } catch (err) {
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
                  child:
                      messages.isEmpty ? _welcome() : _messages(messages),
                ),
                _ChatInputWrapper(
                  loading: _loading,
                  onSend: _handleSend,
                ),
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
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () => setState(() => _showHistory = false),
            child: Container(color: Colors.black.withValues(alpha: 0.5)),
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          child: Container(
            width: 280,
            color: AppColors.surface,
            padding: const EdgeInsets.only(top: AppSpacing.xxxl),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Chat History', style: AppType.h3),
                      GestureDetector(
                        onTap: _handleNewChat,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.add,
                            size: 20,
                            color: AppColors.primarySoft,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (conversations.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(AppSpacing.xxxl),
                    child: Text(
                      'No conversations yet',
                      style: AppType.body,
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      itemCount: conversations.length,
                      itemBuilder: (context, index) {
                        final c = conversations[index];
                        final isActive =
                            c.id == ChatStore.instance.currentConversationId;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _handleSelectHistory(c.id),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.md,
                                      vertical: AppSpacing.md,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? AppColors.surfaceLight
                                          : Colors.transparent,
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.md),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.chat_bubble_outline,
                                          size: 16,
                                          color: isActive
                                              ? AppColors.primarySoft
                                              : AppColors.textMuted,
                                        ),
                                        const SizedBox(
                                            width: AppSpacing.sm),
                                        Expanded(
                                          child: Text(
                                            c.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppType.body.copyWith(
                                              fontSize: 13,
                                              color: isActive
                                                  ? AppColors.text
                                                  : AppColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.all(AppSpacing.sm),
                                child: GestureDetector(
                                  onTap: () => _handleDeleteHistory(c.id),
                                  child: const Icon(
                                    Icons.delete_outline,
                                    size: 14,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _headerBtn(Icons.menu, () => setState(() => _showHistory = true)),
          Row(
            children: const [
              Icon(Icons.auto_awesome, size: 16, color: AppColors.primarySoft),
              SizedBox(width: AppSpacing.xs),
              Text('Cineva AI', style: AppType.h3),
            ],
          ),
          _headerBtn(Icons.add, _handleNewChat),
        ],
      ),
    );
  }

  Widget _headerBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 20, color: AppColors.text),
      ),
    );
  }

  Widget _welcome() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(36),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.auto_awesome,
                size: 36,
                color: AppColors.primarySoft,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text('Cineva AI', style: AppType.h2),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Ask me about movies and series.\nI can help you find what to watch!',
              style: AppType.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxxl),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              alignment: WrapAlignment.center,
              children: _suggestions
                  .map((s) => _suggestionChip(s.$1, s.$2))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _suggestionChip(IconData icon, String text) {
    return GestureDetector(
      onTap: () => _handleSend(text),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.primarySoft),
            const SizedBox(width: AppSpacing.sm),
            Text(
              text,
              style: AppType.body.copyWith(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _messages(List<ChatMessageData> messages) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      itemCount: messages.length + (_loading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == messages.length) return const _TypingIndicator();
        return ChatMessageBubble(message: messages[index]);
      },
    );
  }
}

class _ChatInputWrapper extends StatelessWidget {
  final bool loading;
  final void Function(String text) onSend;

  const _ChatInputWrapper({required this.loading, required this.onSend});

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
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.auto_awesome,
              size: 12,
              color: AppColors.primarySoft,
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
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: _TypingDots(),
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
                    color: AppColors.primarySoft,
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