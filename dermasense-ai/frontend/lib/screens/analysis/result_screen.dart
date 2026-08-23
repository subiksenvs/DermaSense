import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/skin_profile_provider.dart';
import '../products/product_list_screen.dart';

class ResultScreen extends StatelessWidget {
  final Map<String, dynamic>? scanResult;
  final Uint8List? originalImage;

  const ResultScreen({super.key, this.scanResult, this.originalImage});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<SkinProfileProvider>();

    final scores = scanResult?['scores'] as Map<String, dynamic>? ?? {};
    final overlays = scanResult?['overlays'] as Map<String, dynamic>? ?? {};

    // Calculate an average health score if scores exist
    double overallScore = 0.0;
    if (scores.isNotEmpty) {
      // Invert negative metrics (e.g. higher redness is worse) for a general score,
      // or simply average them. Here we'll do a simple average for demo purposes.
      double sum = 0;
      for (var v in scores.values) {
        sum += (1.0 - (v as double));
      } // Assume lower is better for most
      overallScore = sum / scores.length;
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Analysis Results")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Disclaimer
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.error.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "This AI skin analysis is for informational purposes only and is not a medical diagnosis. Please consult a qualified dermatologist for clinical evaluation.",
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Original Image Display
            if (originalImage != null) ...[
              const Text(
                "Original Scan",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.black,
                  image: DecorationImage(
                    image: MemoryImage(originalImage!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],

            // Score Header
            if (scores.isNotEmpty)
              Center(
                child: Column(
                  children: [
                    const Text(
                      "Overall Skin Health",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: CircularProgressIndicator(
                            value: overallScore,
                            strokeWidth: 12,
                            backgroundColor: Colors.grey[200],
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        Column(
                          children: [
                            Text(
                              "${(overallScore * 100).toInt()}",
                              style: Theme.of(context).textTheme.displayLarge
                                  ?.copyWith(
                                    fontSize: 36,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                            ),
                            const Text("Score"),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 32),

            // AI Screening Results
            const Text(
              "AI Screening Result",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            if (scores.isNotEmpty) ...[
              if (scores.containsKey('redness'))
                _buildMetricBar(
                  context,
                  "Redness",
                  scores['redness'],
                  "${(scores['redness'] * 100).toInt()}%",
                ),
              const SizedBox(height: 12),
              if (scores.containsKey('oiliness'))
                _buildMetricBar(
                  context,
                  "Oiliness",
                  scores['oiliness'],
                  "${(scores['oiliness'] * 100).toInt()}%",
                ),
              const SizedBox(height: 12),
              if (scores.containsKey('texture'))
                _buildMetricBar(
                  context,
                  "Texture",
                  scores['texture'],
                  "${(scores['texture'] * 100).toInt()}%",
                ),
              const SizedBox(height: 12),
              if (scores.containsKey('pores'))
                _buildMetricBar(
                  context,
                  "Pores",
                  scores['pores'],
                  "${(scores['pores'] * 100).toInt()}%",
                ),
              const SizedBox(height: 12),
              if (scores.containsKey('blemishes'))
                _buildMetricBar(
                  context,
                  "Blemishes",
                  scores['blemishes'],
                  "${(scores['blemishes'] * 100).toInt()}%",
                ),
              const SizedBox(height: 12),
              if (scores.containsKey('hydration'))
                _buildMetricBar(
                  context,
                  "Hydration",
                  scores['hydration'],
                  "${(scores['hydration'] * 100).toInt()}%",
                ),
              const SizedBox(height: 12),
              if (scores.containsKey('pigment'))
                _buildMetricBar(
                  context,
                  "Pigmentation",
                  scores['pigment'],
                  "${(scores['pigment'] * 100).toInt()}%",
                ),
            ] else ...[
              const Text("No metrics available."),
            ],

            const SizedBox(height: 32),

            // Explainable AI heatmap
            const Text(
              "Explainable AI Analysis",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (overlays.isNotEmpty && overlays.containsKey('redness'))
              Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.black,
                  image: DecorationImage(
                    image: MemoryImage(
                      base64Decode(
                        (overlays['redness'] as String).split(',').last,
                      ),
                    ),
                    fit: BoxFit.contain,
                  ),
                ),
              )
            else
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.grey[200],
                ),
                child: const Center(
                  child: Text(
                    "No Heatmap Available",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProductListScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.shopping_bag),
              label: const Text("View Full Recommendations"),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Save & View Routine"),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricBar(
    BuildContext context,
    String label,
    double value,
    String percentage,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text(
              percentage,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: value,
          backgroundColor: Colors.grey[200],
          color: Theme.of(context).colorScheme.primary,
          minHeight: 10,
          borderRadius: BorderRadius.circular(5),
        ),
      ],
    );
  }
}
