import 'package:shared_preferences/shared_preferences.dart';

/// Tracks whether the first-launch tutorial has been shown, so it only
/// appears once — the settings screen offers a way to replay it manually.
class OnboardingService {
  OnboardingService._();
  static final OnboardingService instance = OnboardingService._();

  static const _seenKey = 'onboarding_seen';

  Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_seenKey) ?? false;
  }

  Future<void> markOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenKey, true);
  }
}
