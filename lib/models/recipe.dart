import 'ingredient.dart';
import 'nutrition.dart';

/// 조리 난이도
enum Difficulty {
  easy,    // 쉬움
  medium,  // 보통
  hard,    // 어려움
}

extension DifficultyExtension on Difficulty {
  String get displayName {
    switch (this) {
      case Difficulty.easy:
        return '쉬움';
      case Difficulty.medium:
        return '보통';
      case Difficulty.hard:
        return '어려움';
    }
  }
}

/// 레시피 모델
class Recipe {
  final String id;
  final String name;
  final BabyFoodStage stage;
  final List<RecipeIngredient> ingredients;
  final List<String> steps; // 조리 단계
  final int cookingTimeMinutes; // 조리 시간 (분)
  final Difficulty difficulty;
  final String? imageUrl;
  final String? storageInfo; // 보관 정보
  final String? tip; // 조리 팁
  final bool isFavorite;

  const Recipe({
    required this.id,
    required this.name,
    required this.stage,
    required this.ingredients,
    required this.steps,
    required this.cookingTimeMinutes,
    this.difficulty = Difficulty.easy,
    this.imageUrl,
    this.storageInfo,
    this.tip,
    this.isFavorite = false,
  });

  /// 총 영양소 계산
  Nutrition get totalNutrition {
    if (ingredients.isEmpty) return Nutrition.empty;
    return ingredients.fold<Nutrition>(
      Nutrition.empty,
      (sum, item) => sum + item.nutrition,
    );
  }

  /// 1회 제공량 영양소 (기본 1회)
  Nutrition get perServingNutrition => totalNutrition;

  /// 알레르기 유발 재료 목록
  List<Ingredient> get allergens {
    return ingredients
        .where((ri) => ri.ingredient.isAllergen)
        .map((ri) => ri.ingredient)
        .toList();
  }

  /// 알레르기 유발 재료 있는지 확인
  bool get hasAllergens => allergens.isNotEmpty;

  /// 즐겨찾기 토글
  Recipe toggleFavorite() {
    return Recipe(
      id: id,
      name: name,
      stage: stage,
      ingredients: ingredients,
      steps: steps,
      cookingTimeMinutes: cookingTimeMinutes,
      difficulty: difficulty,
      imageUrl: imageUrl,
      storageInfo: storageInfo,
      tip: tip,
      isFavorite: !isFavorite,
    );
  }

  /// 재료 수정된 레시피 반환
  Recipe copyWithIngredients(List<RecipeIngredient> newIngredients) {
    return Recipe(
      id: id,
      name: name,
      stage: stage,
      ingredients: newIngredients,
      steps: steps,
      cookingTimeMinutes: cookingTimeMinutes,
      difficulty: difficulty,
      imageUrl: imageUrl,
      storageInfo: storageInfo,
      tip: tip,
      isFavorite: isFavorite,
    );
  }
}

/// 커스텀 레시피 (사용자가 만든 레시피)
class CustomRecipe extends Recipe {
  final DateTime createdAt;
  final DateTime? updatedAt;

  CustomRecipe({
    required super.id,
    required super.name,
    required super.stage,
    required super.ingredients,
    super.steps = const [],
    super.cookingTimeMinutes = 0,
    super.difficulty,
    super.imageUrl,
    super.storageInfo,
    super.tip,
    super.isFavorite,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
