import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';

class DetailScreen extends ConsumerStatefulWidget {
  final Recommendation recommendation;

  const DetailScreen({super.key, required this.recommendation});

  @override
  ConsumerState<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends ConsumerState<DetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  final ScrollController _scrollController = ScrollController();
  double _headerOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _scrollController.addListener(() {
      final offset = _scrollController.offset;
      final newOpacity = (offset / 180).clamp(0.0, 1.0);
      if ((newOpacity - _headerOpacity).abs() > 0.01) {
        setState(() => _headerOpacity = newOpacity);
      }
    });
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Color get _typeColor {
    switch (widget.recommendation.type.toLowerCase()) {
      case 'movie':
        return AppColors.primary;
      case 'anime':
        return const Color(0xFFFF6B35);
      case 'kdrama':
        return const Color(0xFFBB86FC);
      default:
        return const Color(0xFF2176AE);
    }
  }

  String get _typeLabel {
    switch (widget.recommendation.type.toLowerCase()) {
      case 'movie':
        return 'MOVIE';
      case 'anime':
        return 'ANIME';
      case 'kdrama':
        return 'K-DRAMA';
      default:
        return 'TV SERIES';
    }
  }

  IconData get _typeIcon {
    switch (widget.recommendation.type.toLowerCase()) {
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
    final savedTitles = ref.watch(savedTitlesProvider);
    final isSaved = savedTitles.contains(widget.recommendation.title);
    final score = widget.recommendation.scorePercent;

    final Color scoreColor;
    if (score >= 80) {
      scoreColor = AppColors.success;
    } else if (score >= 60) {
      scoreColor = const Color(0xFF27AE60);
    } else if (score >= 40) {
      scoreColor = AppColors.warning;
    } else {
      scoreColor = AppColors.accent;
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        extendBodyBehindAppBar: true,
        appBar: _buildAppBar(isSaved, scoreColor),
        body: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: _HeroPoster(
                recommendation: widget.recommendation,
                typeColor: _typeColor,
                typeLabel: _typeLabel,
                typeIcon: _typeIcon,
                score: score,
                scoreColor: scoreColor,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 60),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _QuickStatsRow(
                      recommendation: widget.recommendation,
                      typeColor: _typeColor,
                      scoreColor: scoreColor,
                      score: score,
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                    const SizedBox(height: 24),
                    _MatchScoreCard(score: score, scoreColor: scoreColor)
                        .animate()
                        .fadeIn(delay: 280.ms)
                        .slideY(begin: 0.1),
                    const SizedBox(height: 24),
                    _ContentInfoSection(
                      recommendation: widget.recommendation,
                      typeColor: _typeColor,
                      typeLabel: _typeLabel,
                      typeIcon: _typeIcon,
                    ).animate().fadeIn(delay: 360.ms).slideY(begin: 0.1),
                    const SizedBox(height: 24),
                    _WhyRecommendedCard(
                      recommendation: widget.recommendation,
                      typeColor: _typeColor,
                      score: score,
                    ).animate().fadeIn(delay: 440.ms).slideY(begin: 0.1),
                    const SizedBox(height: 32),
                    _SaveButton(
                      isSaved: isSaved,
                      onTap: () => ref
                          .read(savedTitlesProvider.notifier)
                          .toggle(widget.recommendation.title),
                    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isSaved, Color scoreColor) {
    return AppBar(
      backgroundColor: AppColors.background.withOpacity(_headerOpacity),
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant.withOpacity(0.85),
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppColors.border.withOpacity(0.6), width: 0.5),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.textPrimary, size: 18),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () => ref
                .read(savedTitlesProvider.notifier)
                .toggle(widget.recommendation.title),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSaved
                    ? AppColors.primary.withOpacity(0.2)
                    : AppColors.surfaceVariant.withOpacity(0.85),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSaved
                      ? AppColors.primary.withOpacity(0.5)
                      : AppColors.border.withOpacity(0.6),
                  width: 0.5,
                ),
              ),
              child: Icon(
                isSaved
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_outline_rounded,
                color: isSaved ? AppColors.primary : AppColors.textMuted,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Hero Poster ─────────────────────────────────────────────────────────────

class _HeroPoster extends StatelessWidget {
  final Recommendation recommendation;
  final Color typeColor;
  final String typeLabel;
  final IconData typeIcon;
  final int score;
  final Color scoreColor;

  const _HeroPoster({
    required this.recommendation,
    required this.typeColor,
    required this.typeLabel,
    required this.typeIcon,
    required this.score,
    required this.scoreColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasPoster = recommendation.posterUrl != null;
    final screenH = MediaQuery.of(context).size.height;

    return SizedBox(
      height: screenH * 0.52,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasPoster)
            Image.network(
              recommendation.posterUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _CinematicPlaceholder(
                  typeColor: typeColor, typeIcon: typeIcon),
            )
          else
            _CinematicPlaceholder(typeColor: typeColor, typeIcon: typeIcon),

          // Gradient overlays
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.25),
                  Colors.transparent,
                  AppColors.background.withOpacity(0.6),
                  AppColors.background,
                ],
                stops: const [0.0, 0.35, 0.75, 1.0],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppColors.background.withOpacity(0.3),
                  Colors.transparent,
                  AppColors.background.withOpacity(0.3),
                ],
              ),
            ),
          ),

