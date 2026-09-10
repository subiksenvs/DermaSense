import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ds/ds_card.dart';
import '../../widgets/ds/ds_button.dart';
import '../../services/analysis_service.dart';
import '../../providers/history_provider.dart';
import '../../providers/skin_profile_provider.dart';
import '../../providers/routine_provider.dart';
import 'result_screen.dart';
import 'live_camera_screen.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  Uint8List? _imageData;
  final ImagePicker _picker = ImagePicker();
  bool _isAnalyzing = false;
  String _analysisStep = "Initializing...";

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

    // Capture providers before any await so they are safe to use later.
    final historyProvider = context.read<HistoryProvider>();
    final profileProvider = context.read<SkinProfileProvider>();
    final routineProvider = context.read<RoutineProvider>();

    setState(() {
      _isAnalyzing = true;
      _analysisStep = "Running AI clinical diagnostic scan...";
    });

    try {
      // Fire analysis immediately without artificial delays for instant response
      final result = await AnalysisService.analyzeSkin(_imageData!, 'scan.jpg');

      final scores = result['scores'] as Map<String, dynamic>? ?? {};
      double overallScore = 85.0;
      Map<String, double> metrics = {};

      if (scores.isNotEmpty) {
        // Clinical weighted composite health score (0-100 scale)
        final weights = <String, double>{
          'acne_severity': 1.6,
          'blemishes': 1.3,
          'redness': 1.3,
          'barrier_health': 1.4,
          'wrinkles': 1.2,
          'sun_damage': 1.1,
          'dark_circles': 0.9,
          'eye_bags': 0.8,
          'pore_dilation': 0.9,
          'pores': 0.8,
          'texture': 0.9,
          'tone_evenness': 1.0,
          'oiliness': 0.8,
          'pigment': 1.1,
          'firmness': 1.0,
          'radiance': 0.9,
          'hydration': 1.0,
        };

        double totalWeight = 0.0;
        double weightedPenalty = 0.0;

        for (var entry in scores.entries) {
          double val = (entry.value as num).toDouble();
          metrics[entry.key] = val;

          // For hydration, higher value is good, so penalty is (1 - val)
          double penalty = (entry.key == 'hydration') ? (1.0 - val) : val;
          double weight = weights[entry.key] ?? 1.0;

          weightedPenalty += penalty * weight;
          totalWeight += weight;
        }

        if (totalWeight > 0) {
          double avgPenalty = weightedPenalty / totalWeight;
          overallScore = ((1.0 - avgPenalty) * 100.0).clamp(10.0, 99.0);
        }
      }

      final record = AnalysisRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: DateTime.now(),
        overallScore: overallScore.round(),
        imagePath: '',
        conditions: {},
        metrics: metrics,
      );

      if (mounted) {
        await historyProvider.addRecord(record);
        routineProvider.generateRoutine(historyProvider, profileProvider, force: true);
      }

      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
      });

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(scanResult: result, originalImage: _imageData),
        ),
      );

      if (mounted) {
        setState(() {
          _imageData = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Skin Analysis"),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_imageData == null) ...[
                Text(
                  "Capture or Upload",
                  style: Theme.of(context).textTheme.headlineLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.space8),
                Text(
                  "For best results, use good lighting and remove makeup.",
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.space32),
              ],
              Expanded(
                child: DSCard(
                  padding: EdgeInsets.zero,
                  variant: DSCardVariant.base,
                  child: ClipRRect(
                    borderRadius: AppTheme.borderRadiusLarge,
                    child: _imageData == null
                        ? _buildPlaceholder()
                        : _buildImagePreview(),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.space32),
              if (_imageData == null)
                Row(
                  children: [
                    Expanded(
                      child: DSButton(
                        variant: DSButtonVariant.outline,
                        icon: Icons.photo_library_outlined,
                        label: "Gallery",
                        onPressed: () => _getImage(ImageSource.gallery),
                      ),
                    ),
                    const SizedBox(width: AppTheme.space16),
                    Expanded(
                      child: DSButton(
                        variant: DSButtonVariant.primary,
                        icon: Icons.camera_alt_outlined,
                        label: "Camera",
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LiveCameraScreen()),
                        ),
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    if (!_isAnalyzing)
                      DSButton(
                        variant: DSButtonVariant.text,
                        icon: Icons.refresh,
                        label: "Retake photo",
                        onPressed: () => setState(() => _imageData = null),
                      ),
                    const SizedBox(height: AppTheme.space16),
                    DSButton(
                      variant: DSButtonVariant.primary,
                      icon: Icons.auto_awesome,
                      label: _isAnalyzing ? _analysisStep : "Analyze Skin",
                      isLoading: _isAnalyzing,
                      onPressed: _isAnalyzing ? null : _startAnalysis,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.face_retouching_natural, size: 80, color: AppTheme.textSecondary.withValues(alpha: 0.3)),
        const SizedBox(height: AppTheme.space24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.space40),
          child: Column(
            children: [
              _buildInstructionRow(Icons.light_mode_outlined, "Find a well-lit area"),
              const SizedBox(height: AppTheme.space12),
              _buildInstructionRow(Icons.cleaning_services_outlined, "Remove makeup/glasses"),
              const SizedBox(height: AppTheme.space12),
              _buildInstructionRow(Icons.face_outlined, "Keep face relaxed"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryLight, size: 20),
        const SizedBox(width: AppTheme.space12),
        Text(text, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.memory(
          _imageData!,
          fit: BoxFit.cover,
        ),
        if (_isAnalyzing)
          Container(
            color: Colors.black.withValues(alpha: 0.7),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: AppTheme.primary),
                const SizedBox(height: AppTheme.space24),
                Text(
                  _analysisStep,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
