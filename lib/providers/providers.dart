import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../services/api_service.dart';
import '../models/models.dart';

final firebaseServiceProvider = Provider<FirebaseService>((_) => FirebaseService());
final apiServiceProvider      = Provider<ApiService>((_)      => ApiService());

// ─── Auth Providers ───────────────────────────────────────────────────────────

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.read(firebaseServiceProvider).authStateChanges;
});

final appUserProvider =
    FutureProvider.family<AppUser?, String>((ref, uid) async {
  return ref.read(firebaseServiceProvider).getUserProfile(uid);
});

final currentAppUserProvider = FutureProvider<AppUser?>((ref) async {
  final user = await ref.watch(authStateProvider.future);
  if (user == null) return null;
  return ref.read(firebaseServiceProvider).getUserProfile(user.uid);
});

// ─── Search State ─────────────────────────────────────────────────────────────

class SearchState {
  final String query;

  // ── Content / genre filter (what to show) ──
  final String? contentTypeFilter; // movie | tv | bollywood | kollywood …
  final String? genreFilter;       // anime | kdrama

  // ── Advanced v2 filters ──
  final String? languageFilter;    // ISO-639-1: hi | en | ko | ja | ta …
  final String? moodFilter;        // happy | thrilling | romantic …
  final int?    yearFrom;
  final int?    yearTo;
  final double? minRating;
  final double? maxRating;
  final double  diversity;         // 0.0 – 1.0

  final List<AutocompleteResult> suggestions;
  final List<Recommendation>     results;
  final bool isLoadingSuggestions;
  final bool isLoadingResults;
  final String? error;
  final bool hasSearched;

  const SearchState({
    this.query               = '',
    this.contentTypeFilter,
    this.genreFilter,
    this.languageFilter,
    this.moodFilter,
    this.yearFrom,
    this.yearTo,
    this.minRating,
    this.maxRating,
    this.diversity           = 0.15,
    this.suggestions         = const [],
    this.results             = const [],
    this.isLoadingSuggestions = false,
    this.isLoadingResults    = false,
    this.error,
    this.hasSearched         = false,
  });

  SearchState copyWith({
    String? query,
    String? contentTypeFilter,
    String? genreFilter,
    String? languageFilter,
    String? moodFilter,
    int?    yearFrom,
    int?    yearTo,
    double? minRating,
    double? maxRating,
    double? diversity,
    List<AutocompleteResult>? suggestions,
    List<Recommendation>?     results,
    bool? isLoadingSuggestions,
    bool? isLoadingResults,
    String? error,
    bool? hasSearched,
    // clear flags
    bool clearError          = false,
    bool clearFilter         = false,
    bool clearGenreFilter    = false,
    bool clearLanguageFilter = false,
    bool clearMoodFilter     = false,
    bool clearYearFilter     = false,
    bool clearRatingFilter   = false,
  }) {
    return SearchState(
      query:              query              ?? this.query,
      contentTypeFilter:  clearFilter        ? null : (contentTypeFilter  ?? this.contentTypeFilter),
      genreFilter:        clearGenreFilter   ? null : (genreFilter        ?? this.genreFilter),
      languageFilter:     clearLanguageFilter? null : (languageFilter     ?? this.languageFilter),
      moodFilter:         clearMoodFilter    ? null : (moodFilter         ?? this.moodFilter),
      yearFrom:           clearYearFilter    ? null : (yearFrom           ?? this.yearFrom),
      yearTo:             clearYearFilter    ? null : (yearTo             ?? this.yearTo),
      minRating:          clearRatingFilter  ? null : (minRating          ?? this.minRating),
      maxRating:          clearRatingFilter  ? null : (maxRating          ?? this.maxRating),
      diversity:          diversity          ?? this.diversity,
      suggestions:        suggestions        ?? this.suggestions,
      results:            results            ?? this.results,
      isLoadingSuggestions: isLoadingSuggestions ?? this.isLoadingSuggestions,
      isLoadingResults:   isLoadingResults   ?? this.isLoadingResults,
      error:              clearError         ? null : (error              ?? this.error),
      hasSearched:        hasSearched        ?? this.hasSearched,
    );
  }

