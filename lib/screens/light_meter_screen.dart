import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../data/care_info.dart';
import '../services/light_meter_service.dart';
import '../theme/app_theme.dart';

enum _Status { requestingPermission, permissionDenied, initializing, ready, noCamera }

/// Order from least to most light, used to tell the user whether a spot is
/// too dark or too bright for the plant, not just "different".
const _kLightOrder = [LightNeed.shade, LightNeed.weakIndirect, LightNeed.strongIndirect, LightNeed.directLight];

class LightMeterScreen extends StatefulWidget {
  final String? plantName;
  final LightNeed? targetLight;

  const LightMeterScreen({super.key, this.plantName, this.targetLight});

  @override
  State<LightMeterScreen> createState() => _LightMeterScreenState();
}

class _LightMeterScreenState extends State<LightMeterScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  _Status _status = _Status.requestingPermission;
  bool _permanentlyDenied = false;
  double? _lux;
  DateTime _lastSample = DateTime.fromMillisecondsSinceEpoch(0);

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
    final controller = CameraController(back, ResolutionPreset.low, enableAudio: false);
    await controller.initialize();
    if (!mounted) {
      await controller.dispose();
      return;
    }
    await controller.startImageStream(_onFrame);
    setState(() {
      _controller = controller;
      _status = _Status.ready;
    });
  }

  void _onFrame(CameraImage image) {
    final now = DateTime.now();
    if (now.difference(_lastSample) < const Duration(milliseconds: 400)) return;
    _lastSample = now;

    final lux = estimateLux(
      apertureFStop: image.lensAperture,
      exposureTimeNanos: image.sensorExposureTime,
      iso: image.sensorSensitivity,
    );
    if (lux == null || !mounted) return;
    setState(() => _lux = lux);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final controller = _controller;
    if (controller != null) {
      if (controller.value.isStreamingImages) {
        controller.stopImageStream();
      }
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _status == _Status.permissionDenied) {
      _setup();
    }
  }

  String? _verdict() {
    final lux = _lux;
    final target = widget.targetLight;
    if (lux == null || target == null) return null;

    final measured = lightNeedFromLux(lux);
    final measuredIdx = _kLightOrder.indexOf(measured);
    final targetIdx = _kLightOrder.indexOf(target);

    if (measuredIdx == targetIdx) return 'Potrivit pentru ${widget.plantName ?? "această plantă"}.';
    if (measuredIdx < targetIdx) {
      return 'Prea întunecat pentru ${widget.plantName ?? "această plantă"} — are nevoie de mai multă lumină.';
    }
    return 'Mai multă lumină decât are nevoie ${widget.plantName ?? "această plantă"} — ar tolera și un loc mai umbrit.';
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
                        ? 'Accesul la cameră a fost refuzat. Activează-l din Setări pentru a măsura lumina.'
                        : 'Aplicația are nevoie de acces la cameră pentru a măsura lumina.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.text),
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
        return Scaffold(body: Center(child: Text('Nu s-a găsit nicio cameră disponibilă.', style: TextStyle(color: AppColors.text))));
      case _Status.ready:
        final controller = _controller!;
        final lux = _lux;
        final verdict = _verdict();
        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              CameraPreview(controller),
              Positioned(
                top: 54,
                left: 16,
                child: SafeArea(
                  bottom: false,
                  child: AppGhostIconButton(icon: Icons.chevron_left, onPressed: () => Navigator.of(context).maybePop()),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 40,
                child: SafeArea(
                  top: false,
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (lux == null)
                            Text('Se măsoară...', style: TextStyle(color: AppColors.neutral400))
                          else ...[
                            Text(
                              '${lux.round()} lux',
                              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.text),
                            ),
                            const SizedBox(height: 2),
                            Text(luxLabelRo(lux), style: TextStyle(fontSize: 13, color: AppColors.neutral400)),
                          ],
                          if (verdict != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              verdict,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.accent),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            'Estimare orientativă din expunerea camerei, nu un luxmetru calibrat.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 10, color: AppColors.neutral500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }
}
