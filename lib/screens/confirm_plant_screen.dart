import 'dart:io';
import 'package:flutter/material.dart';
import '../data/care_info.dart';
import '../db/database_service.dart';
import '../models/plant_prediction.dart';
import '../services/notification_service.dart';
import 'plant_detail_screen.dart';

class ConfirmPlantScreen extends StatefulWidget {
  final String photoPath;
  final List<PlantPrediction> predictions;

  const ConfirmPlantScreen({super.key, required this.photoPath, required this.predictions});

  @override
  State<ConfirmPlantScreen> createState() => _ConfirmPlantScreenState();
}

class _ConfirmPlantScreenState extends State<ConfirmPlantScreen> {
  late int _selectedIndex;
  late TextEditingController _nameController;
  bool _saving = false;

  PlantPrediction get _selected => widget.predictions[_selectedIndex];
  CareInfo get _care => getCareInfo(_selected.scientificName);

  @override
  void initState() {
    super.initState();
    _selectedIndex = 0;
    _nameController = TextEditingController(text: _care.commonNameRo);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _selectPrediction(int index) {
    setState(() {
      _selectedIndex = index;
      _nameController.text = getCareInfo(widget.predictions[index].scientificName).commonNameRo;
    });
  }

  Future<void> _onSave() async {
    setState(() => _saving = true);
    try {
      await NotificationService.instance.requestPermissions();

      final care = _care;
      final commonName = _nameController.text.trim().isEmpty ? care.commonNameRo : _nameController.text.trim();

      final plantId = await DatabaseService.instance.addPlant(
        commonName: commonName,
        scientificName: _selected.scientificName,
        photoPath: widget.photoPath,
        confidence: _selected.confidence,
        light: lightNeedToDb(care.light),
        wateringDays: care.wateringDays,
        misting: care.misting,
        toxicToPets: care.toxicToPets,
        tips: care.tips,
      );

      final now = DateTime.now().millisecondsSinceEpoch;
      final waterDueAt = now + care.wateringDays * 24 * 60 * 60 * 1000;
      final waterReminderId = await DatabaseService.instance.addReminder(
        plantId: plantId,
        type: 'udare',
        label: 'Udare',
        intervalDays: care.wateringDays,
        nextDueAt: waterDueAt,
      );
      final waterNotifId = await NotificationService.instance.scheduleReminder(
        plantName: commonName,
        label: 'Udare',
        dueAtEpochMs: waterDueAt,
      );
      await DatabaseService.instance.setReminderNotificationId(waterReminderId, waterNotifId);

      if (care.misting) {
        final mistDueAt = now + 3 * 24 * 60 * 60 * 1000;
        final mistReminderId = await DatabaseService.instance.addReminder(
          plantId: plantId,
          type: 'pulverizare',
          label: 'Pulverizare frunze',
          intervalDays: 3,
          nextDueAt: mistDueAt,
        );
        final mistNotifId = await NotificationService.instance.scheduleReminder(
          plantName: commonName,
          label: 'Pulverizare frunze',
          dueAtEpochMs: mistDueAt,
        );
        await DatabaseService.instance.setReminderNotificationId(mistReminderId, mistNotifId);
      }

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => PlantDetailScreen(plantId: plantId)),
        (route) => route.isFirst,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final care = _care;
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmă planta')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          Image.file(File(widget.photoPath), height: 260, width: double.infinity, fit: BoxFit.cover),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Am identificat:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < widget.predictions.length; i++)
                      ChoiceChip(
                        label: Text(
                          '${widget.predictions[i].scientificName} (${(widget.predictions[i].confidence * 100).round()}%)',
                          style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                        ),
                        selected: i == _selectedIndex,
                        onSelected: (_) => _selectPrediction(i),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('Nume plantă', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                const SizedBox(height: 6),
                TextField(controller: _nameController, decoration: const InputDecoration(border: OutlineInputBorder())),
                const SizedBox(height: 20),
                const Text('Îngrijire', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                const SizedBox(height: 6),
                Text('💧 Udare: la fiecare ${care.wateringDays} zile', style: const TextStyle(fontSize: 15)),
                Text('☀️ ${lightLabelRo(care.light)}', style: const TextStyle(fontSize: 15)),
                if (care.misting)
                  const Text('💦 Beneficiază de pulverizare frecventă', style: TextStyle(fontSize: 15)),
                if (care.toxicToPets)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      '⚠️ Toxică pentru animale de companie',
                      style: TextStyle(fontSize: 14, color: Color(0xffb71c1c), fontWeight: FontWeight.w600),
                    ),
                  ),
                for (final tip in care.tips)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('• $tip', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                  ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : _onSave,
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: Text(_saving ? 'Se salvează...' : 'Adaugă planta și setează remindere'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
