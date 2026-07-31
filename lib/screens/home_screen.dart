import 'dart:io';
import 'package:flutter/material.dart';
import '../db/database_service.dart';
import '../services/notification_service.dart';
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
      appBar: AppBar(title: const Text('Plantele mele')),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_due.isNotEmpty) ...[
              const Text('De făcut acum', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              for (final item in _due)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xfffff3e0), borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${item.reminder.label} — ${item.plantCommonName}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xff5d4037)),
                        ),
                      ),
                      FilledButton(onPressed: () => _onMarkDone(item), child: const Text('Marchează făcut')),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
            ],
            const Text('Plantele tale', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (_plants.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Column(
                  children: [
                    Text('Nu ai adăugat încă nicio plantă.', style: TextStyle(fontWeight: FontWeight.w600)),
                    SizedBox(height: 6),
                    Text(
                      'Mergi la tab-ul "Identifică" ca să scanezi prima ta plantă.',
                      style: TextStyle(color: Colors.black54, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              for (final plant in _plants)
                InkWell(
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => PlantDetailScreen(plantId: plant.id)),
                    );
                    refresh();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xfff4f8f4), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: plant.photoPath != null
                              ? Image.file(File(plant.photoPath!), width: 56, height: 56, fit: BoxFit.cover)
                              : Container(width: 56, height: 56, color: const Color(0xffdddddd)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(plant.commonName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              Text(
                                plant.scientificName,
                                style: const TextStyle(fontSize: 12, color: Colors.black54, fontStyle: FontStyle.italic),
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
    );
  }
}