  /// True when any advanced filter is active
  bool get hasAdvancedFilter =>
      languageFilter != null ||
      moodFilter     != null ||
      yearFrom       != null ||
      yearTo         != null ||
      minRating      != null ||
      maxRating      != null;
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class SearchNotifier extends StateNotifier<SearchState> {
  final ApiService      _api;
  final FirebaseService _firebase;
  String? userId;

  SearchNotifier(this._api, this._firebase, this.userId)
      : super(const SearchState());

  // ── Init helpers ──────────────────────────────────────────────────────────

  void applyInitialFilter(String? filter) {
    if (filter != null && filter.isNotEmpty) {
      state = state.copyWith(contentTypeFilter: filter);
    }
  }

  // ── Autocomplete ─────────────────────────────────────────────────────────

  Future<void> onQueryChanged(String query) async {
    state = state.copyWith(query: query, isLoadingSuggestions: true);

    if (query.trim().isEmpty) {
      state = state.copyWith(suggestions: [], isLoadingSuggestions: false);
      return;
    }

    final suggestions = await _api.autocomplete(
      query,
      contentType: state.genreFilter ?? state.contentTypeFilter,
    );

    if (!mounted) return;
    state = state.copyWith(suggestions: suggestions, isLoadingSuggestions: false);
  }

  // ── Search ────────────────────────────────────────────────────────────────

  Future<void> search(String title) async {
    state = state.copyWith(
      query:            title,
      suggestions:      [],
      isLoadingResults: true,
      hasSearched:      true,
      clearError:       true,
    );

    final results = await _api.recommend(
      title:       title,
      contentType: state.contentTypeFilter,
      genreFilter: state.genreFilter,
      language:    state.languageFilter,
      mood:        state.moodFilter,
      yearFrom:    state.yearFrom,
      yearTo:      state.yearTo,
      minRating:   state.minRating,
      maxRating:   state.maxRating,
      diversity:   state.diversity,
      userId:      userId,
    );

    if (!mounted) return;

    if (results.isEmpty) {
      final label = state.genreFilter == 'anime'
          ? 'anime'
          : state.genreFilter == 'kdrama'
              ? 'K-Drama'
              : null;
      state = state.copyWith(
        isLoadingResults: false,
        results:          [],
        error: label != null
            ? 'No $label matches for "$title". Try a $label title directly.'
            : 'No results found. Try a different title or remove some filters.',
      );
      return;
    }

    final uid = userId;
    if (uid != null) {
      try {
        await _firebase.logUserActivity(
          userId:      uid,
          query:       title,
          contentType: state.genreFilter ?? state.contentTypeFilter,
          results:     results.map((r) => r.title).toList(),
        );
      } catch (e) {
        print('History log failed: $e');
      }
    }

    if (!mounted) return;
    state = state.copyWith(isLoadingResults: false, results: results);
  }

  // ── Filter setters ────────────────────────────────────────────────────────

  void setFilter(String? filter) {
    if (filter == state.contentTypeFilter) {
      state = state.copyWith(clearFilter: true, clearGenreFilter: true);
    } else {
      state = state.copyWith(contentTypeFilter: filter, clearGenreFilter: true);
    }
    _autoReSearch();
  }

  void setGenreFilter(String? genre) {
    if (genre == state.genreFilter) {
      state = state.copyWith(clearGenreFilter: true);
    } else {
      state = state.copyWith(genreFilter: genre, clearFilter: true);
    }
    _autoReSearch();
  }

  void setLanguageFilter(String? lang) {
    state = lang == state.languageFilter
        ? state.copyWith(clearLanguageFilter: true)
        : state.copyWith(languageFilter: lang);
    _autoReSearch();
  }

  void setMoodFilter(String? mood) {
    state = mood == state.moodFilter
        ? state.copyWith(clearMoodFilter: true)
        : state.copyWith(moodFilter: mood);
    _autoReSearch();
  }

  void setYearRange(int? from, int? to) {
    if (from == null && to == null) {
      state = state.copyWith(clearYearFilter: true);
    } else {
      state = state.copyWith(yearFrom: from, yearTo: to);
    }
    _autoReSearch();
  }

  void setRatingRange(double? min, double? max) {
    if (min == null && max == null) {
      state = state.copyWith(clearRatingFilter: true);
    } else {
      state = state.copyWith(minRating: min, maxRating: max);
    }
    _autoReSearch();
  }

  void setDiversity(double value) {
    state = state.copyWith(diversity: value);
    _autoReSearch();
  }

  void clearAllAdvancedFilters() {
    state = state.copyWith(
      clearLanguageFilter: true,
      clearMoodFilter:     true,
      clearYearFilter:     true,
      clearRatingFilter:   true,
    );
    _autoReSearch();
  }

  void clearSuggestions() => state = state.copyWith(suggestions: []);

  void _autoReSearch() {
    if (state.query.isNotEmpty && state.hasSearched) search(state.query);
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final searchProvider =
    StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  final api      = ref.read(apiServiceProvider);
  final firebase = ref.read(firebaseServiceProvider);
  final user     = ref.watch(authStateProvider).value;

  final notifier = SearchNotifier(api, firebase, user?.uid);
  ref.listen(authStateProvider, (_, next) {
    notifier.userId = next.value?.uid;
  });
  return notifier;
});

// ─── History ──────────────────────────────────────────────────────────────────

final historyProvider =
    StreamProvider.family<List<SearchHistoryItem>, String>((ref, uid) {
  return ref.watch(firebaseServiceProvider).getUserHistory(uid);
});

// ─── Saved Titles ─────────────────────────────────────────────────────────────

final savedTitlesProvider =
    StateNotifierProvider<SavedTitlesNotifier, Set<String>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return SavedTitlesNotifier(null, null, {});

  final appUserAsync = ref.watch(currentAppUserProvider);
  final savedSet     = appUserAsync.value?.savedTitles.toSet() ?? {};
  return SavedTitlesNotifier(ref.read(firebaseServiceProvider), user.uid, savedSet);
});

class SavedTitlesNotifier extends StateNotifier<Set<String>> {
  final FirebaseService? _firebase;
  final String? _uid;

  SavedTitlesNotifier(this._firebase, this._uid, Set<String> initial)
      : super(initial);

  Future<void> toggle(String title) async {
    if (_firebase == null || _uid == null) return;
    if (state.contains(title)) {
      state = {...state}..remove(title);
      await _firebase?.unsaveTitle(_uid!, title);
    } else {
      state = {...state, title};
      await _firebase?.saveTitle(_uid!, title);
    }
  }

  bool isSaved(String title) => state.contains(title);
}
