import 'dart:convert';
import 'package:http/http.dart' as http;

/// Looks up a representative photo for a plant species by scientific name,
/// using Wikipedia's public page-summary API. Works for any species name,
/// not just ones in the local care database.
class SpeciesThumbnailService {
  SpeciesThumbnailService._();
  static final SpeciesThumbnailService instance = SpeciesThumbnailService._();

  final Map<String, String?> _cache = {};

  Future<String?> getThumbnailUrl(String scientificName) async {
    final key = scientificName.trim();
    if (key.isEmpty) return null;
    if (_cache.containsKey(key)) return _cache[key];

    try {
      final uri = Uri.https('en.wikipedia.org', '/api/rest_v1/page/summary/$key');
      final response = await http.get(uri).timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) {
        _cache[key] = null;
        return null;
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final thumbnail = body['thumbnail'] as Map<String, dynamic>?;
      final url = thumbnail?['source'] as String?;
      _cache[key] = url;
      return url;
    } catch (_) {
      _cache[key] = null;
      return null;
    }
  }
}