          // Bottom overlay
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: typeColor.withOpacity(0.5), width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(typeIcon, color: typeColor, size: 12),
                      const SizedBox(width: 5),
                      Text(typeLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: typeColor,
                            letterSpacing: 1.5,
                          )),
                    ],
                  ),
                ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 10),
                Text(
                  recommendation.title,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    height: 1.15,
                    shadows: [
                      Shadow(
                          color: Colors.black.withOpacity(0.8), blurRadius: 12)
                    ],
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ).animate().fadeIn(delay: 60.ms).slideY(begin: 0.06),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CinematicPlaceholder extends StatelessWidget {
  final Color typeColor;
  final IconData typeIcon;
  const _CinematicPlaceholder(
      {required this.typeColor, required this.typeIcon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            typeColor.withOpacity(0.2),
            AppColors.surface,
            typeColor.withOpacity(0.08)
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
              child: CustomPaint(painter: _FilmGrainPainter(typeColor))),
          Center(
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.12),
                shape: BoxShape.circle,
                border:
                    Border.all(color: typeColor.withOpacity(0.25), width: 1),
              ),
              child:
                  Icon(typeIcon, color: typeColor.withOpacity(0.5), size: 48),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilmGrainPainter extends CustomPainter {
  final Color color;
  _FilmGrainPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withOpacity(0.04);
    final rng = math.Random(42);
    for (int i = 0; i < 80; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = rng.nextDouble() * 60 + 20;
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─── Quick Stats Row ─────────────────────────────────────────────────────────

class _QuickStatsRow extends StatelessWidget {
  final Recommendation recommendation;
  final Color typeColor;
  final Color scoreColor;
  final int score;

  const _QuickStatsRow({
    required this.recommendation,
    required this.typeColor,
    required this.scoreColor,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    final String relevanceLabel = score >= 80
        ? 'Excellent'
        : score >= 65
            ? 'Very Good'
            : score >= 50
                ? 'Good'
                : 'Moderate';
    final String matchDesc = score >= 80
        ? 'Top pick for you'
        : score >= 65
            ? 'Great match'
            : score >= 50
                ? 'Worth watching'
                : 'Partial match';

    return Row(
      children: [
        _StatPill(
            icon: Icons.percent_rounded,
            label: '$score%',
            sublabel: 'Match',
            color: scoreColor),
        const SizedBox(width: 10),
        _StatPill(
            icon: Icons.star_rounded,
            label: relevanceLabel,
            sublabel: matchDesc,
            color: AppColors.gold),
        const SizedBox(width: 10),
        _StatPill(
          icon: recommendation.type.toLowerCase() == 'movie'
              ? Icons.theaters_rounded
              : Icons.subscriptions_rounded,
          label:
              recommendation.type.toLowerCase() == 'movie' ? 'Film' : 'Series',
          sublabel: recommendation.type.toUpperCase(),
          color: typeColor,
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;

  const _StatPill(
      {required this.icon,
      required this.label,
      required this.sublabel,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2), width: 0.8),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: color),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(sublabel,
                style:
                    const TextStyle(fontSize: 10, color: AppColors.textMuted),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

// ─── Match Score Card ────────────────────────────────────────────────────────

class _MatchScoreCard extends StatelessWidget {
  final int score;
  final Color scoreColor;
  const _MatchScoreCard({required this.score, required this.scoreColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.auto_awesome_rounded,
                    color: scoreColor, size: 18),
              ),
              const SizedBox(width: 12),
              Text('AI Match Score',
                  style: Theme.of(context).textTheme.headlineSmall),
              const Spacer(),
              Text('$score%',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: scoreColor,
                    letterSpacing: -1,
                  )),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                Container(
                    height: 8,
                    decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(6))),
                FractionallySizedBox(
                  widthFactor: score / 100,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      gradient: LinearGradient(
                          colors: [scoreColor.withOpacity(0.6), scoreColor]),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['0', '25', '50', '75', '100'].map((v) {
              final active = score >= int.parse(v);
              return Text(v,
                  style: TextStyle(
                    fontSize: 10,
                    color: active
                        ? scoreColor.withOpacity(0.8)
                        : AppColors.textMuted,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  ));
            }).toList(),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: scoreColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  score >= 80
                      ? Icons.thumb_up_alt_rounded
                      : score >= 50
                          ? Icons.thumbs_up_down_rounded
                          : Icons.thumb_down_alt_rounded,
                  color: scoreColor,
                  size: 14,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    score >= 80
                        ? 'Highly recommended — our AI thinks you\'ll love this.'
                        : score >= 65
                            ? 'Strong match based on your search preferences.'
                            : score >= 50
                                ? 'Decent match — shares key elements with your search.'
                                : 'Partial match — some genre overlap with your search.',
                    style: TextStyle(
                        fontSize: 12,
                        color: scoreColor.withOpacity(0.9),
                        height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Content Info Section ────────────────────────────────────────────────────

class _ContentInfoSection extends StatelessWidget {
  final Recommendation recommendation;
  final Color typeColor;
  final String typeLabel;
  final IconData typeIcon;

  const _ContentInfoSection({
    required this.recommendation,
    required this.typeColor,
    required this.typeLabel,
    required this.typeIcon,
  });

  @override
  Widget build(BuildContext context) {
    final isMovie = recommendation.type.toLowerCase() == 'movie';
    final isAnime = recommendation.type.toLowerCase() == 'anime';
    final isKdrama = recommendation.type.toLowerCase() == 'kdrama';

    final details = [
      _InfoDetail(
          icon: typeIcon,
          label: 'Format',
          value: isMovie
              ? 'Feature Film'
              : isAnime
                  ? 'Anime Series'
                  : isKdrama
                      ? 'Korean Drama'
                      : 'TV Series',
          color: typeColor),
      _InfoDetail(
          icon: Icons.language_rounded,
          label: 'Origin',
          value: isAnime
              ? 'Japan'
              : isKdrama
                  ? 'South Korea'
                  : isMovie
                      ? 'International'
                      : 'Worldwide',
          color: const Color(0xFF2176AE)),
      _InfoDetail(
          icon: isMovie ? Icons.schedule_rounded : Icons.view_week_rounded,
          label: isMovie ? 'Runtime' : 'Episodes',
          value: isMovie
              ? '~2h'
              : isAnime
                  ? '12–24 eps'
                  : '8–16 eps',
          color: AppColors.warning),
      _InfoDetail(
          icon: Icons.workspace_premium_rounded,
          label: 'Status',
          value: isMovie ? 'Released' : 'Available',
          color: AppColors.success),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10)),
              child:
                  Icon(Icons.info_outline_rounded, color: typeColor, size: 18),
            ),
            const SizedBox(width: 12),
            Text('Content Details',
                style: Theme.of(context).textTheme.headlineSmall),
          ]),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.6,
            children: details.map((d) => _InfoDetailTile(detail: d)).toList(),
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            children: [
              _TypeBadge(label: typeLabel, color: typeColor, icon: typeIcon),
              if (isAnime || isKdrama)
                _TypeBadge(
                    label: isAnime ? 'SUBBED/DUB' : 'SUBTITLED',
                    color: AppColors.textMuted,
                    icon: Icons.subtitles_rounded),
              _TypeBadge(
                  label: isMovie ? 'HD' : 'STREAMING',
                  color: AppColors.textMuted,
                  icon: isMovie ? Icons.hd_rounded : Icons.wifi_rounded),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoDetail {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _InfoDetail(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});
}

class _InfoDetailTile extends StatelessWidget {
  final _InfoDetail detail;
  const _InfoDetailTile({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: detail.color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: detail.color.withOpacity(0.15), width: 0.5),
      ),
      child: Row(children: [
        Icon(detail.icon, color: detail.color, size: 16),
        const SizedBox(width: 8),
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(detail.label,
                style:
                    const TextStyle(fontSize: 10, color: AppColors.textMuted)),
            Text(detail.value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        )),
      ]),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _TypeBadge(
      {required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.25), width: 0.5),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 11),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.8)),
      ]),
    );
  }
}

