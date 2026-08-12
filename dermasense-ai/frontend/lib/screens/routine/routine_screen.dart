import 'package:flutter/material.dart';
import '../products/product_list_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/skin_profile_provider.dart';

class RoutineScreen extends StatelessWidget {
  const RoutineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<SkinProfileProvider>();
    final skinTypeLabel = profile.profile.skinType?.toLowerCase() ?? 'normal';

    return Scaffold(
      appBar: AppBar(title: const Text("Personalized Routine")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Your Recommended Routine",
              style: Theme.of(
                context,
              ).textTheme.displayMedium?.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 8),
            Text(
              "Based on your recent analysis and $skinTypeLabel skin profile.",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            const Text(
              "Morning",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildRoutineStep(
              context,
              "1",
              "Gentle Cleanser",
              "Removes overnight impurities without stripping moisture.",
              Icons.wash,
            ),
            const SizedBox(height: 12),
            _buildRoutineStep(
              context,
              "2",
              "Vitamin C Serum",
              "Targets pigmentation and brightens skin.",
              Icons.science,
            ),
            const SizedBox(height: 12),
            _buildRoutineStep(
              context,
              "3",
              "Hydrating Moisturizer",
              "Addresses your dehydration concern.",
              Icons.water_drop,
            ),
            const SizedBox(height: 12),
            _buildRoutineStep(
              context,
              "4",
              "Broad Spectrum SPF 50+",
              "Essential protection against UV damage.",
              Icons.wb_sunny,
            ),
            const SizedBox(height: 32),
            const Text(
              "Evening",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildRoutineStep(
              context,
              "1",
              "Double Cleanse",
              "Removes sunscreen and daily buildup.",
              Icons.wash,
            ),
            const SizedBox(height: 12),
            _buildRoutineStep(
              context,
              "2",
              "Salicylic Acid Treatment",
              "Helps clear pores and reduce mild acne.",
              Icons.healing,
            ),
            const SizedBox(height: 12),
            _buildRoutineStep(
              context,
              "3",
              "Rich Night Cream",
              "Repairs skin barrier overnight.",
              Icons.nightlight_round,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ProductListScreen()));
                },
                icon: const Icon(Icons.shopping_bag),
                label: const Text("View Personalized Products"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutineStep(
    BuildContext context,
    String step,
    String title,
    String description,
    IconData icon,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
                              child: Center(
                                child: Text(
                                  step,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(icon, color: Theme.of(context).colorScheme.secondary),
          ],
        ),
      ),
    );
  }
}
