class PlantPrediction {
  final String scientificName;
  final double confidence; // 0..1, aproximativ (model cuantizat uint8)

  const PlantPrediction({required this.scientificName, required this.confidence});
}
