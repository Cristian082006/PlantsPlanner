import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../data/plant_labels.dart';
import '../models/plant_prediction.dart';

const int _modelInputSize = 224;
final int _backgroundLabelIndex = kPlantLabels.length - 1;

class PlantModelService {
  PlantModelService._();
  static final PlantModelService instance = PlantModelService._();

  Interpreter? _interpreter;
  IsolateInterpreter? _isolateInterpreter;

  Future<void> load() async {
    if (_interpreter != null) return;
    final interpreter = await Interpreter.fromAsset('assets/model/plants_v1.tflite');
    _interpreter = interpreter;
    _isolateInterpreter = await IsolateInterpreter.create(address: interpreter.address);
  }

  bool get isLoaded => _isolateInterpreter != null;

  Future<List<PlantPrediction>> classifyImageFile(File file, {int topN = 3}) async {
    final isolateInterpreter = _isolateInterpreter;
    if (isolateInterpreter == null) {
      throw StateError('Modelul nu a fost încărcat încă.');
    }

    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw StateError('Imaginea nu a putut fi decodată.');
    }

    final resized = img.copyResize(
      decoded,
      width: _modelInputSize,
      height: _modelInputSize,
      interpolation: img.Interpolation.linear,
    );

    final input = List.generate(
      1,
      (_) => List.generate(
        _modelInputSize,
        (y) => List.generate(_modelInputSize, (x) {
          final pixel = resized.getPixel(x, y);
          return [pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()];
        }),
      ),
    );

    final output = List.generate(1, (_) => List.filled(kPlantLabels.length, 0));

    await isolateInterpreter.run(input, output);

    final scores = output[0];
    final indexed = <MapEntry<int, int>>[];
    for (var i = 0; i < scores.length; i++) {
      if (i == _backgroundLabelIndex) continue;
      indexed.add(MapEntry(i, scores[i]));
    }
    indexed.sort((a, b) => b.value.compareTo(a.value));

    return indexed
        .take(topN)
        .map((e) => PlantPrediction(scientificName: kPlantLabels[e.key], confidence: e.value / 255.0))
        .toList();
  }

  void dispose() {
    _isolateInterpreter?.close();
    _interpreter?.close();
    _isolateInterpreter = null;
    _interpreter = null;
  }
}
