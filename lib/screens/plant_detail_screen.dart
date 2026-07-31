import 'dart:io';
import 'package:flutter/material.dart';
import '../data/care_info.dart';
import '../db/database_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

const _kRoMonths = [
  'ian',
  'feb',
  'mar',
  'apr',
  'mai',
  'iun',
  'iul',
  'aug',
  'sep',
  'oct',
  'nov',
  'dec',
];

String _formatDateRo(DateTime date) {
  return '${date.day} ${_kRoMonths[date.month - 1]} ${date.year}';
}

class PlantDetailScreen extends StatefulWidget {
  final int plantId;

  const PlantDetailScreen({super.key, required this.plantId});

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  PlantRow? _plant;
  List<ReminderRow> _reminders = [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final plant = await DatabaseService.instance.getPlant(widget.plantId);
    final reminders = await DatabaseService.instance.getRemindersForPlant(widget.plantId);
    if (!mounted) return;
    setState(() {
      _plant = plant;
      _reminders = reminders;
    });
  }

  Future<void> _onMarkDone(ReminderRow reminder) async {
    await NotificationService.instance.markReminderDoneAndReschedule(reminder, _plant!.commonName);
    await _refresh();
  }

  Future<void> _onDelete() async {
    final plant = _plant;
    if (plant == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Șterge planta'),
        content: Text('Sigur vrei să ștergi „${plant.commonName}"?', style: const TextStyle(color: AppColors.text)),
        actionsPadding: const EdgeInsets.fromLTRB(0, 0, 16, 16),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Anulează')),
          OutlinedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Șterge')),
        ],
      ),
    );
    if (confirmed != true) return;

    for (final r in _reminders) {
      await NotificationService.instance.cancel(r.notificationId);
    }
    await DatabaseService.instance.deletePlant(plant.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final plant = _plant;
    if (plant == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final meta = lightMeta(lightNeedFromDb(plant.light));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
              child: Row(
                children: [
                  AppGhostIconButton(icon: Icons.chevron_left, onPressed: () => Navigator.of(context).maybePop()),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Detalii plantă', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: AppColors.text)),
                  ),
                  AppGhostIconButton(icon: Icons.delete_outline, onPressed: _onDelete),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  if (plant.photoPath != null)
                    Image.file(File(plant.photoPath!), height: 200, width: double.infinity, fit: BoxFit.cover)
                  else
                    Container(height: 200, color: AppColors.surface),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(plant.commonName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: AppColors.text)),
                        Text(
                          plant.scientificName,
                          style: const TextStyle(fontSize: 13, color: AppColors.neutral400, fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 18),
                        const Text('Îngrijire', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.neutral400)),
                        const SizedBox(height: 8),
                        _CareRow(icon: Icons.water_drop_outlined, text: 'Udare: la fiecare ${plant.wateringDays} zile'),
                        _CareRow(icon: meta.icon, text: meta.tag),
                        if (plant.misting) const _CareRow(icon: Icons.water_outlined, text: 'Beneficiază de pulverizare frecventă'),
                        if (plant.toxicToPets)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: _CareRow(icon: Icons.pets, text: 'Toxică pentru animale de companie', color: AppColors.accent2_300, fontSize: 13),
                          ),
                        for (final tip in plant.tips)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text('· $tip', style: const TextStyle(fontSize: 12, color: AppColors.neutral400)),
                          ),
                        const SizedBox(height: 20),
                        const Text('Remindere', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.neutral400)),
                        const SizedBox(height: 8),
                        for (final reminder in _reminders) ...[
                          AppCard(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(reminder.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text)),
                                      Text(
                                        'Următor: ${_formatDateRo(DateTime.fromMillisecondsSinceEpoch(reminder.nextDueAt))} · la fiecare ${reminder.intervalDays} zile',
                                        style: const TextStyle(fontSize: 12, color: AppColors.neutral400),
                                      ),
                                    ],
                                  ),
                                ),
                                OutlinedButton(onPressed: () => _onMarkDone(reminder), child: const Text('Marchează făcut')),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CareRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final double fontSize;

  const _CareRow({required this.icon, required this.text, this.color = AppColors.text, this.fontSize = 14});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: fontSize, color: color == AppColors.text ? AppColors.accent : color),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontSize: fontSize, color: color))),
        ],
      ),
    );
  }
}
