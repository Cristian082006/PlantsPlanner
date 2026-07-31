import 'dart:io';
import 'package:flutter/material.dart';
import '../data/care_info.dart';
import '../db/database_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import 'plant_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  List<PlantRow> _plants = [];
  List<ReminderWithPlant> _due = [];

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    final plants = await DatabaseService.instance.getPlants();
    final due = await DatabaseService.instance.getDueReminders();
    if (!mounted) return;
    setState(() {
      _plants = plants;
      _due = due;
    });
  }

  Future<void> _onMarkDone(ReminderWithPlant item) async {
    await NotificationService.instance.markReminderDoneAndReschedule(item.reminder, item.plantCommonName);
    await refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: refresh,
          color: AppColors.accent,
          backgroundColor: AppColors.surface,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 10, 20, 4),
                child: Text('Plantele mele', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 26, color: AppColors.text)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_due.isNotEmpty) ...[
                      const _SectionLabel('De făcut acum', color: AppColors.accent300),
                      const SizedBox(height: 8),
                      for (final item in _due) ...[
                        _DueCard(item: item, onMarkDone: () => _onMarkDone(item)),
                        const SizedBox(height: 10),
                      ],
                      const SizedBox(height: 14),
                    ],
                    const _SectionLabel('Plantele tale', color: AppColors.neutral500),
                    const SizedBox(height: 8),
                    if (_plants.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Center(
                          child: Column(
                            children: [
                              Text(
                                'Nu ai adăugat încă nicio plantă.',
                                style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.text),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Mergi la tab-ul "Identifică" ca să scanezi prima ta plantă.',
                                style: TextStyle(color: AppColors.neutral400, fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      for (final plant in _plants) ...[
                        _PlantCard(
                          plant: plant,
                          onOpen: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => PlantDetailScreen(plantId: plant.id)),
                            );
                            refresh();
                          },
                        ),
                        const SizedBox(height: 10),
                      ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final Color color;

  const _SectionLabel(this.text, {required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(fontSize: 11, letterSpacing: 0.9, fontWeight: FontWeight.w500, color: color),
    );
  }
}

class _DueCard extends StatelessWidget {
  final ReminderWithPlant item;
  final VoidCallback onMarkDone;

  const _DueCard({required this.item, required this.onMarkDone});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      elevated: true,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(color: AppColors.accent800, shape: BoxShape.circle),
            child: const Icon(Icons.water_drop_outlined, color: AppColors.accent200, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.reminder.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.text)),
                Text(item.plantCommonName, style: const TextStyle(fontSize: 12, color: AppColors.neutral400)),
              ],
            ),
          ),
          OutlinedButton(onPressed: onMarkDone, child: const Text('Marchează făcut')),
        ],
      ),
    );
  }
}

class _PlantCard extends StatelessWidget {
  final PlantRow plant;
  final VoidCallback onOpen;

  const _PlantCard({required this.plant, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final meta = lightMeta(lightNeedFromDb(plant.light));
    return AppCard(
      onTap: onOpen,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: plant.photoPath != null
                ? Image.file(File(plant.photoPath!), width: 52, height: 52, fit: BoxFit.cover)
                : Container(width: 52, height: 52, color: AppColors.neutral800),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plant.commonName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text)),
                Text(
                  plant.scientificName,
                  style: const TextStyle(fontSize: 12, color: AppColors.neutral400, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 6,
                  children: [
                    AppTag(text: '${plant.wateringDays} zile', icon: Icons.water_drop_outlined),
                    AppTag(text: meta.tag, icon: meta.icon),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.neutral600, size: 16),
        ],
      ),
    );
  }
}