// ─── Why Recommended Card ────────────────────────────────────────────────────

class _WhyRecommendedCard extends StatelessWidget {
  final Recommendation recommendation;
  final Color typeColor;
  final int score;

  const _WhyRecommendedCard(
      {required this.recommendation,
      required this.typeColor,
      required this.score});

  @override
  Widget build(BuildContext context) {
    final isMovie = recommendation.type.toLowerCase() == 'movie';
    final isAnime = recommendation.type.toLowerCase() == 'anime';

    final reasons = [
      _ReasonItem(
          icon: Icons.auto_awesome_rounded,
          text: 'SBERT semantic similarity matched the story tone and themes',
          strength: score >= 70 ? 'Strong' : 'Moderate',
          strengthColor: score >= 70 ? AppColors.success : AppColors.warning),
      _ReasonItem(
          icon: Icons.category_rounded,
          text: 'Genre overlap confirmed with your original search query',
          strength: 'Confirmed',
          strengthColor: typeColor),
      _ReasonItem(
          icon: Icons.trending_up_rounded,
          text: isMovie
              ? 'High theatrical popularity score on TMDB'
              : isAnime
                  ? 'Strong following in the anime community'
                  : 'Well-rated series with high audience engagement',
          strength: 'Ranked',
          strengthColor: AppColors.gold),
      const _ReasonItem(
          icon: Icons.psychology_rounded,
          text: 'TF-IDF keyword match on cast, crew and plot keywords',
          strength: 'AI Scored',
          strengthColor: Color(0xFF9B59B6)),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.psychology_alt_rounded,
                  color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Text('Why Recommended',
                style: Theme.of(context).textTheme.headlineSmall),
          ]),
          const SizedBox(height: 16),
          ...reasons.map((r) => _ReasonRow(item: r)),
        ],
      ),
    );
  }
}

