import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Recommendation Model ─────────────────────────────────────────────────────

class Recommendation extends Equatable {
  final String title;
  final String type;
  final double score;
  final String? posterUrl;
  // ── v2 new fields ──
  final String? language;
  final String? genres;
  final int? year;
  final double? rating; // TMDB vote_average 0–10

  const Recommendation({
    required this.title,
    required this.type,
    required this.score,
    this.posterUrl,
    this.language,
    this.genres,
    this.year,
    this.rating,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      title:    json['title']    as String,
      type:     json['type']     as String? ?? 'movie',
      score:    (json['score']   as num).toDouble(),
      posterUrl: json['poster_url'] as String?,
      language: json['language'] as String?,
      genres:   json['genres']   as String?,
      year:     json['year']     as int?,
      rating:   json['rating'] != null
                  ? (json['rating'] as num).toDouble()
                  : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'title':    title,
    'type':     type,
    'score':    score,
    if (posterUrl != null) 'poster_url': posterUrl,
    if (language  != null) 'language':   language,
    if (genres    != null) 'genres':     genres,
    if (year      != null) 'year':       year,
    if (rating    != null) 'rating':     rating,
  };

  int get scorePercent => (score * 100).clamp(0, 100).round();

  /// e.g. "2022 · ★ 7.4"
  String get metaLine {
    final parts = <String>[];
    if (year != null) parts.add('$year');
    if (rating != null && rating! > 0) parts.add('★ ${rating!.toStringAsFixed(1)}');
    return parts.join(' · ');
  }

  @override
  List<Object?> get props => [title, type, score];
}

// ─── Autocomplete Result Model ────────────────────────────────────────────────

class AutocompleteResult extends Equatable {
  final String title;
  final int score;
  final String? type; // v2: api now returns type

  const AutocompleteResult({
    required this.title,
    required this.score,
    this.type,
  });

  factory AutocompleteResult.fromJson(Map<String, dynamic> json) {
    return AutocompleteResult(
      title: json['title'] as String,
      score: (json['score'] as num).toInt(),
      type:  json['type']  as String?,
    );
  }

  @override
  List<Object?> get props => [title, score];
}

// ─── Search History Item ──────────────────────────────────────────────────────

class SearchHistoryItem extends Equatable {
  final String id;
  final String query;
  final String? contentType;
  final List<String> results;
  final DateTime timestamp;

  const SearchHistoryItem({
    required this.id,
    required this.query,
    this.contentType,
    required this.results,
    required this.timestamp,
  });

  factory SearchHistoryItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SearchHistoryItem(
      id:          doc.id,
      query:       data['query']        as String? ?? '',
      contentType: data['content_type'] as String?,
      results:     List<String>.from(data['results'] as List? ?? []),
      timestamp:   (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'query':        query,
    'content_type': contentType,
    'results':      results,
    'timestamp':    Timestamp.fromDate(timestamp),
  };

  @override
  List<Object?> get props => [id, query, contentType, timestamp];
}

// ─── App User Model ───────────────────────────────────────────────────────────

class AppUser extends Equatable {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
  final DateTime createdAt;
  final List<String> savedTitles;
  final String? preferredType;

  const AppUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
    required this.createdAt,
    required this.savedTitles,
    this.preferredType,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid:           doc.id,
      email:         data['email']          as String? ?? '',
      displayName:   data['display_name']   as String?,
      photoURL:      data['photo_url']       as String?,
      createdAt:     (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      savedTitles:   List<String>.from(data['saved_titles'] as List? ?? []),
      preferredType: data['preferred_type'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'email':          email,
    'display_name':   displayName,
    'photo_url':      photoURL,
    'created_at':     Timestamp.fromDate(createdAt),
    'saved_titles':   savedTitles,
    'preferred_type': preferredType,
  };

  AppUser copyWith({
    String? displayName,
    String? photoURL,
    List<String>? savedTitles,
    String? preferredType,
  }) {
    return AppUser(
      uid:           uid,
      email:         email,
      displayName:   displayName   ?? this.displayName,
      photoURL:      photoURL      ?? this.photoURL,
      createdAt:     createdAt,
      savedTitles:   savedTitles   ?? this.savedTitles,
      preferredType: preferredType ?? this.preferredType,
    );
  }

  @override
  List<Object?> get props => [uid, email, displayName, savedTitles];
}
