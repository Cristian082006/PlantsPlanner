import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/plant_prediction.dart';
import '../services/local_plant_model_service.dart';
import '../services/plant_id_service.dart';
import '../theme/app_theme.dart';
import 'confirm_plant_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

enum _Status { requestingPermission, permissionDenied, initializing, ready, noCamera, classifying }

class _Shot {
  final String path;
  final String organ;
  const _Shot(this.path, this.organ);
}

// Pl@ntNet identifies houseplants more reliably from a close-up leaf shot
// plus a whole-plant shot; a third optional flower/fruit shot helps further.
const List<String> _shotOrgans = ['leaf', 'auto', 'flower'];
const List<String> _shotInstructions = [
  'Fotografiază frunza de aproape',
  'Acum fotografiază planta întreagă',
  'Opțional: o floare sau un fruct',
];
const int _maxShots = 3;
const int _minShotsToIdentify = 2;

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  _Status _status = _Status.requestingPermission;
  bool _permanentlyDenied = false;
  final List<_Shot> _shots = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setup();
  }

  Future<void> _setup() async {
    final permission = await Permission.camera.request();
    if (!permission.isGranted) {
      setState(() {
        _status = _Status.permissionDenied;
        _permanentlyDenied = permission.isPermanentlyDenied;
      });
      return;
    }

    setState(() => _status = _Status.initializing);
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      setState(() => _status = _Status.noCamera);
      return;
    }

    final back = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
    final controller = CameraController(back, ResolutionPreset.high, enableAudio: false);
    await controller.initialize();
    if (!mounted) return;
    setState(() {
      _controller = controller;
      _status = _Status.ready;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _status == _Status.permissionDenied) {
      _setup();
    }
  }

  void _resetShots() {
    setState(() => _shots.clear());
  }

  Future<void> _deleteQuietly(String path) async {
    try {
      await File(path).delete();
    } catch (_) {}
  }

  Future<void> _onCapture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (_shots.length >= _maxShots) return;

    final organ = _shotOrgans[_shots.length];
    final xfile = await controller.takePicture();
    final docsDir = await getApplicationDocumentsDirectory();
    final fileName = 'plant_${DateTime.now().millisecondsSinceEpoch}_$organ.jpg';
    final savedPath = p.join(docsDir.path, fileName);
    await File(xfile.path).copy(savedPath);

    setState(() => _shots.add(_Shot(savedPath, organ)));

    if (_shots.length >= _maxShots) {
      await _identify();
    }
  }

  Future<void> _identify() async {
    if (_shots.isEmpty) return;
    final shots = List<_Shot>.from(_shots);
    final representative = shots.firstWhere((s) => s.organ == 'auto', orElse: () => shots.first);

    setState(() => _status = _Status.classifying);
    try {
      final results = await Future.wait([
        LocalPlantModelService.instance
            .classifyImageFile(File(representative.path))
            .catchError((_) => <PlantPrediction>[]),
        PlantIdService.instance
            .classifyImages(shots.map((s) => File(s.path)).toList(), shots.map((s) => s.organ).toList())
            .catchError((_) => <PlantPrediction>[]),
      ]);
      final localPredictions = results[0];
      final plantNetPredictions = results[1];

      if (plantNetPredictions.isEmpty && localPredictions.isEmpty) {
        throw StateError('Identificarea a eșuat pentru ambele surse (Pl@ntNet și modelul local).');
      }

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ConfirmPlantScreen(
            photoPath: representative.path,
            plantNetPredictions: plantNetPredictions,
            localPredictions: localPredictions,
          ),
        ),
      );

      for (final s in shots) {
        if (s.path != representative.path) {
          unawaited(_deleteQuietly(s.path));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is StateError ? e.message : 'Identificarea a eșuat.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _status = _Status.ready;
          _shots.clear();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_status) {
      case _Status.requestingPermission:
      case _Status.initializing:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case _Status.permissionDenied:
        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _permanentlyDenied
                        ? 'Accesul la cameră a fost refuzat. Activează-l din Setări pentru a identifica plantele.'
                        : 'Aplicația are nevoie de acces la cameră pentru a identifica plantele.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.text),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: _permanentlyDenied ? openAppSettings : _setup,
                    child: Text(_permanentlyDenied ? 'Deschide Setări' : 'Permite accesul la cameră'),
                  ),
                ],
              ),
            ),
          ),
        );
      case _Status.noCamera:
        return const Scaffold(body: Center(child: Text('Nu s-a găsit nicio cameră disponibilă.', style: TextStyle(color: AppColors.text))));
      case _Status.ready:
      case _Status.classifying:
        final controller = _controller!;
        final canIdentifyNow = _shots.length >= _minShotsToIdentify && _status == _Status.ready;
        final instruction = _shotInstructions[_shots.length.clamp(0, _shotInstructions.length - 1)];
        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              CameraPreview(controller),
              Positioned(
                top: 54,
                left: 16,
                right: 16,
                child: Row(
                  children: [
                    Flexible(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            color: const Color(0x8c161826),
                            child: Text(
                              '$instruction (${_shots.length}/$_maxShots)',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_shots.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: GestureDetector(
                            onTap: _status == _Status.ready ? _resetShots : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              color: const Color(0x8c161826),
                              child: const Text('Renunță', style: TextStyle(fontSize: 13, color: Colors.white)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Positioned(
                top: 24,
                left: 24,
                right: 24,
                bottom: 24,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0x59e9e9ed), width: 1.5),
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
              if (_status == _Status.classifying)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: AppColors.accent),
                        SizedBox(height: 12),
                        Text('Se identifică planta...', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              Positioned(
                bottom: 28,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    if (canIdentifyNow) ...[
                      OutlinedButton(
                        onPressed: _identify,
                        child: Text('Identifică acum (${_shots.length} poze)'),
                      ),
                      const SizedBox(height: 16),
                    ],
                    GestureDetector(
                      onTap: _status == _Status.ready ? _onCapture : null,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 4),
                        ),
                        child: Center(
                          child: Container(
                            width: 58,
                            height: 58,
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                          ),
                        ),
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
}
