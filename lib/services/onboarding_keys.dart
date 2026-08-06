import 'package:flutter/widgets.dart';

/// Stable [GlobalKey]s attached to the real buttons the coach-mark tutorial
/// highlights, so it can spotlight the actual on-screen widget instead of a
/// mocked-up illustration. Screens stay alive under the root [IndexedStack],
/// so these keys remain valid for the whole app session once first built.
class OnboardingKeys {
  OnboardingKeys._();

  static final tabPlants = GlobalKey(debugLabel: 'onboarding_tab_plants');
  static final tabIdentify = GlobalKey(debugLabel: 'onboarding_tab_identify');
  static final tabDiagnose = GlobalKey(debugLabel: 'onboarding_tab_diagnose');
  static final tabSettings = GlobalKey(debugLabel: 'onboarding_tab_settings');

  static final roomChipsRow = GlobalKey(debugLabel: 'onboarding_room_chips');
  static final cameraShutter = GlobalKey(
    debugLabel: 'onboarding_camera_shutter',
  );
  static final diagnoseCapture = GlobalKey(
    debugLabel: 'onboarding_diagnose_capture',
  );
  static final settingsReplay = GlobalKey(
    debugLabel: 'onboarding_settings_replay',
  );
}
