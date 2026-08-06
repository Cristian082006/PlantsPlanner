import 'package:flutter/foundation.dart';

/// Starts/stops the coach-mark tutorial overlay from anywhere (first-launch
/// check in [RootScreen], or the "replay tutorial" tap in Settings) without
/// those callers needing a reference to the overlay widget itself.
class OnboardingCoachController {
  OnboardingCoachController._();
  static final OnboardingCoachController instance =
      OnboardingCoachController._();

  final ValueNotifier<bool> active = ValueNotifier(false);

  void start() => active.value = true;

  void stop() => active.value = false;
}
