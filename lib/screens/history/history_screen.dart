// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../theme.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';
import '../../services/firebase_service.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authStateProvider);

    // Still loading auth
    if (userAsync.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body:
            Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final user = userAsync.value;

    // Not logged in — show prompt
    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_outline_rounded,
                        color: AppColors.primary, size: 36),
                  ),
                  const SizedBox(height: 20),
                  Text('Sign in to see your history',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text('Your search history is saved when you\'re logged in.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go('/auth'),
                    child: const Text('Sign In'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final historyAsync = ref.watch(historyProvider(user.uid));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('History',
                                style: Theme.of(context).textTheme.displaySmall)
                            .animate()
                            .fadeIn(),
                        Text('Your past searches',
                                style: Theme.of(context).textTheme.bodyLarge)
                            .animate()
                            .fadeIn(delay: 80.ms),
                      ],
                    ),
                  ),
                  historyAsync.whenOrNull(
                        data: (items) => items.isEmpty
                            ? null
                            : _ClearButton(
                                onTap: () =>
                                    _confirmClear(context, ref, user.uid),
                              ),
                      ) ??
                      const SizedBox(),
                ],
              ),
              const SizedBox(height: 24),

              // ── Content ──────────────────────────────────────────────────────
              Expanded(
                child: historyAsync.when(
                  loading: () => ListView.separated(
                    itemCount: 5,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, __) => const ShimmerCard(),
                  ),
                  error: (e, __) => _HistoryErrorState(error: e.toString()),
                  data: (items) {
                    if (items.isEmpty) {
                      return _EmptyHistoryState();
                    }
                    return ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        return _HistoryCard(
                          item: items[index],
                          index: index,
                          onDelete: () => ref
                              .read(firebaseServiceProvider)
                              .deleteHistoryItem(items[index].id),
                          onRepeat: () {
                            context.go(
                                '/search?q=${Uri.encodeComponent(items[index].query)}');
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmClear(
      BuildContext context, WidgetRef ref, String uid) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear History',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
            'This will permanently delete all your search history.',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(firebaseServiceProvider).clearUserHistory(uid);
    }
  }
}

// ─── Clear Button ─────────────────────────────────────────────────────────────

class _ClearButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ClearButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline_rounded,
                size: 14, color: AppColors.textMuted),
            SizedBox(width: 5),
            Text('Clear all',
                style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyHistoryState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: const Icon(Icons.history_rounded,
                color: AppColors.textMuted, size: 40),
          ),
          const SizedBox(height: 20),
          Text('No search history',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Your searches will appear here\nafter you start discovering titles.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Builder(
              builder: (ctx) => ElevatedButton.icon(
                    onPressed: () => ctx.go('/search'),
                    icon: const Icon(Icons.search_rounded, size: 18),
                    label: const Text('Start Searching'),
                  )),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95));
  }
}

// ─── Error State ──────────────────────────────────────────────────────────────

class _HistoryErrorState extends StatelessWidget {
  final String error;
  const _HistoryErrorState({required this.error});

  bool get _isIndexError =>
      error.contains('index') || error.contains('FAILED_PRECONDITION');

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isIndexError
                    ? Icons.build_outlined
                    : Icons.error_outline_rounded,
                color: AppColors.accent,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isIndexError
                  ? 'Database Setup Required'
                  : 'Failed to load history',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _isIndexError
                  ? 'A Firestore index is required.\n\nOpen your debug console, find the Firebase error and click the index link to auto-create it. It takes ~2 minutes.'
                  : 'Check your connection and try again.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── History Card ─────────────────────────────────────────────────────────────

class _HistoryCard extends StatefulWidget {
  final SearchHistoryItem item;
  final int index;
  final VoidCallback onDelete;
  final VoidCallback onRepeat;

  const _HistoryCard({
    required this.item,
    required this.index,
    required this.onDelete,
    required this.onRepeat,
  });

