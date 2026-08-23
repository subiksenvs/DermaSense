import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'result_screen.dart';
import '../../services/analysis_service.dart';

class LiveCameraScreen extends StatefulWidget {
  const LiveCameraScreen({super.key});

  @override
  State<LiveCameraScreen> createState() => _LiveCameraScreenState();
}

class _LiveCameraScreenState extends State<LiveCameraScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  bool _isInitializing = true;
  bool _isAnalyzing = false;
  late AnimationController _scannerController;
  late Animation<double> _scannerAnimation;
  Timer? _analysisTimer;

  @override
  void initState() {
    super.initState();
    _initCamera();

    _scannerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _scannerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scannerController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception("No cameras available");
      }

      // Prefer front camera for selfies
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to initialize camera: $e")),
        );
        Navigator.pop(context);
      }
    }
  }

  void _startAnalysis() async {
    setState(() {
      _isAnalyzing = true;
    });

    _scannerController.repeat(reverse: true);

    try {
      if (_cameraController == null ||
          !_cameraController!.value.isInitialized) {
        throw Exception("Camera not ready");
      }

      // Capture a photo
      final XFile file = await _cameraController!.takePicture();
      final bytes = await file.readAsBytes();

      // Send to backend
      final result = await AnalysisService.analyzeSkin(bytes, 'live_scan.jpg');
      await AnalysisService.saveScanToHistory(result);

      if (mounted) {
        _scannerController.stop();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ResultScreen(scanResult: result, originalImage: bytes),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _scannerController.stop();
        setState(() {
          _isAnalyzing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Analysis failed: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _analysisTimer?.cancel();
    _scannerController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            "Camera not available",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera Preview
          Center(
            child: AspectRatio(
              aspectRatio: 1 / _cameraController!.value.aspectRatio,
              child: CameraPreview(_cameraController!),
            ),
          ),

          // Scanning Overlay
          if (_isAnalyzing)
            AnimatedBuilder(
              animation: _scannerAnimation,
              builder: (context, child) {
                return Positioned(
                  top:
                      MediaQuery.of(context).size.height * 0.2 +
                      (MediaQuery.of(context).size.height *
                          0.5 *
                          _scannerAnimation.value),
                  left: 24,
                  right: 24,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary,
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          // Face Guide (Oval)
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.7,
              height: MediaQuery.of(context).size.height * 0.5,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _isAnalyzing
                      ? Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.5),
                  width: 3,
                ),
                borderRadius: BorderRadius.all(
                  Radius.elliptical(
                    MediaQuery.of(context).size.width * 0.35,
                    MediaQuery.of(context).size.height * 0.25,
                  ),
                ),
              ),
            ),
          ),

          // Top Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 32),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Bottom Controls
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  _isAnalyzing ? "Analyzing..." : "",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                  ),
                ),
                const SizedBox(height: 24),
                if (!_isAnalyzing)
                  GestureDetector(
                    onTap: _startAnalysis,
                    child: Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: Center(
                        child: Container(
                          height: 60,
                          width: 60,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.document_scanner,
                            color: Colors.white,
                            size: 32,
                          ),
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
