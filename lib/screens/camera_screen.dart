import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/disease_prediction.dart';
import '../models/plant_prediction.dart';
import '../services/local_plant_model_service.dart';
import '../services/plant_disease_service.dart';
import '../services/plant_id_service.dart';
import '../theme/app_theme.dart';
import '../widgets/species_thumbnail.dart';
import 'confirm_plant_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

enum _Status {
  requestingPermission,
  permissionDenied,
  initializing,
  ready,
  noCamera,
  classifying,
  revealing,
}

class _Shot {
  final String path;
  final String organ;
  const _Shot(this.path, this.organ);
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  _Status _status = _Status.requestingPermission;
  bool _permanentlyDenied = false;
  PlantPrediction? _revealedPrediction;
  Completer<void>? _revealTapCompleter;

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
    final controller = CameraController(
      back,
      ResolutionPreset.high,
      enableAudio: false,
    );
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
    if (state == AppLifecycleState.resumed &&
        _status == _Status.permissionDenied) {
      _setup();
    }
  }

  Future<void> _deleteQuietly(String path) async {
    try {
      await File(path).delete();
    } catch (_) {}
  }

  Future<void> _onCapture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (_status != _Status.ready) return;

    final xfile = await controller.takePicture();
    final docsDir = await getApplicationDocumentsDirectory();
    final fileName = 'plant_${DateTime.now().millisecondsSinceEpoch}_auto.jpg';
    final savedPath = p.join(docsDir.path, fileName);
    await File(xfile.path).copy(savedPath);

    await _identifyShots([_Shot(savedPath, 'auto')]);
  }

  Future<void> _pickFromGallery() async {
    if (_status != _Status.ready) return;
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (picked == null || !mounted) return;

    final docsDir = await getApplicationDocumentsDirectory();
    final fileName =
        'plant_${DateTime.now().millisecondsSinceEpoch}_gallery.jpg';
    final savedPath = p.join(docsDir.path, fileName);
    await File(picked.path).copy(savedPath);

    await _identifyShots([_Shot(savedPath, 'auto')]);
  }

  Future<void> _identifyShots(List<_Shot> shots) async {
    if (shots.isEmpty) return;
    final representative = shots.firstWhere(
      (s) => s.organ == 'auto',
      orElse: () => shots.first,
    );

    setState(() => _status = _Status.classifying);
    try {
      const minSearchDuration = Duration(milliseconds: 3500);
      final stopwatch = Stopwatch()..start();
      // Boala se caută pe aceeași poză, în paralel cu identificarea speciei —
      // dacă eșuează (fără internet, etc.) nu blochează identificarea.
      final localFuture = LocalPlantModelService.instance
          .classifyImageFile(File(representative.path))
          .catchError((_) => <PlantPrediction>[]);
      final plantNetFuture = PlantIdService.instance
          .classifyImages(
            shots.map((s) => File(s.path)).toList(),
            shots.map((s) => s.organ).toList(),
          )
          .catchError((_) => <PlantPrediction>[]);
      final diseaseFuture = PlantDiseaseService.instance
          .diagnoseImage(File(representative.path))
          .catchError((_) => <DiseasePrediction>[]);

      final localPredictions = await localFuture;
      final plantNetPredictions = await plantNetFuture;
      final diseasePredictions = await diseaseFuture;
      final remaining = minSearchDuration - stopwatch.elapsed;
      if (remaining > Duration.zero) {
        await Future.delayed(remaining);
      }

      if (plantNetPredictions.isEmpty && localPredictions.isEmpty) {
        throw StateError(
          'Identificarea a eșuat pentru ambele surse (Pl@ntNet și modelul local).',
        );
      }

      final isPlantNet = plantNetPredictions.isNotEmpty;
      final topPrediction = isPlantNet
          ? plantNetPredictions.first
          : localPredictions.first;
      if (!mounted) return;
      final tapCompleter = Completer<void>();
      _revealTapCompleter = tapCompleter;
      setState(() {
        _status = _Status.revealing;
        _revealedPrediction = topPrediction;
      });
      await tapCompleter.future;

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ConfirmPlantScreen(
            photoPath: representative.path,
            plantNetPredictions: isPlantNet ? [topPrediction] : [],
            localPredictions: isPlantNet ? [] : [topPrediction],
            diseasePredictions: diseasePredictions,
            hideSuggestions: true,
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
          SnackBar(
            content: Text(
              e is StateError ? e.message : 'Identificarea a eșuat.',
            ),
          ),
        );
      }
    } finally {
      _revealTapCompleter = null;
      if (mounted) {
        setState(() {
          _status = _Status.ready;
          _revealedPrediction = null;
        });
      }
    }
  }

  void _onRevealTap() {
    if (!(_revealTapCompleter?.isCompleted ?? true)) {
      _revealTapCompleter!.complete();
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
                    style: TextStyle(color: AppColors.text),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: _permanentlyDenied ? openAppSettings : _setup,
                    child: Text(
                      _permanentlyDenied
                          ? 'Deschide Setări'
                          : 'Permite accesul la cameră',
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      case _Status.noCamera:
        return Scaffold(
          body: Center(
            child: Text(
              'Nu s-a găsit nicio cameră disponibilă.',
              style: TextStyle(color: AppColors.text),
            ),
          ),
        );
      case _Status.ready:
      case _Status.classifying:
      case _Status.revealing:
        final controller = _controller!;
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      color: const Color(0x8c161826),
                      child: const Text(
                        'Fotografiază planta — o singură poză e de-ajuns',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
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
                      border: Border.all(
                        color: const Color(0x59e9e9ed),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
              if (_status == _Status.classifying ||
                  _status == _Status.revealing)
                GestureDetector(
                  onTap: _status == _Status.revealing ? _onRevealTap : null,
                  child: Container(
                    color: Colors.black54,
                    child: Center(
                      child:
                          _status == _Status.revealing &&
                              _revealedPrediction != null
                          ? _RevealedPlantCard(prediction: _revealedPrediction!)
                          : const _SearchingPhoneAnimation(),
                    ),
                  ),
                ),
              Positioned(
                bottom: 28,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 56,
                            height: 56,
                            child: GestureDetector(
                              onTap: _status == _Status.ready
                                  ? _pickFromGallery
                                  : null,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(28),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 8,
                                    sigmaY: 8,
                                  ),
                                  child: Container(
                                    color: const Color(0x8c161826),
                                    child: const Icon(
                                      Icons.photo_library_outlined,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: GestureDetector(
                                onTap: _status == _Status.ready
                                    ? _onCapture
                                    : null,
                                child: Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                      width: 4,
                                    ),
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 58,
                                      height: 58,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 56),
                        ],
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

/// Phone-with-camera icon that jitters/shakes while a scan is in progress.
class _SearchingPhoneAnimation extends StatefulWidget {
  const _SearchingPhoneAnimation();

  @override
  State<_SearchingPhoneAnimation> createState() =>
      _SearchingPhoneAnimationState();
}

class _SearchingPhoneAnimationState extends State<_SearchingPhoneAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final phoneSize = (screenSize.shortestSide * 0.75).clamp(160.0, 520.0);
    final cameraBadgeSize = phoneSize * 0.32;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = _controller.value;
            final angle = (t - 0.5) * 0.22; // gentle shake, ± ~6°
            final dx = (t - 0.5) * (phoneSize * 0.12);
            return Transform.translate(
              offset: Offset(dx, 0),
              child: Transform.rotate(angle: angle, child: child),
            );
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.smartphone, size: phoneSize, color: AppColors.accent),
              Positioned(
                bottom: phoneSize * 0.16,
                right: phoneSize * 0.05,
                child: Icon(
                  Icons.camera_alt,
                  size: cameraBadgeSize,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Se caută planta...',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ],
    );
  }
}

/// Briefly shown once the top match is known, before handing off to the
/// confirmation screen: the species reference photo in a small frame.
class _RevealedPlantCard extends StatelessWidget {
  final PlantPrediction prediction;

  const _RevealedPlantCard({required this.prediction});

  @override
  Widget build(BuildContext context) {
    final photoSize = MediaQuery.of(context).size.shortestSide * 0.5;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0, 1),
        child: Transform.scale(scale: 0.85 + 0.15 * t, child: child),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.accent, width: 3),
              borderRadius: BorderRadius.circular(AppRadius.md),
              color: AppColors.surface,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: SpeciesThumbnail(
                scientificName: prediction.scientificName,
                size: photoSize,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            prediction.scientificName,
            style: const TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '${(prediction.confidence * 100).round()}% potrivire',
            style: TextStyle(fontSize: 12, color: AppColors.neutral400),
          ),
          const SizedBox(height: 16),
          const Text(
            'Atinge ecranul pentru a continua',
            style: TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
