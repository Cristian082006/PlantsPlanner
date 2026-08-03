import 'dart:io';
import 'package:flutter/material.dart';
import '../data/care_info.dart';
import '../db/database_service.dart';
import '../models/plant_prediction.dart';
import '../services/app_tab_controller.dart';
import '../services/notification_service.dart';
import '../services/species_thumbnail_service.dart';
import '../theme/app_theme.dart';
import '../widgets/species_thumbnail.dart';

enum _Source { plantNet, local, manual }

class _Selection {
  final _Source source;
  final int index;
  final String scientificName;
  final double confidence;

  const _Selection({
    required this.source,
    required this.index,
    required this.scientificName,
    required this.confidence,
  });
}

class ConfirmPlantScreen extends StatefulWidget {
  final String photoPath;
  final List<PlantPrediction> plantNetPredictions;
  final List<PlantPrediction> localPredictions;
  final bool hideSuggestions;

  const ConfirmPlantScreen({
    super.key,
    required this.photoPath,
    required this.plantNetPredictions,
    required this.localPredictions,
    this.hideSuggestions = false,
  });

  @override
  State<ConfirmPlantScreen> createState() => _ConfirmPlantScreenState();
}

class _ConfirmPlantScreenState extends State<ConfirmPlantScreen> {
  late _Selection _selection;
  late TextEditingController _nameController;
  bool _saving = false;

  CareInfo get _care => getCareInfo(_selection.scientificName);

  @override
  void initState() {
    super.initState();
    if (widget.plantNetPredictions.isNotEmpty) {
      final p = widget.plantNetPredictions[0];
      _selection = _Selection(source: _Source.plantNet, index: 0, scientificName: p.scientificName, confidence: p.confidence);
    } else {
      final p = widget.localPredictions[0];
      _selection = _Selection(source: _Source.local, index: 0, scientificName: p.scientificName, confidence: p.confidence);
    }
    _nameController = TextEditingController(text: _care.commonNameRo);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _select(_Source source, int index, PlantPrediction prediction) {
    setState(() {
      _selection = _Selection(
        source: source,
        index: index,
        scientificName: prediction.scientificName,
        confidence: prediction.confidence,
      );
      _nameController.text = getCareInfo(prediction.scientificName).commonNameRo;
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
      _selection = _Selection(source: _Source.manual, index: -1, scientificName: key, confidence: 1.0);
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
        scientificName: _selection.scientificName,
        photoPath: widget.photoPath,
        confidence: _selection.confidence,
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
      AppTabController.instance.showHomeTab();
      Navigator.of(context).popUntil((route) => route.isFirst);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _predictionSection({
    required String title,
    required List<PlantPrediction> predictions,
    required _Source source,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.neutral400)),
        const SizedBox(height: 8),
        if (predictions.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Text('Indisponibil pentru această scanare.', style: TextStyle(fontSize: 12, color: AppColors.neutral400)),
          )
        else
          for (var i = 0; i < predictions.length; i++) ...[
            _PredictionRow(
              scientificName: predictions[i].scientificName,
              label: '${predictions[i].scientificName} · ${(predictions[i].confidence * 100).round()}%',
              selected: _selection.source == source && _selection.index == i,
              onTap: () => _select(source, i, predictions[i]),
            ),
            const SizedBox(height: 8),
          ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final care = _care;
    final meta = lightMeta(care.light);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        AppTabController.instance.showHomeTab();
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
      child: Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
              child: Row(
                children: [
                  AppGhostIconButton(
                    icon: Icons.chevron_left,
                    onPressed: () {
                      AppTabController.instance.showHomeTab();
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                  ),
                  const SizedBox(width: 8),
                  const Text('Confirmă planta', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: AppColors.text)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  _SelectedPlantPhoto(scientificName: _selection.scientificName, fallbackPhotoPath: widget.photoPath),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!widget.hideSuggestions) ...[
                          _predictionSection(
                            title: 'Sugestii Pl@ntNet (online)',
                            predictions: widget.plantNetPredictions,
                            source: _Source.plantNet,
                          ),
                          const SizedBox(height: 16),
                          _predictionSection(
                            title: 'Sugestii model local (offline)',
                            predictions: widget.localPredictions,
                            source: _Source.local,
                          ),
                          if (_selection.source == _Source.manual) ...[
                            const SizedBox(height: 8),
                            _PredictionRow(
                              scientificName: _selection.scientificName,
                              label: '${_selection.scientificName} (manual)',
                              selected: true,
                              onTap: () {},
                            ),
                          ],
                          const SizedBox(height: 8),
                        ],
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
      ),
    );
  }
}

class _SelectedPlantPhoto extends StatelessWidget {
  final String scientificName;
  final String fallbackPhotoPath;

  const _SelectedPlantPhoto({required this.scientificName, required this.fallbackPhotoPath});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      key: ValueKey(scientificName),
      future: SpeciesThumbnailService.instance.getThumbnailUrl(scientificName),
      builder: (context, snapshot) {
        final url = snapshot.data;
        if (url != null) {
          return Image.network(
            url,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _fallback(),
          );
        }
        return _fallback();
      },
    );
  }

  Widget _fallback() {
    return Image.file(File(fallbackPhotoPath), height: 200, width: double.infinity, fit: BoxFit.cover);
  }
}

class _PredictionRow extends StatelessWidget {
  final String scientificName;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PredictionRow({
    required this.scientificName,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: selected ? AppColors.accent : Colors.transparent, width: 1.5),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: SpeciesThumbnail(scientificName: scientificName, size: 56),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: AppColors.text),
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                size: 20,
                color: selected ? AppColors.accent : AppColors.neutral600,
              ),
            ],
          ),
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
                          leading: SpeciesThumbnail(scientificName: entry.key, size: 64),
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
