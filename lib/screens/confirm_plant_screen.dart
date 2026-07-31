import 'dart:io';
import 'package:flutter/material.dart';
import '../data/care_info.dart';
import '../db/database_service.dart';
import '../models/plant_prediction.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/species_thumbnail.dart';
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
  String? _manualScientificName;

  String get _effectiveScientificName => _manualScientificName ?? widget.predictions[_selectedIndex].scientificName;
  double get _effectiveConfidence => _manualScientificName != null ? 1.0 : widget.predictions[_selectedIndex].confidence;
  CareInfo get _care => getCareInfo(_effectiveScientificName);

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
      _manualScientificName = null;
      _nameController.text = getCareInfo(widget.predictions[index].scientificName).commonNameRo;
    });
  }

  Future<void> _openManualSearch() async {
    final key = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => const _ManualPlantSearchSheet(),
    );
    if (key == null) return;
    setState(() {
      _manualScientificName = key;
      _nameController.text = getCareInfo(key).commonNameRo;
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
        scientificName: _effectiveScientificName,
        photoPath: widget.photoPath,
        confidence: _effectiveConfidence,
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
    final meta = lightMeta(care.light);
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
                  const Text('Confirmă planta', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: AppColors.text)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  Image.file(File(widget.photoPath), height: 200, width: double.infinity, fit: BoxFit.cover),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Am identificat', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.neutral400)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (var i = 0; i < widget.predictions.length; i++)
                              AppTag(
                                text: '${widget.predictions[i].scientificName} · ${(widget.predictions[i].confidence * 100).round()}%',
                                leading: SpeciesThumbnail(scientificName: widget.predictions[i].scientificName, size: 20),
                                style: _manualScientificName == null && i == _selectedIndex
                                    ? AppTagStyle.accent
                                    : AppTagStyle.outline,
                                onTap: () => _selectPrediction(i),
                              ),
                            if (_manualScientificName != null)
                              AppTag(
                                text: '$_manualScientificName (manual)',
                                leading: SpeciesThumbnail(scientificName: _manualScientificName!, size: 20),
                                style: AppTagStyle.accent,
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _openManualSearch,
                          child: const Text(
                            'Nu e planta corectă? Caută manual',
                            style: TextStyle(fontSize: 12, color: AppColors.accent, decoration: TextDecoration.underline),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text('Nume plantă', style: TextStyle(fontSize: 12, color: AppColors.neutral400)),
                        const SizedBox(height: 6),
                        TextField(controller: _nameController, style: const TextStyle(color: AppColors.text, fontSize: 14)),
                        const SizedBox(height: 20),
                        const Text('Îngrijire', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.neutral400)),
                        const SizedBox(height: 8),
                        _CareRow(icon: Icons.water_drop_outlined, text: 'Udare: la fiecare ${care.wateringDays} zile'),
                        _CareRow(icon: meta.icon, text: meta.tag),
                        if (care.misting) const _CareRow(icon: Icons.water_outlined, text: 'Beneficiază de pulverizare frecventă'),
                        if (care.toxicToPets)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: _CareRow(icon: Icons.pets, text: 'Toxică pentru animale de companie', color: AppColors.accent2_300, fontSize: 13),
                          ),
                        for (final tip in care.tips)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text('· $tip', style: const TextStyle(fontSize: 12, color: AppColors.neutral400)),
                          ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _saving ? null : _onSave,
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                            child: Text(_saving ? 'Se salvează...' : 'Adaugă planta și setează remindere'),
                          ),
                        ),
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

class _ManualPlantSearchSheet extends StatefulWidget {
  const _ManualPlantSearchSheet();

  @override
  State<_ManualPlantSearchSheet> createState() => _ManualPlantSearchSheetState();
}

class _ManualPlantSearchSheetState extends State<_ManualPlantSearchSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final entries = kCareDb.entries.where((e) {
      if (query.isEmpty) return true;
      return e.key.contains(query) || e.value.commonNameRo.toLowerCase().contains(query);
    }).toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                autofocus: true,
                style: const TextStyle(color: AppColors.text, fontSize: 14),
                decoration: const InputDecoration(hintText: 'Caută după nume...'),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Expanded(
              child: entries.isEmpty
                  ? const Center(
                      child: Text('Nicio plantă găsită.', style: TextStyle(color: AppColors.neutral400)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      itemCount: entries.length,
                      itemBuilder: (context, i) {
                        final entry = entries[i];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: SpeciesThumbnail(scientificName: entry.key, size: 40),
                          title: Text(entry.value.commonNameRo, style: const TextStyle(color: AppColors.text, fontSize: 14, fontWeight: FontWeight.w500)),
                          subtitle: Text(entry.key, style: const TextStyle(color: AppColors.neutral400, fontSize: 12, fontStyle: FontStyle.italic)),
                          onTap: () => Navigator.of(context).pop(entry.key),
                        );
                      },
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
