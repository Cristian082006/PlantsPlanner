import 'package:flutter/material.dart';
import 'screens/camera_screen.dart';
import 'screens/home_screen.dart';
import 'services/local_plant_model_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const PlantsPlannerApp());
}

class PlantsPlannerApp extends StatelessWidget {
  const PlantsPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plants Planner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const RootScreen(),
    );
  }
}

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _tabIndex = 0;
  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();

  @override
  void initState() {
    super.initState();
    NotificationService.instance.init();
    NotificationService.instance.requestPermissions();
    LocalPlantModelService.instance.load();
  }

  void _selectTab(int index) {
    setState(() => _tabIndex = index);
    if (index == 0) _homeKey.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tabIndex,
        children: [
          HomeScreen(key: _homeKey),
          const CameraScreen(),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
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
                  selected: _tabIndex == 0,
                  onTap: () => _selectTab(0),
                ),
                _TabButton(
                  icon: Icons.camera_alt_outlined,
                  label: 'Identifică',
                  selected: _tabIndex == 1,
                  onTap: () => _selectTab(1),
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
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.accent : AppColors.neutral400;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(height: 3),
              Text(label, style: TextStyle(fontSize: 11, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
