import '../models/product.dart';
import '../models/user_profile.dart';

class ProductRepository {
  static final List<Product> _products = [
    Product(
      id: 'p1',
      name: 'Hydrating Facial Cleanser',
      brand: 'CeraVe',
      category: 'Cleanser',
      price: 15.99,
      rating: 4.7,
      description:
          'CeraVe Hydrating Facial Cleanser is a gentle, non-foaming formula that effectively removes dirt and makeup while maintaining the skin\'s natural moisture barrier. Formulated with 3 essential ceramides and hyaluronic acid, it hydrates as it cleanses, leaving skin feeling soft and smooth without stripping or over-drying.',
      suitableSkinTypes: ['Dry', 'Normal', 'Sensitive'],
      targetedConcerns: ['Hydration', 'Redness'],
      keyIngredients: ['Ceramides 1, 3, 6-II', 'Hyaluronic Acid', 'MVE Technology'],
      pros: ['Non-foaming gentle formula', 'Fragrance-free', 'Dermatologist recommended', 'Affordable'],
      cons: ['May not remove heavy waterproof makeup', 'Can feel slightly slimy to some users'],
      isSustainable: false,
      imageUrl: 'https://m.media-amazon.com/images/I/61MKaPVfxZL._SL1000_.jpg',
      productUrl: 'https://www.amazon.com/s?k=CeraVe+Hydrating+Facial+Cleanser',
    ),
    Product(
      id: 'p2',
      name: 'Niacinamide 10% + Zinc 1%',
      brand: 'The Ordinary',
      category: 'Serum',
      price: 5.90,
      rating: 4.5,
      description:
          'This water-based serum from The Ordinary targets blemishes, enlarged pores, and uneven skin tone. With a high concentration of 10% Niacinamide (Vitamin B3) supported by 1% Zinc PCA, it helps regulate sebum production, minimise the appearance of pores, and brighten the complexion over time.',
      suitableSkinTypes: ['Oily', 'Combination', 'Normal'],
      targetedConcerns: ['Acne', 'Pores', 'Pigmentation'],
      keyIngredients: ['Niacinamide (Vitamin B3)', 'Zinc PCA'],
      pros: ['Extremely affordable', 'Reduces oiliness', 'Minimises pore appearance', 'Vegan & cruelty-free'],
      cons: ['Can pill under certain products', 'May cause initial purging in some users'],
      isSustainable: true,
      imageUrl: 'https://m.media-amazon.com/images/I/61Q4bFadGaL._SL1000_.jpg',
      productUrl: 'https://www.amazon.com/s?k=The+Ordinary+Niacinamide+10%25+%2B+Zinc+1%25',
    ),
    Product(
      id: 'p3',
      name: 'Toleriane Double Repair Face Moisturizer',
      brand: 'La Roche-Posay',
      category: 'Moisturizer',
      price: 22.99,
      rating: 4.7,
      description:
          'La Roche-Posay Toleriane Double Repair Face Moisturizer provides 48-hour hydration and helps restore the skin\'s natural protective barrier. Formulated with Ceramide-3, Niacinamide, and La Roche-Posay Prebiotic Thermal Water, this oil-free moisturizer is allergy-tested and suitable even for sensitive skin.',
      suitableSkinTypes: ['Normal', 'Dry', 'Sensitive', 'Combination'],
      targetedConcerns: ['Hydration', 'Redness'],
      keyIngredients: ['Ceramide-3', 'Niacinamide', 'Glycerin', 'Prebiotic Thermal Water'],
      pros: ['48-hour moisture', 'Oil-free', 'Fragrance-free', 'Suitable for sensitive skin'],
      cons: ['May feel heavy for very oily skin', 'Higher price than drugstore brands'],
      isSustainable: false,
      imageUrl: 'https://m.media-amazon.com/images/I/61rXnSEz3NL._SL1000_.jpg',
      productUrl: 'https://www.amazon.com/s?k=La+Roche-Posay+Toleriane+Double+Repair+Face+Moisturizer',
    ),
    Product(
      id: 'p4',
      name: 'Hyaluronic Acid 2% + B5',
      brand: 'The Ordinary',
      category: 'Serum',
      price: 6.80,
      rating: 4.6,
      description:
          'A water-based hydrating formula combining low, medium, and high molecular weight hyaluronic acid with a next-generation HA crosspolymer for multi-depth hydration. Vitamin B5 (Panthenol) enhances surface hydration, leaving skin plumped and dewy.',
      suitableSkinTypes: ['Dry', 'Normal', 'Combination', 'Sensitive'],
      targetedConcerns: ['Hydration', 'Wrinkles'],
      keyIngredients: ['Hyaluronic Acid (Multi-weight)', 'Vitamin B5 (Panthenol)'],
      pros: ['Budget-friendly', 'Multi-depth hydration', 'Fragrance-free', 'Layers well with other products'],
      cons: ['Can feel sticky in humid climates', 'Needs to be sealed with a moisturizer'],
      isSustainable: true,
      imageUrl: 'https://m.media-amazon.com/images/I/61S9mYSGw8L._SL1000_.jpg',
      productUrl: 'https://www.amazon.com/s?k=The+Ordinary+Hyaluronic+Acid+2%25+%2B+B5',
    ),
    Product(
      id: 'p5',
      name: 'Anthelios Melt-in Milk Sunscreen SPF 60',
      brand: 'La Roche-Posay',
      category: 'Sunscreen',
      price: 35.99,
      rating: 4.6,
      description:
          'A fast-absorbing, water-resistant sunscreen with broad-spectrum SPF 60 protection. Features Cell-Ox Shield® technology with antioxidants for advanced UVA/UVB protection. Suitable for face and body, it leaves a dry, non-greasy finish with no white cast.',
      suitableSkinTypes: ['Normal', 'Dry', 'Oily', 'Combination', 'Sensitive'],
      targetedConcerns: ['Pigmentation', 'Wrinkles'],
      keyIngredients: ['Cell-Ox Shield Technology', 'Vitamin E', 'La Roche-Posay Thermal Water'],
      pros: ['SPF 60 broad spectrum', 'No white cast', 'Water-resistant 80 min', 'Non-greasy finish'],
      cons: ['Chemical sunscreen (not mineral)', 'Contains fragrance'],
      isSustainable: false,
      imageUrl: 'https://m.media-amazon.com/images/I/61D3z5nQpcL._SL1000_.jpg',
      productUrl: 'https://www.amazon.com/s?k=La+Roche-Posay+Anthelios+Melt-in+Milk+Sunscreen+SPF+60',
    ),
    Product(
      id: 'p6',
      name: 'Salicylic Acid 2% Solution',
      brand: 'The Ordinary',
      category: 'Serum',
      price: 5.50,
      rating: 4.4,
      description:
          'This targeted exfoliant uses 2% Salicylic Acid to unclog pores and reduce acne and blemishes. As a BHA, it penetrates into pores to dissolve excess sebum and dead skin cell build-up. Ideal for acne-prone skin when used 2-3 times per week.',
      suitableSkinTypes: ['Oily', 'Combination'],
      targetedConcerns: ['Acne', 'Pores'],
      keyIngredients: ['Salicylic Acid (BHA)', 'Witch Hazel'],
      pros: ['Effective BHA exfoliant', 'Budget-friendly', 'Targets active breakouts', 'Vegan'],
      cons: ['Can be drying if overused', 'Not for sensitive or dry skin', 'May cause initial purging'],
      isSustainable: true,
      imageUrl: 'https://m.media-amazon.com/images/I/51sP3xH90YL._SL1000_.jpg',
      productUrl: 'https://www.amazon.com/s?k=The+Ordinary+Salicylic+Acid+2%25+Solution',
    ),
    Product(
      id: 'p7',
      name: 'Daily Moisturizing Lotion',
      brand: 'CeraVe',
      category: 'Moisturizer',
      price: 16.08,
      rating: 4.7,
      description:
          'A lightweight, oil-free daily moisturizing lotion with three essential ceramides and hyaluronic acid that provides 24-hour hydration. Features patented MVE Delivery Technology for controlled, long-lasting moisture release throughout the day.',
      suitableSkinTypes: ['Normal', 'Dry', 'Sensitive'],
      targetedConcerns: ['Hydration'],
      keyIngredients: ['Ceramides 1, 3, 6-II', 'Hyaluronic Acid', 'MVE Technology'],
      pros: ['24-hour hydration', 'Lightweight non-greasy', 'Fragrance-free', 'National Eczema Association accepted'],
      cons: ['May not be rich enough for extremely dry skin in winter'],
      isSustainable: false,
      imageUrl: 'https://m.media-amazon.com/images/I/617bU7V9TjL._SL1000_.jpg',
      productUrl: 'https://www.amazon.com/s?k=CeraVe+Daily+Moisturizing+Lotion',
    ),
    Product(
      id: 'p8',
      name: 'Vitamin C Suspension 23% + HA Spheres 2%',
      brand: 'The Ordinary',
      category: 'Serum',
      price: 5.80,
      rating: 4.3,
      description:
          'A highly potent Vitamin C treatment that brightens skin tone and fights signs of aging. Contains L-Ascorbic Acid in a silicone-free suspension for maximum stability. HA Spheres provide hydration while the high concentration of Vitamin C targets dullness and uneven tone.',
      suitableSkinTypes: ['Normal', 'Combination', 'Oily'],
      targetedConcerns: ['Pigmentation', 'Wrinkles'],
      keyIngredients: ['L-Ascorbic Acid (Vitamin C)', 'HA Spheres'],
      pros: ['High potency Vitamin C', 'Extremely affordable', 'Brightens complexion', 'Vegan'],
      cons: ['Gritty texture takes getting used to', 'Can tingle on sensitive skin', 'Silicone-free so doesn\'t feel silky'],
      isSustainable: true,
      imageUrl: 'https://m.media-amazon.com/images/I/616CvFMwJeL._SL1000_.jpg',
      productUrl: 'https://www.amazon.com/s?k=The+Ordinary+Vitamin+C+Suspension+23%25+%2B+HA+Spheres+2%25',
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
