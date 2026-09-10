import 'dart:convert';
import 'package:flutter/material.dart';
import '../../widgets/glass_app_bar_title.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/ai_service.dart';
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
  List<Map<String, dynamic>> _geminiProducts = [];
  bool _isFetchingGemini = false;
  bool _hasFetchedGemini = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchGeminiProducts();
    });
  }

  Future<void> _fetchGeminiProducts() async {
    if (!mounted || _hasFetchedGemini) return;

    final profile = Provider.of<SkinProfileProvider>(
      context,
      listen: false,
    ).profile;

    setState(() {
      _isFetchingGemini = true;
      _hasFetchedGemini = true;
    });

    final skinType = profile.skinType ?? "Unknown";
    final concerns = profile.skinConcerns.join(", ");

    final prompt =
        """
    Generate exactly 3 real-world skincare product recommendations for a person with $skinType skin and concerns: $concerns.
    Return ONLY a raw JSON array of objects. Do not include markdown formatting like ```json.
    Each object MUST have these exact string keys: "id" (a unique string), "name", "brand", "category", "description", "imageUrl", "productUrl".
    Also include "price" (number), "rating" (number).
    For "imageUrl", use a generic placeholder like 'https://via.placeholder.com/150' if you don't know the real one.
    """;

    try {
      final rawText = await AiService().generateText(
        prompt: prompt,
        systemInstruction: "You are a dermatology skincare specialist recommending real-world products in strict JSON format.",
      );

      final jsonStr = AiService.cleanJson(rawText);
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      final List<Map<String, dynamic>> newProducts = [];

      for (var p in jsonList) {
        final product = Product(
          id:
              p['id']?.toString() ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          name: p['name']?.toString() ?? "Unknown Product",
          brand: p['brand']?.toString() ?? "Unknown Brand",
          category: p['category']?.toString() ?? "Skincare",
          price: (p['price'] as num?)?.toDouble() ?? 15.0,
          rating: (p['rating'] as num?)?.toDouble() ?? 4.5,
          description: p['description']?.toString() ?? "AI Recommended Product",
          suitableSkinTypes: [skinType],
          targetedConcerns: profile.skinConcerns,
          keyIngredients: [],
          pros: [],
          cons: [],
          isSustainable: false,
          imageUrl:
              p['imageUrl']?.toString() ?? "https://via.placeholder.com/150",
          productUrl: p['productUrl']?.toString() ?? "",
        );
        newProducts.add({
          'product': product,
          'score': 95, // AI Match
          'reasons': ["AI Recommended based on your profile"],
        });
      }

      if (mounted) {
        setState(() {
          _geminiProducts = newProducts;
          _isFetchingGemini = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFetchingGemini = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const GlassAppBarTitle(
          icon: Icons.shopping_bag_outlined,
          title: "Skincare Products",
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search products or brands...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
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
                  displayedItems = ProductRepository.getRecommendations(
                    profileProvider.profile,
                  );
                  // Append Gemini products
                  displayedItems.addAll(_geminiProducts);
                } else {
                  final all = ProductRepository.searchProducts(_searchQuery);
                  displayedItems = all
                      .map((p) => {'product': p, 'score': null, 'reasons': []})
                      .toList();
                }

                if (displayedItems.isEmpty && !_isFetchingGemini) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount:
                      displayedItems.length + (_isFetchingGemini ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == displayedItems.length) {
                      return Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(
                              "AI is finding more products for you...",
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final item = displayedItems[index];
                    final Product product = item['product'];
                    final int? score = item['score'];
                    final isFavorite = favoritesProvider.isFavorite(product.id);

                    return _buildProductCard(
                      context,
                      product,
                      score,
                      isFavorite,
                      favoritesProvider,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    Product product,
    int? score,
    bool isFavorite,
    FavoritesProvider favProvider,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ProductDetailScreen(product: product, matchScore: score),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image from network
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: product.imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.shopping_bag,
                      size: 40,
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
                      product.brand,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$${product.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              size: 14,
                              color: Colors.orange.shade400,
                            ),
                            Text(
                              product.rating.toString(),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (score != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.secondary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$score% Match',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
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
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade600),
          const SizedBox(height: 16),
          const Text(
            "No products found.",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            "Try adjusting your search or filters.",
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
