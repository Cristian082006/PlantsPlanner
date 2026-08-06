import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/onboarding_coach_controller.dart';
import '../services/onboarding_keys.dart';
import '../theme/app_theme.dart';
import '../widgets/plants_backdrop.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  PackageInfo? _info;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _info = info);
    });
  }

  @override
  Widget build(BuildContext context) {
    final info = _info;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PlantsBackdrop(
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
                child: Text(
                  'Setări',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 26,
                    color: AppColors.text,
                  ),
                ),
              ),
              Padding(
                key: OnboardingKeys.settingsReplay,
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                child: AppCard(
                  onTap: () => OnboardingCoachController.instance.start(),
                  child: Row(
                    children: [
                      Icon(Icons.help_outline, color: AppColors.accent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Vezi din nou tutorialul',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: AppColors.neutral400,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: AppCard(
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.accent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Versiune aplicație',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.text,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              info == null
                                  ? '...'
                                  : '${info.version} (${info.buildNumber})',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.neutral400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
