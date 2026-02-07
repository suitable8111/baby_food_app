import 'package:cloud_firestore/cloud_firestore.dart';
import 'nutrition.dart';

/// 이유식 단계
enum BabyFoodStage {
  early,   // 초기 (4-6개월)
  middle,  // 중기 (7-9개월)
  late,    // 후기 (10-12개월)
}

extension BabyFoodStageExtension on BabyFoodStage {
  String get displayName {
    switch (this) {
      case BabyFoodStage.early:
        return '초기 (4-6개월)';
      case BabyFoodStage.middle:
        return '중기 (7-9개월)';
      case BabyFoodStage.late:
        return '후기 (10-12개월)';
    }
  }

  String get shortName {
    switch (this) {
      case BabyFoodStage.early:
        return '초기';
      case BabyFoodStage.middle:
        return '중기';
      case BabyFoodStage.late:
        return '후기';
    }
  }
}

/// 식재료 카테고리
enum IngredientCategory {
  grain,      // 곡물
  vegetable,  // 채소
  fruit,      // 과일
  protein,    // 단백질 (고기, 생선, 두부 등)
  dairy,      // 유제품
  other,      // 기타
}

extension IngredientCategoryExtension on IngredientCategory {
  String get displayName {
    switch (this) {
      case IngredientCategory.grain:
        return '곡물';
      case IngredientCategory.vegetable:
        return '채소';
      case IngredientCategory.fruit:
        return '과일';
      case IngredientCategory.protein:
        return '단백질';
      case IngredientCategory.dairy:
        return '유제품';
      case IngredientCategory.other:
        return '기타';
    }
  }
}

/// 식재료 모델
class Ingredient {
  final String id;
  final String name;
  final IngredientCategory category;
  final Nutrition nutritionPer100g;
  final List<BabyFoodStage> availableStages;
  final bool isAllergen;
  final String? allergenType;
  final String? description;

  const Ingredient({
    required this.id,
    required this.name,
    required this.category,
    required this.nutritionPer100g,
    required this.availableStages,
    this.isAllergen = false,
    this.allergenType,
    this.description,
  });

  /// 특정 그램수에 대한 영양소 계산
  Nutrition getNutritionForGrams(double grams) {
    return nutritionPer100g.multiply(grams / 100);
  }

  /// 특정 단계에서 사용 가능한지 확인
  bool isAvailableAt(BabyFoodStage stage) {
    return availableStages.contains(stage);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category.index,
      'nutritionPer100g': nutritionPer100g.toJson(),
      'availableStages': availableStages.map((s) => s.index).toList(),
      'isAllergen': isAllergen,
      'allergenType': allergenType,
      'description': description,
    };
  }

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: IngredientCategory.values[json['category'] ?? 0],
      nutritionPer100g: Nutrition.fromJson(json['nutritionPer100g'] ?? {}),
      availableStages: (json['availableStages'] as List<dynamic>?)
              ?.map((i) => BabyFoodStage.values[i as int])
              .toList() ??
          [],
      isAllergen: json['isAllergen'] ?? false,
      allergenType: json['allergenType'],
      description: json['description'],
    );
  }

  /// Firestore 문서에서 변환
  factory Ingredient.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Ingredient.fromJson({...data, 'id': doc.id});
  }
}

/// 레시피에서 사용되는 재료 (양 포함) - UI 표시용
class RecipeIngredient {
  final Ingredient ingredient;
  final double amount;
  final String? unit;

  const RecipeIngredient({
    required this.ingredient,
    required this.amount,
    this.unit = 'g',
  });

  Nutrition get nutrition => ingredient.getNutritionForGrams(amount);

  RecipeIngredient copyWith({double? amount}) {
    return RecipeIngredient(
      ingredient: ingredient,
      amount: amount ?? this.amount,
      unit: unit,
    );
  }
}
