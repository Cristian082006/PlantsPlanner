import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class WeatherReading {
  final double tempC;
  final int? weatherCode;

  const WeatherReading({required this.tempC, required this.weatherCode});
}

/// Maps an Open-Meteo/WMO weather code — plus the current time of day — to a
/// representative Material icon. Only the "clear/mostly clear" codes swap
/// between a sun and a moon; cloud/rain/snow read the same day or night.
/// https://open-meteo.com/en/docs (WMO Weather interpretation codes)
IconData weatherIconForCode(int? code, {DateTime? now}) {
  final hour = (now ?? DateTime.now()).hour;
  final isNight = hour < 6 || hour >= 20;

  if (code == null) return Icons.thermostat_outlined;
  if (code == 0)
    return isNight ? Icons.nightlight_round : Icons.wb_sunny_outlined;
  if (code <= 2)
    return isNight ? Icons.nights_stay_outlined : Icons.wb_cloudy_outlined;
  if (code == 3) return Icons.cloud_outlined;
  if (code == 45 || code == 48) return Icons.foggy;
  if (code >= 51 && code <= 57) return Icons.grain;
  if ((code >= 61 && code <= 67) || (code >= 80 && code <= 82))
    return Icons.umbrella_outlined;
  if ((code >= 71 && code <= 77) || code == 85 || code == 86)
    return Icons.ac_unit;
  if (code >= 95) return Icons.thunderstorm_outlined;
  return Icons.thermostat_outlined;
}

/// Fetches the current outdoor temperature and weather condition near the
/// device via Open-Meteo (free, no API key). Location is only used to pick
/// the nearest weather point — never sent anywhere else. Result is cached in
/// memory for a few hours since watering adjustments don't need to be more
/// precise than that.
class WeatherService {
  WeatherService._();
  static final WeatherService instance = WeatherService._();

  WeatherReading? _cached;
  DateTime? _cachedAt;

  Future<WeatherReading?> getCurrentWeather() async {
    final cachedAt = _cachedAt;
    if (_cached != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < const Duration(hours: 3)) {
      return _cached;
    }

    final position = await _getPosition();
    if (position == null) return null;

    try {
      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=${position.latitude}&longitude=${position.longitude}&current=temperature_2m,weather_code',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final current = body['current'] as Map<String, dynamic>?;
      final temp = (current?['temperature_2m'] as num?)?.toDouble();
      final code = (current?['weather_code'] as num?)?.toInt();
      if (temp != null) {
        final reading = WeatherReading(tempC: temp, weatherCode: code);
        _cached = reading;
        _cachedAt = DateTime.now();
        return reading;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<double?> getOutdoorTemperatureC() async =>
      (await getCurrentWeather())?.tempC;

  Future<Position?> _getPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      ).timeout(const Duration(seconds: 10));
    } catch (_) {
      return null;
    }
  }
}
