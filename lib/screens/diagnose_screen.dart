import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../data/disease_treatment.dart';
import '../models/disease_prediction.dart';
import '../services/plant_disease_service.dart';
import '../theme/app_theme.dart';
import '../widgets/plants_backdrop.dart';

enum _Status { pickingSource, diagnosing, results, error }

class DiagnoseScreen extends StatefulWidget {
  final String? plantCommonName;

  const DiagnoseScreen({super.key, this.plantCommonName});

  @override
  State<DiagnoseScreen> createState() => _DiagnoseScreenState();
}

class _DiagnoseScreenState extends State<DiagnoseScreen> {
  _Status _status = _Status.pickingSource;
  File? _image;
  List<DiseasePrediction> _results = [];
  String _errorMessage = '';

  Future<void> _pickAndDiagnose(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 90,
    );
    if (picked == null || !mounted) return;

    final file = File(picked.path);
    setState(() {
      _image = file;
      _status = _Status.diagnosing;
    });

    try {
      final results = await PlantDiseaseService.instance.diagnoseImage(file);
      if (!mounted) return;
      setState(() {
        _results = results;
        _status = _Status.results;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e is StateError ? e.message : 'Diagnoza a eșuat.';
        _status = _Status.error;
      });
    }
  }

  void _reset() {
    setState(() {
      _status = _Status.pickingSource;
      _image = null;
      _results = [];
      _errorMessage = '';
    });
  }

  bool get _isStandaloneTab => widget.plantCommonName == null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PlantsBackdrop(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
                child: Row(
                  children: [
                    if (!_isStandaloneTab) ...[
                      AppGhostIconButton(
                        icon: Icons.chevron_left,
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        _isStandaloneTab
                            ? 'Diagnoză plantă'
                            : 'Diagnoză · ${widget.plantCommonName}',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          color: AppColors.text,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_status) {
      case _Status.pickingSource:
        return _PickSourceView(onPick: _pickAndDiagnose);
      case _Status.diagnosing:
        return _DiagnosingView(image: _image);
      case _Status.results:
        return _ResultsView(image: _image, results: _results, onRetry: _reset);
      case _Status.error:
        return _ErrorView(message: _errorMessage, onRetry: _reset);
    }
  }
}

class _PickSourceView extends StatelessWidget {
  final void Function(ImageSource) onPick;

  const _PickSourceView({required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.health_and_safety_outlined,
            size: 64,
            color: AppColors.accent,
          ),
          const SizedBox(height: 16),
          Text(
            'Fotografiază frunza sau partea afectată a plantei pentru a căuta boli sau dăunători.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.text, fontSize: 14),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => onPick(ImageSource.camera),
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Fă o poză'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => onPick(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Alege din galerie'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiagnosingView extends StatelessWidget {
  final File? image;

  const _DiagnosingView({required this.image});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (image != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Image.file(
              image!,
              height: 200,
              width: 200,
              fit: BoxFit.cover,
            ),
          ),
        const SizedBox(height: 20),
        CircularProgressIndicator(color: AppColors.accent),
        const SizedBox(height: 16),
        Text(
          'Se caută boli și dăunători...',
          style: TextStyle(color: AppColors.neutral400),
        ),
      ],
    );
  }
}

class _ResultsView extends StatelessWidget {
  final File? image;
  final List<DiseasePrediction> results;
  final VoidCallback onRetry;

  const _ResultsView({
    required this.image,
    required this.results,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        if (image != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Image.file(
              image!,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        const SizedBox(height: 16),
        Text(
          'Rezultatele provin din baza de date EPPO (Pl@ntNet), descrierile pot fi în engleză. Diagnoza este orientativă și nu înlocuiește un specialist.',
          style: TextStyle(fontSize: 12, color: AppColors.neutral400),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < results.length; i++) ...[
          AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.bug_report_outlined,
                  color: AppColors.accent,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        results[i].description,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${(results[i].confidence * 100).round()}% potrivire',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.neutral400,
                        ),
                      ),
                      if (i == 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.healing_outlined,
                              size: 14,
                              color: AppColors.accent2,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                treatmentAdviceRo(results[i].description),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.neutral400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onRetry,
            child: const Text('Diagnostichează altă poză'),
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: AppColors.accent2_300),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.text),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('Încearcă din nou'),
          ),
        ],
      ),
    );
  }
}
