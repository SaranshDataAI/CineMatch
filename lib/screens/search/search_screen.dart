import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Supported filter data
// ─────────────────────────────────────────────────────────────────────────────

const _contentTypeChips = [
  ('All',        null,          Icons.all_inclusive_rounded),
  ('Movies',     'movie',       Icons.movie_filter_rounded),
  ('TV Series',  'tv',          Icons.tv_rounded),
  ('Bollywood',  'bollywood',   Icons.music_note_rounded),
  ('South',      'kollywood',   Icons.stars_rounded),  // tap again for tollywood etc.
];

const _genreChips = [
  ('Anime',   'anime',  Icons.auto_awesome_rounded),
  ('K-Drama', 'kdrama', Icons.favorite_rounded),
];

const _moodChips = [
  ('😂 Happy',      'happy'),
  ('💔 Sad',        'sad'),
  ('🔥 Thrilling',  'thrilling'),
  ('😱 Scary',      'scary'),
  ('💕 Romantic',   'romantic'),
  ('🌍 Adventure',  'adventurous'),
  ('💡 Inspiring',  'inspiring'),
  ('🌑 Dark',       'dark'),
];

const _languageChips = [
  ('English',   'en'),
  ('Hindi',     'hi'),
  ('Korean',    'ko'),
  ('Japanese',  'ja'),
  ('Tamil',     'ta'),
  ('Telugu',    'te'),
  ('Malayalam', 'ml'),
];

// Rating presets  (min, max)
const _ratingPresets = [
  ('Any',    null,  null),
  ('7+',     7.0,   null),
  ('8+',     8.0,   null),
  ('9+',     9.0,   null),
];

// Year presets  (from, to)
const _yearPresets = [
  ('Any Era',  null,  null),
  ('2020s',    2020,  null),
  ('2010s',    2010,  2019),
  ('2000s',    2000,  2009),
  ('Classic',  null,  1999),
];

// ─────────────────────────────────────────────────────────────────────────────

class SearchScreen extends ConsumerStatefulWidget {
  final String? initialQuery;
  final String? initialFilter;
  final String? initialGenreFilter;

