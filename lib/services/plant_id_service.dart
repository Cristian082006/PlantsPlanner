import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/plantnet_config.dart';
import '../models/plant_prediction.dart';

const String _identifyEndpoint = 'https://my-api.plantnet.org/v2/identify/all';

class PlantIdService {
  PlantIdService._();
  static final PlantIdService instance = PlantIdService._();

  /// [files] and [organs] must be the same length. [organs] uses Pl@ntNet's
  /// organ vocabulary: 'leaf', 'flower', 'fruit', 'bark', or 'auto'.
  Future<List<PlantPrediction>> classifyImages(List<File> files, List<String> organs, {int topN = 3}) async {
    assert(files.length == organs.length);
    final uri = Uri.parse('$_identifyEndpoint?api-key=$plantNetApiKey');
    final request = http.MultipartRequest('POST', uri);
    for (var i = 0; i < files.length; i++) {
      request.files.add(await http.MultipartFile.fromPath('images', files[i].path));
      request.files.add(http.MultipartFile.fromString('organs', organs[i]));
    }

    final http.Response response;
    try {
      final streamed = await request.send();
      response = await http.Response.fromStream(streamed);
    } on SocketException {
      throw StateError('Nu există conexiune la internet. Identificarea are nevoie de internet.');
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw StateError('Cheia API Pl@ntNet lipsește sau este invalidă.');
    }
    if (response.statusCode == 429) {
      throw StateError('Limita zilnică de identificări Pl@ntNet a fost atinsă.');
    }
    if (response.statusCode != 200) {
      throw StateError('Identificarea a eșuat (cod ${response.statusCode}).');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final results = body['results'] as List<dynamic>? ?? [];
    if (results.isEmpty) {
      throw StateError('Nu s-a putut identifica planta din fotografii.');
    }

    return results.take(topN).map((raw) {
      final result = raw as Map<String, dynamic>;
      final species = result['species'] as Map<String, dynamic>;
      final scientificName =
          species['scientificNameWithoutAuthor'] as String? ?? species['scientificName'] as String;
      final score = (result['score'] as num).toDouble();
      return PlantPrediction(scientificName: scientificName, confidence: score);
    }).toList();
  }
}
