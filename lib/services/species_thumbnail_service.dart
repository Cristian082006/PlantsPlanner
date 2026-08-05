import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/species_thumbnails.dart';

/// Looks up a representative photo for a plant species by scientific name.
/// Species in the local care database use a curated Commons photo
/// (`kSpeciesThumbnails`); anything else falls back to Wikipedia's public
/// page-summary API, so arbitrary Pl@ntNet results still get a best-effort
/// photo.
class SpeciesThumbnailService {
  SpeciesThumbnailService._();
  static final SpeciesThumbnailService instance = SpeciesThumbnailService._();

  final Map<String, String?> _cache = {};

  Future<String?> getThumbnailUrl(String scientificName) async {
    final key = scientificName.trim();
    if (key.isEmpty) return null;

    final curated = kSpeciesThumbnails[key.toLowerCase()];
    if (curated != null) return curated;

    if (_cache.containsKey(key)) return _cache[key];

    // Try the name as-is, then the bare binomial (dropping "var.", "subsp.",
    // "f.", "cv." qualifiers the local model sometimes returns), then fall
    // back to Wikipedia's search API to resolve synonyms/redirects.
    final binomial = _binomialOf(key);
    final candidates = <String>{key, if (binomial != key) binomial};

    for (final candidate in candidates) {
      final url = await _summaryThumbnail(candidate);
      if (url != null) {
        _cache[key] = url;
        return url;
      }
    }

    final resolvedTitle = await _searchTitle(binomial);
    if (resolvedTitle != null) {
      final url = await _summaryThumbnail(resolvedTitle);
      if (url != null) {
        _cache[key] = url;
        return url;
      }
    }

    _cache[key] = null;
    return null;
  }

  String _binomialOf(String name) {
    final parts = name.split(RegExp(r'\s+'));
    return parts.length >= 2 ? '${parts[0]} ${parts[1]}' : name;
  }

  Future<String?> _summaryThumbnail(String title) async {
    try {
      final uri = Uri.https('en.wikipedia.org', '/api/rest_v1/page/summary/$title');
      final response = await http.get(uri).timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) return null;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final thumbnail = body['thumbnail'] as Map<String, dynamic>?;
      return thumbnail?['source'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _searchTitle(String query) async {
    try {
      final uri = Uri.https('en.wikipedia.org', '/w/api.php', {
        'action': 'opensearch',
        'search': query,
        'limit': '1',
        'namespace': '0',
        'format': 'json',
      });
      final response = await http.get(uri).timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) return null;
      final body = jsonDecode(response.body) as List<dynamic>;
      final titles = body.length > 1 ? body[1] as List<dynamic> : const [];
      return titles.isNotEmpty ? titles.first as String : null;
    } catch (_) {
      return null;
    }
  }
}