  @override
  State<_HistoryCard> createState() => _HistoryCardState();
}

class _HistoryCardState extends State<_HistoryCard> {
  bool _hovered = false;
  bool _expanded = false;

  String get _typeLabel {
    switch (widget.item.contentType) {
      case 'movie':
        return 'Movies';
      case 'tv':
        return 'TV Series';
      case 'anime':
        return 'Anime';
      case 'kdrama':
        return 'K-Drama';
      default:
        return 'All';
    }
  }

  Color get _typeColor {
    switch (widget.item.contentType) {
      case 'movie':
        return AppColors.primary;
      case 'anime':
        return const Color(0xFFFF6B35);
      case 'kdrama':
        return const Color(0xFFBB86FC);
      case 'tv':
        return const Color(0xFF2176AE);
      default:
        return AppColors.textMuted;
    }
  }

  IconData get _typeIcon {
    switch (widget.item.contentType) {
      case 'movie':
        return Icons.movie_rounded;
      case 'anime':
        return Icons.animation_rounded;
      case 'kdrama':
        return Icons.live_tv_rounded;
      default:
        return Icons.tv_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM d · h:mm a').format(widget.item.timestamp);
    final hasResults = widget.item.results.isNotEmpty;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: hasResults ? () => setState(() => _expanded = !_expanded) : null,
        child: AnimatedContainer(
          duration: AppConstants.animationFast,
          decoration: BoxDecoration(
            color: _hovered ? AppColors.cardHover : AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hovered ? AppColors.borderHover : AppColors.border,
              width: 0.5,
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _typeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(_typeIcon, color: _typeColor, size: 18),
                    ),
                    const SizedBox(width: 14),

                    // Query + meta
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.item.query,
                            style: Theme.of(context).textTheme.headlineSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.schedule_rounded,
                                  size: 11, color: AppColors.textMuted),
                              const SizedBox(width: 4),
                              Text(dateStr,
                                  style: Theme.of(context).textTheme.bodySmall),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _typeColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                      color: _typeColor.withOpacity(0.25),
                                      width: 0.5),
                                ),
                                child: Text(
                                  _typeLabel,
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: _typeColor,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                              if (hasResults) ...[
                                const SizedBox(width: 8),
                                Text('${widget.item.results.length} results',
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textMuted)),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Actions
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_hovered || _expanded) ...[
                          _ActionIcon(
                            icon: Icons.replay_rounded,
                            tooltip: 'Search again',
                            onTap: widget.onRepeat,
                          ),
                          const SizedBox(width: 4),
                          _ActionIcon(
                            icon: Icons.delete_outline_rounded,
                            tooltip: 'Delete',
                            onTap: widget.onDelete,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 4),
                        ],
                        if (hasResults)
                          AnimatedRotation(
                            turns: _expanded ? 0.5 : 0,
                            duration: AppConstants.animationFast,
                            child: const Icon(Icons.keyboard_arrow_down_rounded,
                                color: AppColors.textMuted, size: 20),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Expandable results
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: _ResultsExpanded(results: widget.item.results),
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: AppConstants.animationFast,
              ),
            ],
          ),
        )
            .animate(delay: Duration(milliseconds: widget.index * 50))
            .fadeIn(duration: 350.ms)
            .slideY(begin: 0.08),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color color;

  const _ActionIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color = AppColors.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
      ),
    );
  }
}

class _ResultsExpanded extends StatelessWidget {
  final List<String> results;
  const _ResultsExpanded({required this.results});

  @override
  Widget build(BuildContext context) {
    final display = results.take(6).toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.list_alt_rounded,
                  size: 13, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text('Top results', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: display.asMap().entries.map((e) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${e.key + 1}',
                          style: const TextStyle(
                              fontSize: 9,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      e.value,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          if (results.length > 6)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('+${results.length - 6} more',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textMuted)),
            ),
        ],
      ),
    );
  }
}
