import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/skin_profile_provider.dart';
import '../products/product_list_screen.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<SkinProfileProvider>();
    // Mock image for demo purposes
    ImageProvider? imageProvider;

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
                color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.error.withValues(alpha: 0.5),
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
                      "DermaSense AI provides preliminary AI-assisted information and does not replace professional medical diagnosis. Please consult a qualified dermatologist for clinical evaluation.",
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Score Header
            Center(
              child: Column(
                children: [
                  const Text(
                    "Overall Skin Health",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: CircularProgressIndicator(
                          value: 0.82,
                          strokeWidth: 12,
                          backgroundColor: Colors.grey[200],
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Column(
                        children: [
                          Text(
                            "82",
                            style: Theme.of(context).textTheme.displayLarge
                                ?.copyWith(
                                  fontSize: 36,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                          const Text("Good"),
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
              "AI Screening Result (Possible Conditions)",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildMetricBar(context, "Acne", 0.78, "78%"),
            const SizedBox(height: 12),
            _buildMetricBar(context, "Pigmentation", 0.35, "35%"),

            const SizedBox(height: 32),

            // Skin Metrics
            const Text(
              "Skin Quality Metrics",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildMetricBar(context, "Hydration", 0.72, "72%"),
            const SizedBox(height: 12),
            _buildMetricBar(context, "Pores (Visibility)", 0.42, "42%"),
            const SizedBox(height: 12),
            _buildMetricBar(context, "Wrinkles", 0.18, "18%"),

            const SizedBox(height: 32),

            // Explainable AI heatmap placeholder
            const Text(
              "Explainable AI Analysis",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.grey[200],
                image: null,
              ),
              child: const Center(
                child: Text(
                  "Heatmap Overlay (Demo)",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Your skin is showing signs of moderate dehydration and early aging. Focus on hydration and sun protection.",
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 24),
            if (true) ...[
              const Text(
                "Recommended Products",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const SizedBox(height: 16),
              // We removed the old product Suggestions mapping because it used a custom model.
              // We'll replace it with a button leading to ProductListScreen or just leave a static message.
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ProductListScreen()));
                },
                icon: const Icon(Icons.shopping_bag),
                label: const Text("View Full Recommendations"),
              ),
              const SizedBox(height: 24),
            ],
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