class _ReasonItem {
  final IconData icon;
  final String text;
  final String strength;
  final Color strengthColor;
  const _ReasonItem(
      {required this.icon,
      required this.text,
      required this.strength,
      required this.strengthColor});
}

class _ReasonRow extends StatelessWidget {
  final _ReasonItem item;
  const _ReasonRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
                color: item.strengthColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(item.icon, color: item.strengthColor, size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.text,
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4)),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: item.strengthColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4)),
                child: Text(item.strength,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: item.strengthColor,
                        letterSpacing: 0.5)),
              ),
            ],
          )),
        ],
      ),
    );
  }
}

// ─── Save Button ─────────────────────────────────────────────────────────────

class _SaveButton extends StatelessWidget {
  final bool isSaved;
  final VoidCallback onTap;
  const _SaveButton({required this.isSaved, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: isSaved
              ? null
              : const LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary]),
          color: isSaved ? AppColors.surfaceVariant : null,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isSaved ? AppColors.border : AppColors.primary.withOpacity(0.4),
            width: 0.8,
          ),
          boxShadow: isSaved
              ? []
              : [
                  BoxShadow(
                      color: AppColors.primary.withOpacity(0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 6))
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
                isSaved
                    ? Icons.bookmark_remove_rounded
                    : Icons.bookmark_add_rounded,
                color: isSaved ? AppColors.textSecondary : Colors.white,
                size: 22),
            const SizedBox(width: 10),
            Text(isSaved ? 'Remove from Watchlist' : 'Add to Watchlist',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isSaved ? AppColors.textSecondary : Colors.white,
                    letterSpacing: 0.3)),
          ],
        ),
      ),
    );
  }
}
