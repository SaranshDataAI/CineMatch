import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ApiService {
  final String _baseUrl = "https://ai-recommender-api-v2.onrender.com";

  static const String _tmdbKey = '2addbc2bf90cc62db27bf11d93d670f6';
  static const String _tmdbBase = 'https://api.themoviedb.org/3';
  static const String _tmdbImg = 'https://image.tmdb.org/t/p/w185';

  final http.Client _client = http.Client();

  // ─── Retry wrapper ─────────────────────────────────────────────────────────
  Future<http.Response?> _getWithRetry(
    Uri uri, {
    int retries = 2,
    Duration timeout = const Duration(seconds: 40),
  }) async {
    for (int attempt = 0; attempt <= retries; attempt++) {
      try {
        return await _client.get(uri).timeout(timeout);
      } catch (_) {
        if (attempt == retries) return null;
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    return null;
  }

  // ─── TMDB poster ───────────────────────────────────────────────────────────
  Future<String?> _fetchPosterUrl(String title, String type) async {
    if (_tmdbKey == 'YOUR_TMDB_API_KEY') return null;
    try {
      final uri = Uri.parse('$_tmdbBase/search/multi').replace(
        queryParameters: {
          'api_key': _tmdbKey,
          'query': title,
          'include_adult': 'false',
        },
      );
      final response =
          await _client.get(uri).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final results = (jsonDecode(response.body)['results'] as List?) ?? [];
        for (final r in results) {
          final path = r['poster_path'] as String?;
          if (path != null && path.isNotEmpty) return '$_tmdbImg$path';
        }
      }
    } catch (_) {}
    return null;
  }

  // ─── RECOMMEND (v2) ────────────────────────────────────────────────────────
  Future<List<Recommendation>> recommend({
    required String title,
    // Content-type / genre filters (mutually exclusive — pass one or the other)
    String? contentType, // movie | tv | bollywood | kollywood | tollywood …
    String?
        genreFilter, // anime | kdrama  (legacy alias → sent as content_type)
    // New v2 filters
    String? language, // ISO-639-1: hi | en | ko | ja | ta | te | ml …
    String? mood, // happy | sad | thrilling | scary | romantic …
    int? yearFrom,
    int? yearTo,
    double? minRating,
    double? maxRating,
    double diversity = 0.15, // 0 = pure relevance, 1 = pure variety
    int topK = 10,
    String? userId,
  }) async {
    try {
      final params = <String, String>{'title': title};

      // content_type: genreFilter wins if both somehow passed
      final ct = genreFilter ?? contentType;
      if (ct != null) params['content_type'] = ct;

      if (language != null) params['language'] = language;
      if (mood != null) params['mood'] = mood;
      if (yearFrom != null) params['year_from'] = yearFrom.toString();
      if (yearTo != null) params['year_to'] = yearTo.toString();
      if (minRating != null) params['min_rating'] = minRating.toString();
      if (maxRating != null) params['max_rating'] = maxRating.toString();
      params['diversity'] = diversity.toString();
      params['top_k'] = topK.toString();
      if (userId != null) params['user_id'] = userId;

      final uri =
          Uri.parse("$_baseUrl/recommend").replace(queryParameters: params);
      final response =
          await _getWithRetry(uri, timeout: const Duration(seconds: 45));

      if (response == null || response.statusCode != 200) {
        print("API ERROR: ${response?.statusCode}");
        return [];
      }

      final data = jsonDecode(response.body);
      List<Recommendation> recs = ((data['results'] as List?) ?? [])
          .map((e) => Recommendation.fromJson(e as Map<String, dynamic>))
          .toList();

      if (recs.isEmpty) return [];

      // Fetch TMDB posters concurrently
      final posters = await Future.wait(
        recs.map((r) => _fetchPosterUrl(r.title, r.type)),
      );

      return List.generate(
          recs.length,
          (i) => Recommendation(
                title: recs[i].title,
                type: recs[i].type,
                score: recs[i].score,
                posterUrl: posters[i],
                language: recs[i].language,
                genres: recs[i].genres,
                year: recs[i].year,
                rating: recs[i].rating,
              ));
    } catch (e) {
      print("API EXCEPTION: $e");
      return [];
    }
  }

  // ─── AUTOCOMPLETE ──────────────────────────────────────────────────────────
  Future<List<AutocompleteResult>> autocomplete(
    String query, {
    String? contentType,
  }) async {
    try {
      final params = <String, String>{'query': query};
      if (contentType != null) params['content_type'] = contentType;

      final uri =
          Uri.parse("$_baseUrl/autocomplete").replace(queryParameters: params);
      final response =
          await _getWithRetry(uri, timeout: const Duration(seconds: 25));

      if (response?.statusCode == 200) {
        final data = jsonDecode(response!.body);
        return ((data['results'] as List?) ?? [])
            .map((e) => AutocompleteResult.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print("AUTOCOMPLETE EXCEPTION: $e");
      return [];
    }
  }
}
