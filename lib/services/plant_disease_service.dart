import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/plantnet_config.dart';
import '../models/disease_prediction.dart';

const String _diagnoseEndpoint = 'https://my-api.plantnet.org/v2/diseases/identify';

/// Diagnoses diseases and pests from a leaf/plant photo using Pl@ntNet's
/// diseases endpoint. Shares the same API key and daily quota as species
/// identification (`PlantIdService`) — no separate account needed.
class PlantDiseaseService {
  PlantDiseaseService._();
  static final PlantDiseaseService instance = PlantDiseaseService._();

  Future<List<DiseasePrediction>> diagnoseImage(File file, {String organ = 'leaf', int topN = 3}) async {
    final uri = Uri.parse('$_diagnoseEndpoint?api-key=$plantNetApiKey');
    final request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('images', file.path));
    request.fields['organs'] = organ;

    final http.Response response;
    try {
      final streamed = await request.send();
      response = await http.Response.fromStream(streamed);
    } on SocketException {
      throw StateError('Nu există conexiune la internet. Diagnoza are nevoie de internet.');
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw StateError('Cheia API Pl@ntNet lipsește sau este invalidă.');
    }
    if (response.statusCode == 429) {
      throw StateError('Limita zilnică de identificări Pl@ntNet a fost atinsă.');
    }
    if (response.statusCode != 200) {
      throw StateError('Diagnoza a eșuat (cod ${response.statusCode}).');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final results = body['results'] as List<dynamic>? ?? [];
    if (results.isEmpty) {
      throw StateError('Nu s-a putut diagnostica planta din fotografie.');
    }

    return results.take(topN).map((raw) {
      final result = raw as Map<String, dynamic>;
      return DiseasePrediction(
        code: result['name'] as String,
        description: result['description'] as String? ?? result['name'] as String,
        confidence: (result['score'] as num).toDouble(),
      );
    }).toList();
  }
}
