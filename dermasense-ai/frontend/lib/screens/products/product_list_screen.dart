import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../repositories/product_repository.dart';
import '../../providers/skin_profile_provider.dart';
import '../../providers/favorites_provider.dart';
import 'product_detail_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  String _searchQuery = "";
  bool _showOnlyRecommended = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Skincare Products"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search products or brands...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                FilterChip(
                  label: const Text("Recommended For Me"),
                  selected: _showOnlyRecommended,
                  onSelected: (val) {
                    setState(() {
                      _showOnlyRecommended = val;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Consumer2<SkinProfileProvider, FavoritesProvider>(
              builder: (context, profileProvider, favoritesProvider, child) {
                if (profileProvider.isLoading || favoritesProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                List<Map<String, dynamic>> displayedItems = [];

                if (_showOnlyRecommended && _searchQuery.isEmpty) {
                  displayedItems = ProductRepository.getRecommendations(profileProvider.profile);
                } else {
                  final all = ProductRepository.searchProducts(_searchQuery);
                  displayedItems = all.map((p) => {'product': p, 'score': null, 'reasons': []}).toList();
                }

                if (displayedItems.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: displayedItems.length,
                  itemBuilder: (context, index) {
                    final item = displayedItems[index];
                    final Product product = item['product'];
                    final int? score = item['score'];
                    final isFavorite = favoritesProvider.isFavorite(product.id);

                    return _buildProductCard(context, product, score, isFavorite, favoritesProvider);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product, int? score, bool isFavorite, FavoritesProvider favProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => ProductDetailScreen(product: product, matchScore: score)));
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.shopping_bag, size: 40, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.brand, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('\$${product.price.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                        Row(
                          children: [
                            Icon(Icons.star, size: 14, color: Colors.orange.shade400),
                            Text(product.rating.toString(), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          ],
                        ),
                      ],
                    ),
                    if (score != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('$score% Match', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.secondary)),
                      )
                    ]
                  ],
                ),
              ),
              IconButton(
                icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: isFavorite ? Colors.red : Colors.grey),
                onPressed: () {
                  favProvider.toggleFavorite(product.id);
                },
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("No products found.", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          Text("Try adjusting your search or filters.", style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}
