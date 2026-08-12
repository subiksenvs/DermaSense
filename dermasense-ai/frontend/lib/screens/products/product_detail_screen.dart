import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../providers/favorites_provider.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;
  final int? matchScore;

  const ProductDetailScreen({super.key, required this.product, this.matchScore});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Details"),
        actions: [
          Consumer<FavoritesProvider>(
            builder: (context, favProvider, child) {
              final isFav = favProvider.isFavorite(product.id);
              return IconButton(
                icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.red : null),
                onPressed: () => favProvider.toggleFavorite(product.id),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.shopping_bag, size: 100, color: Theme.of(context).colorScheme.primary),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(product.brand, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                if (matchScore != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text('$matchScore% Match', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.secondary)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(product.name, style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 24)),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('\$${product.price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
                Icon(Icons.star, color: Colors.orange.shade400, size: 20),
                const SizedBox(width: 4),
                Text('${product.rating}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 24),
            Text(product.description, style: const TextStyle(fontSize: 16, height: 1.5)),
            const SizedBox(height: 32),
            
            const Text("Key Ingredients", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: product.keyIngredients.map((ing) => Chip(label: Text(ing))).toList(),
            ),
            const SizedBox(height: 24),

            const Text("Pros", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            ...product.pros.map((p) => _buildBulletPoint(p, Colors.green)),
            const SizedBox(height: 16),

            const Text("Cons", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            ...product.cons.map((c) => _buildBulletPoint(c, Colors.red)),
            
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to cart (Demo)')));
                },
                child: const Text("Buy Now"),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, size: 18, color: iconColor),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
