// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../theme.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final firstName = (user?.displayName ?? 'Movie Fan').split(' ').first;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
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
                      Text(
                        'Hello, $firstName 👋',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.textMuted,
                            ),
                      ).animate().fadeIn(delay: 100.ms),
                      const SizedBox(height: 4),
                      Text(
                        'What are you\nwatching next?',
                        style: Theme.of(context).textTheme.displaySmall,
                      ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ── Search Bar ───────────────────────────────────────────────────
            GestureDetector(
              onTap: () => context.go('/search'),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded,
                        color: AppColors.textMuted, size: 22),
                    const SizedBox(width: 12),
                    const Text('Search a movie or TV show...',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 15)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                            width: 0.5),
                      ),
                      child: const Text('⌘ K',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 40),

            // ── Quick Filters ────────────────────────────────────────────────
            Text('Browse by type',
                    style: Theme.of(context).textTheme.headlineSmall)
                .animate()
                .fadeIn(delay: 250.ms),
            const SizedBox(height: 16),
            // BUG FIX: Use proper URI with context.go so router reads ?type= param
            Row(
              children: [
                Expanded(
                  child: _TypeCard(
                    icon: Icons.movie_filter_rounded,
                    label: 'Movies',
                    color: AppColors.primary,
                    // BUG FIX: was '/search?type=movie' — now correctly navigates
                    onTap: () => context.go('/search?type=movie'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TypeCard(
                    icon: Icons.tv_rounded,
                    label: 'TV Series',
                    color: const Color(0xFF2176AE),
                    onTap: () => context.go('/search?type=tv'),
                  ),
                ),
                const SizedBox(width: 12),
                // BUG FIX: Added Anime card
                Expanded(
                  child: _TypeCard(
                    icon: Icons.auto_awesome_rounded,
                    label: 'Anime',
                    color: const Color(0xFF9B59B6),
                    onTap: () => context.go('/search?genre=anime'),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 12),
            // BUG FIX: K-Drama card in its own row
            Row(
              children: [
                Expanded(
                  child: _TypeCard(
                    icon: Icons.favorite_rounded,
                    label: 'K-Drama',
                    color: const Color(0xFFE91E8C),
                    onTap: () => context.go('/search?genre=kdrama'),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(child: SizedBox()),
                const SizedBox(width: 12),
                const Expanded(child: SizedBox()),
              ],
            ).animate().fadeIn(delay: 320.ms),
            const SizedBox(height: 40),

            // ── How it works ─────────────────────────────────────────────────
            Text('How it works',
                    style: Theme.of(context).textTheme.headlineSmall)
                .animate()
                .fadeIn(delay: 350.ms),
            const SizedBox(height: 16),
            ...[
              const _StepCard(
                number: '01',
                title: 'Search a title',
                subtitle:
                    'Type any movie or TV show you love. Our autocomplete finds it instantly.',
                icon: Icons.search_rounded,
              ),
              const _StepCard(
                number: '02',
                title: 'Get AI recommendations',
                subtitle:
                    'Our hybrid SBERT + TF-IDF model finds the most similar titles across genres.',
                icon: Icons.auto_awesome_rounded,
              ),
              const _StepCard(
                number: '03',
                title: 'Save your favorites',
                subtitle:
                    'Bookmark titles and revisit your search history anytime.',
                icon: Icons.bookmark_rounded,
              ),
            ].asMap().entries.map(
                  (e) => e.value
                      .animate(delay: Duration(milliseconds: 400 + e.key * 80))
                      .fadeIn()
                      .slideY(begin: 0.1),
                ),
          ],
        ),
      ),
    );
  }
}

class _TypeCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _TypeCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_TypeCard> createState() => _TypeCardState();
}

class _TypeCardState extends State<_TypeCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppConstants.animationFast,
          height: 110,
          decoration: BoxDecoration(
            color: _hovered ? widget.color.withOpacity(0.15) : AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  _hovered ? widget.color.withOpacity(0.4) : AppColors.border,
              width: 0.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: widget.color, size: 32),
              const SizedBox(height: 8),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;
  final IconData icon;

  const _StepCard({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Text(
            number,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.border,
              fontFamily: 'PlayfairDisplay',
            ),
          ),
          const SizedBox(width: 20),
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
