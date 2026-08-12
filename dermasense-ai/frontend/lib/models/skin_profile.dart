import 'package:flutter/material.dart';

enum SkinType { normal, dry, oily, combination, sensitive }

extension SkinTypeExtension on SkinType {
  String get displayName {
    switch (this) {
      case SkinType.normal:
        return 'Normal';
      case SkinType.dry:
        return 'Dry';
      case SkinType.oily:
        return 'Oily';
      case SkinType.combination:
        return 'Combination';
      case SkinType.sensitive:
        return 'Sensitive';
    }
  }

  IconData get icon {
    switch (this) {
      case SkinType.normal:
        return Icons.spa;
      case SkinType.dry:
        return Icons.wb_sunny_outlined;
      case SkinType.oily:
        return Icons.opacity;
      case SkinType.combination:
        return Icons.brightness_3;
      case SkinType.sensitive:
        return Icons.shield;
    }
  }
}

class ProductSuggestion {
  final String name;
  final String description;
  final IconData icon;

  const ProductSuggestion({
    required this.name,
    required this.description,
    required this.icon,
  });
}
