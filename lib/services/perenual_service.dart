import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/perenual_config.dart';
import '../data/care_info.dart';
import '../db/database_service.dart';

/// Fills in care data for species not in our curated `kCareDb` (only ~60
/// hand-picked houseplants) by querying Perenual's plant database. Free tier
/// only covers species IDs 1–3000 of its 10,000+ catalog and 100
/// requests/day, so this is a best-effort third layer, not full coverage —
/// callers should keep falling back to the generic care info when this
/// returns null.
class PerenualService {
  PerenualService._();
  static final PerenualService instance = PerenualService._();

  final Map<String, CareInfo?> _memoryCache = {};

  Future<CareInfo?> fetchCareInfo(String scientificName) async {
    final key = scientificName.trim().toLowerCase();
    if (key.isEmpty) return null;
    if (_memoryCache.containsKey(key)) return _memoryCache[key];

    final cached = await DatabaseService.instance.getCachedSpeciesCare(key);
    if (cached != null) {
      final care = cached.isEmpty
          ? null
          : _careFromJson(jsonDecode(cached) as Map<String, dynamic>);
      _memoryCache[key] = care;
      return care;
    }

    CareInfo? care;
    try {
      final id = await _searchSpeciesId(key);
      if (id != null) {
        care = await _fetchDetails(id, key);
      }
    } catch (_) {
      care = null;
    }

    // Cache both hits and misses (empty string = confirmed miss) so we don't
    // burn quota re-asking about the same unsupported/unknown species.
    await DatabaseService.instance.setCachedSpeciesCare(
      key,
      care == null ? '' : jsonEncode(_careToJson(care)),
    );
    _memoryCache[key] = care;
    return care;
  }

  Future<int?> _searchSpeciesId(String scientificName) async {
    final uri = Uri.https('perenual.com', '/api/v2/species-list', {
      'key': perenualApiKey,
      'q': scientificName,
    });
    final response = await http.get(uri).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) return null;
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final results = body['data'] as List<dynamic>? ?? [];
    if (results.isEmpty) return null;
    return (results.first as Map<String, dynamic>)['id'] as int?;
  }

  Future<CareInfo?> _fetchDetails(int id, String scientificName) async {
    final uri = Uri.https('perenual.com', '/api/v2/species/details/$id', {
      'key': perenualApiKey,
    });
    final response = await http.get(uri).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) return null;

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final commonName = body['common_name'] as String? ?? scientificName;
    final sunlight = (body['sunlight'] as List<dynamic>? ?? []).cast<String>();
    final wateringLabel = body['watering'] as String?;
    final benchmark =
        body['watering_general_benchmark'] as Map<String, dynamic>?;
    final poisonousToPets = body['poisonous_to_pets'] == true;
    final description = body['description'] as String?;

    return CareInfo(
      commonNameRo:
          '$commonName (${scientificName[0].toUpperCase()}${scientificName.substring(1)})',
      wateringDays: _wateringDaysFrom(wateringLabel, benchmark),
      light: _lightNeedFrom(sunlight),
      misting: false,
      toxicityLevel: poisonousToPets
          ? ToxicityLevel.moderate
          : ToxicityLevel.none,
      tips: [
        if (description != null && description.isNotEmpty)
          description.length > 220
              ? '${description.substring(0, 220)}...'
              : description,
        'Date preluate automat (Perenual) — verifică și ajustează după cum reacționează planta ta.',
      ],
    );
  }

  int _wateringDaysFrom(String? label, Map<String, dynamic>? benchmark) {
    final value = benchmark?['value'] as String?;
    if (value != null) {
      final numbers = RegExp(
        r'\d+',
      ).allMatches(value).map((m) => int.parse(m.group(0)!)).toList();
      if (numbers.isNotEmpty) {
        return (numbers.reduce((a, b) => a + b) / numbers.length).round();
      }
    }
    switch (label) {
      case 'Frequent':
        return 4;
      case 'Average':
        return 7;
      case 'Minimum':
        return 18;
      default:
        return 7;
    }
  }

  LightNeed _lightNeedFrom(List<String> sunlight) {
    final joined = sunlight.join(' ').toLowerCase();
    if (joined.contains('full shade')) return LightNeed.shade;
    if (joined.contains('full sun')) return LightNeed.directLight;
    if (joined.contains('part')) return LightNeed.strongIndirect;
    if (joined.contains('shade')) return LightNeed.weakIndirect;
    return LightNeed.strongIndirect;
  }

  Map<String, dynamic> _careToJson(CareInfo care) => {
    'commonNameRo': care.commonNameRo,
    'wateringDays': care.wateringDays,
    'light': care.light.name,
    'misting': care.misting,
    'toxicityLevel': care.toxicityLevel.name,
    'tips': care.tips,
  };

  CareInfo _careFromJson(Map<String, dynamic> json) => CareInfo(
    commonNameRo: json['commonNameRo'] as String,
    wateringDays: json['wateringDays'] as int,
    light: LightNeed.values.byName(json['light'] as String),
    misting: json['misting'] as bool,
    toxicityLevel: ToxicityLevel.values.byName(json['toxicityLevel'] as String),
    tips: (json['tips'] as List<dynamic>).cast<String>(),
  );
}
