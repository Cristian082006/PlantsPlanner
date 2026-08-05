import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/trefle_config.dart';
import '../data/care_info.dart';
import '../db/database_service.dart';

/// Second-line fallback for species not in `kCareDb` and not found on
/// Perenual either. Trefle's catalog is much larger (400,000+ species vs.
/// Perenual's ~10,000) but its data is purely botanical — no toxicity
/// info — so results always carry a caveat tip telling the user to verify
/// pet safety separately.
class TrefleService {
  TrefleService._();
  static final TrefleService instance = TrefleService._();

  static const _baseUrl = 'https://trefle.io/api/v1';

  final Map<String, CareInfo?> _memoryCache = {};

  Future<CareInfo?> fetchCareInfo(String scientificName) async {
    final key = scientificName.trim().toLowerCase();
    if (key.isEmpty) return null;
    if (_memoryCache.containsKey(key)) return _memoryCache[key];

    final cached = await DatabaseService.instance.getCachedTrefleCare(key);
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
    await DatabaseService.instance.setCachedTrefleCare(
      key,
      care == null ? '' : jsonEncode(_careToJson(care)),
    );
    _memoryCache[key] = care;
    return care;
  }

  Future<int?> _searchSpeciesId(String scientificName) async {
    final uri = Uri.parse('$_baseUrl/species/search').replace(
      queryParameters: {'token': trefleApiToken, 'q': scientificName},
    );
    final response = await http.get(uri).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) return null;
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final results = body['data'] as List<dynamic>? ?? [];
    if (results.isEmpty) return null;
    return (results.first as Map<String, dynamic>)['id'] as int?;
  }

  Future<CareInfo?> _fetchDetails(int id, String scientificName) async {
    final uri = Uri.parse(
      '$_baseUrl/species/$id',
    ).replace(queryParameters: {'token': trefleApiToken});
    final response = await http.get(uri).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) return null;

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) return null;

    // Growth data can sit either directly on the species record or nested
    // under `main_species`, depending on the endpoint/species — try both.
    final growth =
        (data['growth'] as Map<String, dynamic>?) ??
        ((data['main_species'] as Map<String, dynamic>?)?['growth']
            as Map<String, dynamic>?);
    final specifications = data['specifications'] as Map<String, dynamic>?;
    final toxicityText = specifications?['toxicity'] as String?;

    final commonName = data['common_name'] as String? ?? scientificName;
    final capitalized =
        '${scientificName[0].toUpperCase()}${scientificName.substring(1)}';

    return CareInfo(
      commonNameRo: '$commonName ($capitalized)',
      wateringDays: _wateringDaysFrom(growth),
      light: _lightNeedFrom(growth?['light'] as num?),
      misting: ((growth?['atmospheric_humidity'] as num?) ?? 0) >= 7,
      toxicityLevel: _toxicityLevelFrom(toxicityText),
      tips: [
        if (toxicityText == null)
          'Date preluate automat (Trefle) — sursa nu oferă informații de '
              'toxicitate; verifică separat dacă ai animale de companie.'
        else
          'Date preluate automat (Trefle) — verifică și ajustează după cum '
              'reacționează planta ta.',
        'Ajustează udarea și lumina în funcție de cum reacționează planta ta.',
      ],
    );
  }

  // Trefle's `toxicity` field is free text (when present at all — it's
  // sparsely populated in the free tier); derived the same cautious way as
  // the family defaults in care_info.dart: when unsure, pick the higher
  // level rather than risk under-warning a pet owner.
  ToxicityLevel _toxicityLevelFrom(String? text) {
    if (text == null) return ToxicityLevel.none;
    final lower = text.toLowerCase();
    if (lower.contains('non') || lower.contains('not toxic')) {
      return ToxicityLevel.none;
    }
    if (lower.contains('severe') || lower.contains('highly')) {
      return ToxicityLevel.severe;
    }
    if (lower.contains('moderate')) return ToxicityLevel.moderate;
    if (lower.contains('toxic')) return ToxicityLevel.moderate;
    return ToxicityLevel.none;
  }

  int _wateringDaysFrom(Map<String, dynamic>? growth) {
    if (growth == null) return 7;
    final droughtTolerant = growth['drought_tolerance'] == true;
    if (droughtTolerant) return 14;
    final minPrecipitation =
        (growth['minimum_precipitation'] as Map<String, dynamic>?)?['mm']
            as num?;
    if (minPrecipitation != null && minPrecipitation < 500) return 12;
    return 7;
  }

  LightNeed _lightNeedFrom(num? light) {
    if (light == null) return LightNeed.strongIndirect;
    if (light <= 2) return LightNeed.shade;
    if (light <= 5) return LightNeed.weakIndirect;
    if (light <= 8) return LightNeed.strongIndirect;
    return LightNeed.directLight;
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
    toxicityLevel: ToxicityLevel.values.byName(
      json['toxicityLevel'] as String,
    ),
    tips: (json['tips'] as List<dynamic>).cast<String>(),
  );
}
