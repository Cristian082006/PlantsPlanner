import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:image/image.dart' as img;
import '../models/plant_prediction.dart';

const int _modelInputSize = 224;
const List<double> _mean = [0.485, 0.456, 0.406];
const List<double> _std = [0.229, 0.224, 0.225];

/// Runs the "quarrying-plant-id" ONNX model (BSD-3-Clause, 4066 plant taxa,
/// ~85% top-1 accuracy, https://github.com/quarrying/quarrying-plant-id) —
/// complements the Pl@ntNet API with a fully offline classifier that covers
/// far more houseplant genera than a custom-trained small dataset would.
class LocalPlantModelService {
  LocalPlantModelService._();
  static final LocalPlantModelService instance = LocalPlantModelService._();

  OrtSession? _session;
  List<String>? _speciesLatinNames;

  Future<void> load() async {
    if (_session != null) return;
    final ort = OnnxRuntime();
    _session = await ort.createSessionFromAsset('assets/model/quarrying_plantid_model.onnx');

    final labelJson = await rootBundle.loadString('assets/model/quarrying_plantid_label_map.json');
    final labelMap = jsonDecode(labelJson) as Map<String, dynamic>;
    final speciesTaxons = labelMap['species_taxons'] as Map<String, dynamic>;
    final count = speciesTaxons.length;
    _speciesLatinNames = List.generate(count, (i) {
      final entry = speciesTaxons[i.toString()] as Map<String, dynamic>;
      return entry['latin_name'] as String;
    });
  }

  Future<List<PlantPrediction>> classifyImageFile(File file, {int topN = 3}) async {
    await load();
    final session = _session;
    final speciesNames = _speciesLatinNames;
    if (session == null || speciesNames == null) {
      throw StateError('Modelul local nu a putut fi încărcat.');
    }

    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw StateError('Imaginea nu a putut fi decodată.');
    }

    // resize_image_short(224) then center_crop(224, 224), matching the
    // model's original preprocessing exactly.
    final shortSide = math.min(decoded.width, decoded.height);
    final scale = _modelInputSize / shortSide;
    final resized = img.copyResize(
      decoded,
      width: (decoded.width * scale).round(),
      height: (decoded.height * scale).round(),
      interpolation: img.Interpolation.linear,
    );
    final left = ((resized.width - _modelInputSize) / 2).round();
    final top = ((resized.height - _modelInputSize) / 2).round();
    final cropped = img.copyCrop(resized, x: left, y: top, width: _modelInputSize, height: _modelInputSize);

    // NCHW float32, ImageNet-normalized.
    final input = Float32List(3 * _modelInputSize * _modelInputSize);
    var i = 0;
    for (var c = 0; c < 3; c++) {
      for (var y = 0; y < _modelInputSize; y++) {
        for (var x = 0; x < _modelInputSize; x++) {
          final pixel = cropped.getPixel(x, y);
          final channelValue = c == 0 ? pixel.r : (c == 1 ? pixel.g : pixel.b);
          input[i++] = (channelValue / 255.0 - _mean[c]) / _std[c];
        }
      }
    }

    final inputTensor = await OrtValue.fromList(input, [1, 3, _modelInputSize, _modelInputSize]);
    final outputs = await session.run({session.inputNames.first: inputTensor});
    final rawLogits = await outputs[session.outputNames.first]!.asFlattenedList();
    final logits = rawLogits.map((e) => (e as num).toDouble()).toList();

    final probs = _softmax(logits);
    final indexed = List.generate(probs.length, (idx) => MapEntry(idx, probs[idx]));
    indexed.sort((a, b) => b.value.compareTo(a.value));

    return indexed
        .take(topN)
        .map((e) => PlantPrediction(scientificName: speciesNames[e.key], confidence: e.value))
        .toList();
  }

  List<double> _softmax(List<double> logits) {
    final maxVal = logits.reduce(math.max);
    final exps = logits.map((v) => math.exp(v - maxVal)).toList();
    final sum = exps.reduce((a, b) => a + b);
    return exps.map((v) => v / sum).toList();
  }
}