  const SearchScreen({
    super.key,
    this.initialQuery,
    this.initialFilter,
    this.initialGenreFilter,
  });

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _ctrl;
  final FocusNode _focusNode = FocusNode();
  final _overlayController  = OverlayPortalController();
  final _layerLink          = LayerLink();
  bool _showAdvanced        = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialQuery ?? '');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialGenreFilter != null) {
        ref.read(searchProvider.notifier).setGenreFilter(widget.initialGenreFilter);
      }
      if (widget.initialFilter != null) {
        ref.read(searchProvider.notifier).applyInitialFilter(widget.initialFilter);
      }
      if (widget.initialQuery?.isNotEmpty == true) {
        ref.read(searchProvider.notifier).search(widget.initialQuery!);
      }
    });

    _focusNode.addListener(() {
      if (!mounted) return;
      final s = ref.read(searchProvider);
      if (_focusNode.hasFocus && s.suggestions.isNotEmpty) {
        if (!_overlayController.isShowing) _overlayController.show();
      } else if (!_focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted && _overlayController.isShowing) _overlayController.hide();
        });
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    ref.read(searchProvider.notifier).onQueryChanged(value);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final sug = ref.read(searchProvider).suggestions;
      if (sug.isNotEmpty && _focusNode.hasFocus) {
        if (!_overlayController.isShowing) _overlayController.show();
      } else if (sug.isEmpty && _overlayController.isShowing) {
        _overlayController.hide();
      }
    });
  }

  void _onSearch(String title) {
    _ctrl.text = title;
    if (_overlayController.isShowing) _overlayController.hide();
    _focusNode.unfocus();
    ref.read(searchProvider.notifier).search(title);
  }

  @override
  Widget build(BuildContext context) {
    final s           = ref.watch(searchProvider);
    final savedTitles = ref.watch(savedTitlesProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (s.suggestions.isNotEmpty && _focusNode.hasFocus) {
        if (!_overlayController.isShowing) _overlayController.show();
      } else if (s.suggestions.isEmpty && _overlayController.isShowing) {
        _overlayController.hide();
      }
    });

    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: (event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape &&
            _overlayController.isShowing) {
          _overlayController.hide();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ─────────────────────────────────────────────────
              Text('Discover', style: Theme.of(context).textTheme.displaySmall)
                  .animate().fadeIn(),
              const SizedBox(height: 4),
              Text('Find what to watch next',
                      style: Theme.of(context).textTheme.bodyLarge)
                  .animate().fadeIn(delay: 80.ms),
              const SizedBox(height: 20),

              // ── Search Input ────────────────────────────────────────────
              OverlayPortal(
                controller: _overlayController,
                overlayChildBuilder: (_) => _SuggestionsOverlay(
                  layerLink:   _layerLink,
                  suggestions: s.suggestions,
                  onSelect:    _onSearch,
                ),
                child: CompositedTransformTarget(
                  link: _layerLink,
                  child: CMTextField(
                    controller: _ctrl,
                    hint:       'Search movies or TV shows...',
                    focusNode:  _focusNode,
                    onChanged:  _onQueryChanged,
                    onSubmitted: (v) {
                      if (v.trim().isNotEmpty) _onSearch(v.trim());
                    },
                    prefix: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Icon(Icons.search_rounded,
                          color: AppColors.textMuted, size: 22),
                    ),
                    suffix: s.query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded,
                                color: AppColors.textMuted, size: 20),
                            onPressed: () {
                              _ctrl.clear();
                              ref.read(searchProvider.notifier).onQueryChanged('');
                            },
                          )
                        : null,
                  ),
                ),
              ).animate().fadeIn(delay: 120.ms),
              const SizedBox(height: 14),

              // ── Primary filter row ──────────────────────────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  // Content-type chips
                  for (final (label, value, icon) in _contentTypeChips) ...[
                    CMFilterChip(
                      label:    label,
                      selected: value == null
                          ? (s.contentTypeFilter == null && s.genreFilter == null)
                          : s.contentTypeFilter == value,
                      onTap: () {
                        ref.read(searchProvider.notifier).setFilter(value);
                        if (value == null) {
                          ref.read(searchProvider.notifier).setGenreFilter(null);
                        }
                      },
                      icon: icon, small: false,
                    ),
                    const SizedBox(width: 8),
                  ],
                  // Genre chips (anime / kdrama)
                  for (final (label, value, icon) in _genreChips) ...[
                    CMFilterChip(
                      label:    label,
                      selected: s.genreFilter == value,
                      onTap: () =>
                          ref.read(searchProvider.notifier).setGenreFilter(value),
                      icon: icon, small: false,
                    ),
                    const SizedBox(width: 8),
                  ],
                  // Advanced toggle
                  _AdvancedToggleChip(
                    active:  _showAdvanced || s.hasAdvancedFilter,
                    onTap: () => setState(() => _showAdvanced = !_showAdvanced),
                  ),
                ]),
              ).animate().fadeIn(delay: 160.ms),

              // ── Advanced filter panel ───────────────────────────────────
              if (_showAdvanced) ...[
                const SizedBox(height: 12),
                _AdvancedFilterPanel(state: s).animate().fadeIn(),
              ],

              // Active advanced filter badges
              if (s.hasAdvancedFilter) ...[
                const SizedBox(height: 8),
                _ActiveFilterBadges(state: s),
              ],

              const SizedBox(height: 16),

              // ── Results ─────────────────────────────────────────────────
              Expanded(
                child: _ResultsSection(
                  searchState:  s,
                  savedTitles:  savedTitles,
                  onSaveToggle: (title) =>
                      ref.read(savedTitlesProvider.notifier).toggle(title),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Advanced Filter Panel
// ─────────────────────────────────────────────────────────────────────────────

class _AdvancedFilterPanel extends ConsumerWidget {
  final SearchState state;
  const _AdvancedFilterPanel({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(searchProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Language ──────────────────────────────────────────────────
          _FilterSection(
            title: 'Language',
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                for (final (label, code) in _languageChips) ...[
                  CMFilterChip(
                    label:    label,
                    selected: state.languageFilter == code,
                    onTap:   () => notifier.setLanguageFilter(
                        state.languageFilter == code ? null : code),
                    small:   true,
                  ),
                  const SizedBox(width: 6),
                ],
              ]),
            ),
          ),
          const SizedBox(height: 14),

          // ── Mood ──────────────────────────────────────────────────────
          _FilterSection(
            title: 'Mood',
            child: Wrap(spacing: 6, runSpacing: 6, children: [
              for (final (label, value) in _moodChips)
                CMFilterChip(
                  label:    label,
                  selected: state.moodFilter == value,
                  onTap:   () => notifier.setMoodFilter(
                      state.moodFilter == value ? null : value),
                  small:   true,
                ),
            ]),
          ),
          const SizedBox(height: 14),

          // ── Year & Rating side by side ─────────────────────────────────
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: _FilterSection(
                title: 'Year',
                child: Wrap(spacing: 6, runSpacing: 6, children: [
                  for (final (label, from, to) in _yearPresets)
                    CMFilterChip(
                      label:    label,
                      selected: state.yearFrom == from && state.yearTo == to,
                      onTap:   () => notifier.setYearRange(from, to),
                      small:   true,
                    ),
                ]),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _FilterSection(
                title: 'Min Rating',
                child: Wrap(spacing: 6, runSpacing: 6, children: [
                  for (final (label, min, max) in _ratingPresets)
                    CMFilterChip(
                      label:    label,
                      selected: state.minRating == min && state.maxRating == max,
                      onTap:   () => notifier.setRatingRange(min, max),
                      small:   true,
                    ),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 14),

          // ── Diversity slider ───────────────────────────────────────────
          _FilterSection(
            title: 'Result Diversity  ${(state.diversity * 100).round()}%',
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              ),
              child: Slider(
                value: state.diversity,
                min:   0,
                max:   1,
                divisions: 10,
                activeColor: AppColors.primary,
                onChanged: (v) => notifier.setDiversity(v),
              ),
            ),
          ),

          // ── Clear all ─────────────────────────────────────────────────
          if (state.hasAdvancedFilter)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => notifier.clearAllAdvancedFilters(),
                icon: const Icon(Icons.clear_all_rounded, size: 18),
                label: const Text('Clear advanced'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textMuted,
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  final String title;
  final Widget child;
  const _FilterSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8)),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Active filter badges row
// ─────────────────────────────────────────────────────────────────────────────

class _ActiveFilterBadges extends ConsumerWidget {
  final SearchState state;
  const _ActiveFilterBadges({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(searchProvider.notifier);
    final badges   = <Widget>[];

    void addBadge(String label, VoidCallback onClear) {
      badges.add(_FilterBadge(label: label, onClear: onClear));
      badges.add(const SizedBox(width: 6));
    }

    if (state.languageFilter != null) {
      addBadge('Lang: ${state.languageFilter}',
          () => notifier.setLanguageFilter(null));
    }
    if (state.moodFilter != null) {
      addBadge('Mood: ${state.moodFilter}',
          () => notifier.setMoodFilter(null));
    }
    if (state.yearFrom != null || state.yearTo != null) {
      final label = state.yearFrom != null && state.yearTo != null
          ? '${state.yearFrom}–${state.yearTo}'
          : state.yearFrom != null
              ? '${state.yearFrom}+'
              : 'Before ${state.yearTo}';
      addBadge('Year: $label', () => notifier.setYearRange(null, null));
    }
    if (state.minRating != null) {
      addBadge('★ ${state.minRating}+', () => notifier.setRatingRange(null, null));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: badges),
    );
  }
}

class _FilterBadge extends StatelessWidget {
  final String label;
  final VoidCallback onClear;
  const _FilterBadge({required this.label, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color:        AppColors.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: AppColors.primary.withOpacity(0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: onClear,
          child: const Icon(Icons.close_rounded, size: 13, color: AppColors.primary),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Advanced toggle chip
// ─────────────────────────────────────────────────────────────────────────────

class _AdvancedToggleChip extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  const _AdvancedToggleChip({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color:        active ? AppColors.primary.withOpacity(0.15) : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border:       Border.all(
              color: active ? AppColors.primary : AppColors.border, width: 1),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.tune_rounded,
              size: 15,
              color: active ? AppColors.primary : AppColors.textMuted),
          const SizedBox(width: 6),
          Text('Filters',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active ? AppColors.primary : AppColors.textMuted)),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Suggestions overlay
// ─────────────────────────────────────────────────────────────────────────────

class _SuggestionsOverlay extends StatelessWidget {
  final LayerLink layerLink;
  final List suggestions;
  final ValueChanged<String> onSelect;

  const _SuggestionsOverlay({
    required this.layerLink,
    required this.suggestions,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      child: CompositedTransformFollower(
        link:            layerLink,
        showWhenUnlinked: false,
        offset:          const Offset(0, 56),
        child: Material(
          color: Colors.transparent,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width > 700
                  ? 600
                  : MediaQuery.of(context).size.width - 48,
              maxHeight: 300,
            ),
            child: Container(
              decoration: BoxDecoration(
                color:        AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border:       Border.all(color: AppColors.border, width: 0.5),
                boxShadow: [
                  BoxShadow(
                    color:      Colors.black.withOpacity(0.5),
                    blurRadius: 20,
                    offset:     const Offset(0, 8),
                  ),
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 6),
                itemCount: suggestions.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: AppColors.border),
                itemBuilder: (context, index) {
                  final s = suggestions[index];
                  return InkWell(
                    onTap: () => onSelect(s.title),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      child: Row(children: [
                        const Icon(Icons.search_rounded,
                            color: AppColors.textMuted, size: 16),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(s.title,
                              style: const TextStyle(
                                  color: AppColors.textPrimary, fontSize: 14)),
                        ),
                        // Show content type badge if available
                        if (s.type != null)
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(s.type!,
                                style: const TextStyle(
                                    fontSize: 9,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700)),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('${s.score}%',
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ]),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Results section
// ─────────────────────────────────────────────────────────────────────────────

class _ResultsSection extends StatelessWidget {
  final dynamic searchState;
  final Set<String> savedTitles;
  final ValueChanged<String> onSaveToggle;

  const _ResultsSection({
    required this.searchState,
    required this.savedTitles,
    required this.onSaveToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (searchState.isLoadingResults) {
      return ListView.separated(
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => const ShimmerCard(),
      );
    }

    if (searchState.error != null) {
      return EmptyState(
        icon:     Icons.search_off_rounded,
        title:    'No results found',
        subtitle: searchState.error!,
      );
    }

    if (!searchState.hasSearched) {
      return const EmptyState(
        icon:     Icons.movie_filter_outlined,
        title:    'Start searching',
        subtitle: 'Type a movie or TV series title to find similar recommendations.',
      );
    }

    if (searchState.results.isEmpty) {
      return const EmptyState(
        icon:     Icons.search_off_rounded,
        title:    'No matches',
        subtitle: 'Try a different title or remove some filters.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('${searchState.results.length} recommendations',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(width: 8),
          Expanded(
            child: Text('for "${searchState.query}"',
                style: Theme.of(context).textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis),
          ),
        ]).animate().fadeIn(),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            itemCount: searchState.results.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final rec = searchState.results[index];
              return RecommendationCard(
                recommendation: rec,
                isSaved:        savedTitles.contains(rec.title),
                onSaveToggle:   () => onSaveToggle(rec.title),
                index:          index,
              );
            },
          ),
        ),
      ],
    );
  }
}
