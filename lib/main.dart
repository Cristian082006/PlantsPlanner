import 'package:flutter/material.dart';
import 'screens/camera_screen.dart';
import 'screens/diagnose_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'services/app_tab_controller.dart';
import 'services/local_plant_model_service.dart';
import 'services/notification_service.dart';
import 'services/photo_paths.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PhotoPaths.init();
  runApp(const PlantsPlannerApp());
}

class PlantsPlannerApp extends StatelessWidget {
  const PlantsPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plants Planner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const RootScreen(),
    );
  }
}

// Culori fixe de semnătură per tab, independente de tema zi/noapte — scopul
// e diferențiere vizuală imediată între secțiuni, nu integrare cu paletă.
const _kHomeTabColor = Color(0xff4caf6d);
const _kIdentifyTabColor = Color(0xff3b82f6);
const _kDiagnoseTabColor = Color(0xfff5a524);
const _kSettingsTabColor = Color(0xff8b5cf6);

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> with WidgetsBindingObserver {
  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NotificationService.instance.init();
    NotificationService.instance.requestPermissions();
    LocalPlantModelService.instance.load();
    AppTabController.instance.tabIndex.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppTabController.instance.tabIndex.removeListener(_onTabChanged);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    // AppColors reads the OS brightness directly, so a full rebuild here is
    // enough to repaint every screen with the new light/dark palette.
    setState(() {});
  }

  void _onTabChanged() {
    if (AppTabController.instance.tabIndex.value == 0) {
      _homeKey.currentState?.refresh();
    }
    setState(() {});
  }

  void _selectTab(int index) =>
      AppTabController.instance.tabIndex.value = index;

  @override
  Widget build(BuildContext context) {
    final tabIndex = AppTabController.instance.tabIndex.value;
    return Scaffold(
      body: IndexedStack(
        index: tabIndex,
        children: [
          HomeScreen(key: _homeKey),
          const CameraScreen(),
          const DiagnoseScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.bg,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                _TabButton(
                  icon: Icons.eco_outlined,
                  label: 'Plantele mele',
                  color: _kHomeTabColor,
                  selected: tabIndex == 0,
                  onTap: () => _selectTab(0),
                ),
                _TabButton(
                  icon: Icons.camera_alt_outlined,
                  label: 'Identifică',
                  color: _kIdentifyTabColor,
                  selected: tabIndex == 1,
                  onTap: () => _selectTab(1),
                ),
                _TabButton(
                  icon: Icons.health_and_safety_outlined,
                  label: 'Diagnoză',
                  color: _kDiagnoseTabColor,
                  selected: tabIndex == 2,
                  onTap: () => _selectTab(2),
                ),
                _TabButton(
                  icon: Icons.settings_outlined,
                  label: 'Setări',
                  color: _kSettingsTabColor,
                  selected: tabIndex == 3,
                  onTap: () => _selectTab(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tint = selected ? color : color.withValues(alpha: 0.45);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: selected
                      ? color.withValues(alpha: 0.16)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 22, color: tint),
              ),
              const SizedBox(height: 1),
              Text(label, style: TextStyle(fontSize: 11, color: tint)),
            ],
          ),
        ),
      ),
    );
  }
}
