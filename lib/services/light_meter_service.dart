import 'dart:math' as math;
import '../data/care_info.dart';

/// Estimates ambient illuminance (lux) from the camera sensor's own
/// auto-exposure metadata — the same "sunny 16"-style relationship real
/// light meters use: brighter scenes make the sensor choose a smaller
/// aperture / faster shutter / lower ISO to keep exposure balanced, so the
/// exposure triangle itself encodes roughly how much light is present.
/// This is an approximation (not a calibrated lux meter), but it's grounded
/// in the phone's real exposure decisions rather than a raw pixel-brightness
/// guess, which auto-exposure would otherwise normalize away.
double? estimateLux({
  required double? apertureFStop,
  required int? exposureTimeNanos,
  required double? iso,
}) {
  if (apertureFStop == null || exposureTimeNanos == null || iso == null) return null;
  if (exposureTimeNanos <= 0 || iso <= 0 || apertureFStop <= 0) return null;

  final exposureSeconds = exposureTimeNanos / 1e9;
  final ev = math.log(apertureFStop * apertureFStop / exposureSeconds) / math.ln2;
  final ev100 = ev - (math.log(iso / 100) / math.ln2);
  return 2.5 * math.pow(2, ev100).toDouble();
}

/// Rough horticultural lux bands (low/medium/bright indirect/direct sun) —
/// commonly cited ranges, not exact species science.
LightNeed lightNeedFromLux(double lux) {
  if (lux < 250) return LightNeed.shade;
  if (lux < 1000) return LightNeed.weakIndirect;
  if (lux < 10000) return LightNeed.strongIndirect;
  return LightNeed.directLight;
}

String luxLabelRo(double lux) {
  if (lux < 50) return 'Foarte întunecat';
  if (lux < 250) return 'Umbră';
  if (lux < 1000) return 'Lumină indirectă slabă';
  if (lux < 10000) return 'Lumină indirectă puternică';
  return 'Soare direct';
}
