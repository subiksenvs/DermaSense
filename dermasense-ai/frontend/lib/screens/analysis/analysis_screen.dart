import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/animated_gradient_button.dart';
import 'result_screen.dart';
import 'live_camera_screen.dart';
import '../../services/analysis_service.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  Uint8List? _imageData;
  final ImagePicker _picker = ImagePicker();
  bool _isAnalyzing = false;

  Future<void> _getImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageData = bytes;
      });
    }
  }

  void _startAnalysis() async {
    if (_imageData == null) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final result = await AnalysisService.analyzeSkin(_imageData!, 'scan.jpg');
      await AnalysisService.saveScanToHistory(result);

      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
      });

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ResultScreen(
          scanResult: result,
          originalImage: _imageData,
        )),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Skin Analysis"),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Capture or Upload",
                style: Theme.of(
                  context,
                ).textTheme.displayMedium?.copyWith(fontSize: 24),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "For best results, use good lighting and remove makeup.",
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Expanded(
                child: GlassCard(
                  padding: EdgeInsets.zero,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: _imageData == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.face_retouching_natural,
                                size: 80,
                                color: AppTheme.primaryColor.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 16),
                              Text("No image selected", style: TextStyle(color: AppTheme.textSecondary)),
                            ],
                          )
                        : Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: Image.memory(
                                  _imageData!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              if (_isAnalyzing)
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const CircularProgressIndicator(
                                        color: AppTheme.secondaryColor,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        "Analyzing your skin...",
                                        style: TextStyle(
                                          color: AppTheme.secondaryColor,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.photo_library),
                      label: const Text("Gallery"),
                      onPressed: _isAnalyzing ? null : () => _getImage(ImageSource.gallery),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.camera_alt),
                      label: const Text("Camera"),
                      onPressed: _isAnalyzing ? null : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LiveCameraScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              AnimatedGradientButton(
                text: "Scan Now",
                icon: Icons.auto_awesome,
                onPressed: _imageData == null ? () {} : _startAnalysis,
                isLoading: _isAnalyzing,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
