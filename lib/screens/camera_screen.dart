import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/plant_model_service.dart';
import 'confirm_plant_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

enum _Status { requestingPermission, permissionDenied, initializing, ready, noCamera, classifying }

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  _Status _status = _Status.requestingPermission;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setup();
  }

  Future<void> _setup() async {
    final permission = await Permission.camera.request();
    if (!permission.isGranted) {
      setState(() => _status = _Status.permissionDenied);
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

  Future<void> _onCapture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    setState(() => _status = _Status.classifying);
    try {
      final xfile = await controller.takePicture();
      final docsDir = await getApplicationDocumentsDirectory();
      final fileName = 'plant_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedPath = p.join(docsDir.path, fileName);
      await File(xfile.path).copy(savedPath);

      await PlantModelService.instance.load();
      final predictions = await PlantModelService.instance.classifyImageFile(File(savedPath));

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ConfirmPlantScreen(photoPath: savedPath, predictions: predictions),
        ),
      );
    } finally {
      if (mounted) setState(() => _status = _Status.ready);
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
                  const Text(
                    'Aplicația are nevoie de acces la cameră pentru a identifica plantele.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: _setup, child: const Text('Permite accesul la cameră')),
                ],
              ),
            ),
          ),
        );
      case _Status.noCamera:
        return const Scaffold(body: Center(child: Text('Nu s-a găsit nicio cameră disponibilă.')));
      case _Status.ready:
      case _Status.classifying:
        final controller = _controller!;
        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              CameraPreview(controller),
              if (_status == _Status.classifying)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 12),
                        Text('Se identifică planta...', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: _status == _Status.ready ? _onCapture : null,
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: Center(
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                        ),
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
