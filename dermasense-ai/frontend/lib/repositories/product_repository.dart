import '../models/product.dart';
import '../models/user_profile.dart';

class ProductRepository {
  static final List<Product> _products = [
    Product(
      id: 'p1',
      name: 'HydraBoost Hyaluronic Serum',
      brand: 'AquaDerma',
      category: 'Serum',
      price: 45.0,
      rating: 4.8,
      description: 'A deeply hydrating serum with 2% pure hyaluronic acid and B5 to plump skin and lock in moisture.',
      suitableSkinTypes: ['Dry', 'Normal', 'Combination', 'Sensitive'],
      targetedConcerns: ['Hydration', 'Wrinkles'],
      keyIngredients: ['Hyaluronic Acid', 'Vitamin B5', 'Glycerin'],
      pros: ['Fast absorbing', 'Fragrance-free', 'Intensely hydrating'],
      cons: ['Slightly tacky finish initially'],
      isSustainable: true,
    ),
    Product(
      id: 'p2',
      name: 'ClearSkin Salicylic Acid Cleanser',
      brand: 'MediPore',
      category: 'Cleanser',
      price: 28.5,
      rating: 4.6,
      description: 'Gentle exfoliating cleanser with 2% BHA to clear out pores and prevent acne breakouts.',
      suitableSkinTypes: ['Oily', 'Combination'],
      targetedConcerns: ['Acne', 'Pores'],
      keyIngredients: ['Salicylic Acid (BHA)', 'Niacinamide', 'Ceramides'],
      pros: ['Unclogs pores effectively', 'Non-drying'],
      cons: ['May cause purging initially', 'Not for very dry skin'],
      isSustainable: false,
    ),
    Product(
      id: 'p3',
      name: 'Radiance C+ Brightening Cream',
      brand: 'GlowVital',
      category: 'Moisturizer',
      price: 65.0,
      rating: 4.7,
      description: 'Antioxidant-rich daily moisturizer that evens skin tone and fights free radical damage.',
      suitableSkinTypes: ['Normal', 'Dry', 'Combination'],
      targetedConcerns: ['Pigmentation', 'Wrinkles'],
      keyIngredients: ['Vitamin C', 'Vitamin E', 'Ferulic Acid'],
      pros: ['Brightens complexion', 'Lightweight texture'],
      cons: ['Higher price point', 'Vitamin C can oxidize if exposed to light'],
      isSustainable: true,
    ),
    Product(
      id: 'p4',
      name: 'CalmRestore Oat Gel',
      brand: 'SensiCare',
      category: 'Moisturizer',
      price: 32.0,
      rating: 4.9,
      description: 'Cooling gel moisturizer designed to soothe redness and restore the skin barrier.',
      suitableSkinTypes: ['Sensitive', 'Oily', 'Combination'],
      targetedConcerns: ['Redness', 'Hydration'],
      keyIngredients: ['Prebiotic Oat', 'Feverfew', 'Panthenol'],
      pros: ['Instantly soothing', 'Great for damaged barriers', 'Very gentle'],
      cons: ['Not moisturizing enough for extremely dry skin'],
      isSustainable: true,
    ),
    Product(
      id: 'p5',
      name: 'Ultra UV Defense SPF 50+',
      brand: 'SunShield',
      category: 'Sunscreen',
      price: 38.0,
      rating: 4.5,
      description: 'Invisible finish broad-spectrum sunscreen that leaves no white cast.',
      suitableSkinTypes: ['Normal', 'Dry', 'Oily', 'Combination', 'Sensitive'],
      targetedConcerns: ['Pigmentation', 'Wrinkles'],
      keyIngredients: ['Zinc Oxide', 'Titanium Dioxide', 'Aloe Vera'],
      pros: ['No white cast', 'Water-resistant', 'Reef safe'],
      cons: ['Can feel slightly heavy on very oily skin'],
      isSustainable: true,
    ),
  ];

  static List<Product> getAllProducts() {
    return _products;
  }

  /// Advanced scoring engine for personalized product recommendation
  static List<Map<String, dynamic>> getRecommendations(UserProfile profile) {
    List<Map<String, dynamic>> scoredProducts = [];

    for (var product in _products) {
      double score = 0.0;
      List<String> reasons = [];

      // 1. Skin Type Match (High Priority: 40 points)
      if (profile.skinType != null && product.suitableSkinTypes.contains(profile.skinType)) {
        score += 40;
        reasons.add('Perfectly matches your ${profile.skinType} skin type');
      }

      // 2. Concerns Match (High Priority: 30 points)
      int matchedConcerns = 0;
      for (var concern in profile.skinConcerns) {
        if (product.targetedConcerns.contains(concern)) {
          matchedConcerns++;
          score += (30 / profile.skinConcerns.length); // Distribute 30 points
        }
      }
      if (matchedConcerns > 0) {
        reasons.add('Targets your key concern: ${profile.skinConcerns.join(", ")}');
      }

      // 3. Budget Fit (Medium Priority: 20 points)
      if (profile.budget != null) {
        if (product.price <= profile.budget!) {
          score += 20;
          reasons.add('Fits well within your monthly budget');
        } else if (product.price <= profile.budget! * 1.2) {
          score += 10;
          reasons.add('Slightly over budget, but high value');
        }
      } else {
        score += 20; // If no budget, assume it fits
      }

      // 4. Product Quality/Rating (Low Priority: 10 points)
      score += (product.rating / 5.0) * 10;

      // Compile result
      if (score > 40) { // Only recommend if score is decent
        scoredProducts.add({
          'product': product,
          'score': score.clamp(0, 100).toInt(),
          'reasons': reasons,
        });
      }
    }

    // Sort by highest score
    scoredProducts.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
    
    return scoredProducts;
  }

  static List<Product> searchProducts(String query) {
    if (query.isEmpty) return _products;
    final lowerQuery = query.toLowerCase();
    return _products.where((p) {
      return p.name.toLowerCase().contains(lowerQuery) ||
             p.brand.toLowerCase().contains(lowerQuery) ||
             p.targetedConcerns.any((c) => c.toLowerCase().contains(lowerQuery));
    }).toList();
  }
}
