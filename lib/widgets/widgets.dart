import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme.dart';
import '../models/models.dart';
import '../screens/detail/detail_screen.dart';

// ─── Logo Widget ──────────────────────────────────────────────────────────────

class CineMatchLogo extends StatelessWidget {
  final double fontSize;
  final bool showIcon;

  const CineMatchLogo({super.key, this.fontSize = 24, this.showIcon = true});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showIcon) ...[
          Container(
            width: fontSize * 1.2,
            height: fontSize * 1.2,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Icon(Icons.movie_filter_rounded,
                  color: Colors.white, size: fontSize * 0.7),
            ),
          ),
          const SizedBox(width: 10),
        ],
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Cine',
                style: TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              TextSpan(
                text: 'Match',
                style: TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Recommendation Card ──────────────────────────────────────────────────────
// BUG FIX: Added poster image display

class RecommendationCard extends StatefulWidget {
  final Recommendation recommendation;
  final bool isSaved;
  final VoidCallback onSaveToggle;
  final int index;

  const RecommendationCard({
    super.key,
    required this.recommendation,
    required this.isSaved,
    required this.onSaveToggle,
    required this.index,
  });

  @override
  State<RecommendationCard> createState() => _RecommendationCardState();
}

class _RecommendationCardState extends State<RecommendationCard> {
  bool _hovered = false;

  Color get _typeColor => widget.recommendation.type.toLowerCase() == 'movie'
      ? AppColors.primary
      : const Color(0xFF2176AE);

  String get _typeLabel => widget.recommendation.type.toLowerCase() == 'movie'
      ? 'MOVIE'
      : 'TV SERIES';

  @override
  Widget build(BuildContext context) {
    final hasPoster = widget.recommendation.posterUrl != null;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DetailScreen(recommendation: widget.recommendation),
          ),
        );
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // BUG FIX: Poster — shows TMDB image if available, else styled placeholder
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: hasPoster
                      ? Image.network(
                          widget.recommendation.posterUrl!,
                          width: 60,
                          height: 88,
                          fit: BoxFit.cover,
                          loadingBuilder: (ctx, child, progress) {
                            if (progress == null) return child;
                            return _PosterPlaceholder(
                                color: _typeColor,
                                title: widget.recommendation.title,
                                loading: true);
                          },
                          errorBuilder: (_, __, ___) => _PosterPlaceholder(
                              color: _typeColor,
                              title: widget.recommendation.title),
                        )
                      : _PosterPlaceholder(
                          color: _typeColor,
                          title: widget.recommendation.title),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.recommendation.title,
                                  style:
                                      Theme.of(context).textTheme.headlineSmall,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _typeColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                        color: _typeColor.withOpacity(0.3),
                                        width: 0.5),
                                  ),
                                  child: Text(
                                    _typeLabel,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: _typeColor,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: widget.onSaveToggle,
                            child: AnimatedContainer(
                              duration: AppConstants.animationFast,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: widget.isSaved
                                    ? AppColors.primary.withOpacity(0.15)
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                widget.isSaved
                                    ? Icons.bookmark_rounded
                                    : Icons.bookmark_outline_rounded,
                                color: widget.isSaved
                                    ? AppColors.primary
                                    : AppColors.textMuted,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Score bar
                      Row(
                        children: [
                          _ScoreRing(score: widget.recommendation.scorePercent),
                          const SizedBox(width: 10),
                          const Text(
                            'Match Score',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: widget.index * 60))
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }
}

// BUG FIX: Poster placeholder — shows title initials when no poster is available
class _PosterPlaceholder extends StatelessWidget {
  final Color color;
  final String title;
  final bool loading;
  const _PosterPlaceholder({
    required this.color,
    required this.title,
    this.loading = false,
  });

  String get _initials {
    final words = title.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return title.substring(0, title.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 88,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.25),
            color.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2), width: 0.5),
      ),
      child: loading
          ? Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: color.withOpacity(0.5),
                ),
              ),
            )
          : Center(
              child: Text(
                _initials,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: color.withOpacity(0.7),
                  letterSpacing: -0.5,
                ),
              ),
            ),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  final int score;
  const _ScoreRing({required this.score});

  Color get _color {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return const Color(0xFF27AE60);
    if (score >= 40) return AppColors.warning;
    return AppColors.accent;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: score / 100,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(_color),
            strokeWidth: 3,
          ),
          Text(
            '$score',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shimmer Loading Card ─────────────────────────────────────────────────────

class ShimmerCard extends StatelessWidget {
  const ShimmerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Poster placeholder shimmer
            _shimmerBox(88, 60, radius: 10),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _shimmerBox(16, double.infinity),
                  const SizedBox(height: 8),
                  _shimmerBox(12, 80),
                  const SizedBox(height: 12),
                  _shimmerBox(10, 120),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(
          duration: 1500.ms,
          color: AppColors.shimmerHighlight,
          angle: 0.3,
        );
  }

  Widget _shimmerBox(double height, double width, {double radius = 6}) {
    return Container(
      height: height,
      width: width == double.infinity ? null : width,
      decoration: BoxDecoration(
        color: AppColors.shimmerHighlight,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.textMuted, size: 36),
            ),
            const SizedBox(height: 20),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

// ─── Filter Chip ──────────────────────────────────────────────────────────────

class CMFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  const CMFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    required bool small,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppConstants.animationFast,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: selected ? Colors.white : AppColors.textSecondary,
                size: 15,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Custom TextField ─────────────────────────────────────────────────────────

class CMTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? prefix;
  final Widget? suffix;
  final bool autofocus;

  const CMTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.prefix,
    this.suffix,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      autofocus: autofocus,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
      cursorColor: AppColors.primary,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: prefix,
        suffixIcon: suffix,
      ),
    );
  }
}
