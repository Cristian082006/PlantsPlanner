import 'dart:io';
import 'package:flutter/material.dart';
import '../data/care_info.dart';
import '../db/database_service.dart';
import '../services/notification_service.dart';

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
        content: Text('Sigur vrei să ștergi "${plant.commonName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Anulează')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Șterge')),
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

    return Scaffold(
      appBar: AppBar(title: const Text('Detalii plantă')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          if (plant.photoPath != null)
            Image.file(File(plant.photoPath!), height: 260, width: double.infinity, fit: BoxFit.cover)
          else
            Container(height: 260, color: const Color(0xffeeeeee)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plant.commonName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text(
                  plant.scientificName,
                  style: const TextStyle(fontSize: 14, color: Colors.black54, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 18),
                const Text('ÎNGRIJIRE', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54)),
                const SizedBox(height: 6),
                Text('💧 Udare: la fiecare ${plant.wateringDays} zile', style: const TextStyle(fontSize: 15)),
                Text('☀️ ${lightLabelRo(lightNeedFromDb(plant.light))}', style: const TextStyle(fontSize: 15)),
                if (plant.misting)
                  const Text('💦 Beneficiază de pulverizare frecventă', style: TextStyle(fontSize: 15)),
                if (plant.toxicToPets)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      '⚠️ Toxică pentru animale de companie',
                      style: TextStyle(fontSize: 14, color: Color(0xffb71c1c), fontWeight: FontWeight.w600),
                    ),
                  ),
                for (final tip in plant.tips)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('• $tip', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                  ),
                const SizedBox(height: 20),
                const Text('REMINDERE', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54)),
                const SizedBox(height: 8),
                for (final reminder in _reminders)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xfff4f8f4), borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(reminder.label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                              Text(
                                'Următor: ${_formatDateRo(DateTime.fromMillisecondsSinceEpoch(reminder.nextDueAt))} · la fiecare ${reminder.intervalDays} zile',
                                style: const TextStyle(fontSize: 12, color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                        FilledButton(onPressed: () => _onMarkDone(reminder), child: const Text('Marchează făcut')),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: _onDelete,
                    child: const Text('Șterge planta', style: TextStyle(color: Color(0xffb71c1c))),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
