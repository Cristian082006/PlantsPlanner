class PlantPrediction {
  final String scientificName;
  final double confidence; // 0..1, aproximativ (model cuantizat uint8)
  // Doar Pl@ntNet le furnizează; modelul local (offline) le lasă null. Sunt
  // folosite ca fallback secundar pentru date de îngrijire (după familie),
  // pentru specii care nu sunt curatoriate exact.
  final String? family;
  final String? genus;

  const PlantPrediction({
    required this.scientificName,
    required this.confidence,
    this.family,
    this.genus,
  });
}
