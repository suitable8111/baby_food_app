import 'package:cloud_firestore/cloud_firestore.dart';
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
  final List<RecipeIngredientData> ingredientData; // Firestore용 데이터
  final List<String> steps;
  final int cookingTimeMinutes;
  final Difficulty difficulty;
  final String? imageUrl;
  final String? storageInfo;
  final String? tip;
  final bool isFavorite;
  final String? userId; // null이면 기본 레시피, 있으면 사용자 레시피
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Recipe({
    required this.id,
    required this.name,
    required this.stage,
    required this.ingredientData,
    required this.steps,
    required this.cookingTimeMinutes,
    this.difficulty = Difficulty.easy,
    this.imageUrl,
    this.storageInfo,
    this.tip,
    this.isFavorite = false,
    this.userId,
    this.createdAt,
    this.updatedAt,
  });

  /// 총 영양소 계산 (ingredients가 로드된 경우)
  Nutrition calculateNutrition(List<Ingredient> allIngredients) {
    Nutrition total = Nutrition.empty;
    for (var data in ingredientData) {
      final ingredient = allIngredients.firstWhere(
        (i) => i.id == data.ingredientId,
        orElse: () => throw Exception('Ingredient not found: ${data.ingredientId}'),
      );
      total = total + ingredient.getNutritionForGrams(data.amount);
    }
    return total;
  }

  /// 알레르기 유발 재료 확인
  List<Ingredient> getAllergens(List<Ingredient> allIngredients) {
    return ingredientData
        .map((data) => allIngredients.firstWhere(
              (i) => i.id == data.ingredientId,
              orElse: () => throw Exception('Ingredient not found'),
            ))
        .where((i) => i.isAllergen)
        .toList();
  }

  bool hasAllergens(List<Ingredient> allIngredients) {
    return getAllergens(allIngredients).isNotEmpty;
  }

  /// 즐겨찾기 토글
  Recipe toggleFavorite() {
    return copyWith(isFavorite: !isFavorite);
  }

  /// copyWith
  Recipe copyWith({
    String? id,
    String? name,
    BabyFoodStage? stage,
    List<RecipeIngredientData>? ingredientData,
    List<String>? steps,
    int? cookingTimeMinutes,
    Difficulty? difficulty,
    String? imageUrl,
    String? storageInfo,
    String? tip,
    bool? isFavorite,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Recipe(
      id: id ?? this.id,
      name: name ?? this.name,
      stage: stage ?? this.stage,
      ingredientData: ingredientData ?? this.ingredientData,
      steps: steps ?? this.steps,
      cookingTimeMinutes: cookingTimeMinutes ?? this.cookingTimeMinutes,
      difficulty: difficulty ?? this.difficulty,
      imageUrl: imageUrl ?? this.imageUrl,
      storageInfo: storageInfo ?? this.storageInfo,
      tip: tip ?? this.tip,
      isFavorite: isFavorite ?? this.isFavorite,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Firestore JSON 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'stage': stage.index,
      'ingredientData': ingredientData.map((i) => i.toJson()).toList(),
      'steps': steps,
      'cookingTimeMinutes': cookingTimeMinutes,
      'difficulty': difficulty.index,
      'imageUrl': imageUrl,
      'storageInfo': storageInfo,
      'tip': tip,
      'isFavorite': isFavorite,
      'userId': userId,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      stage: BabyFoodStage.values[json['stage'] ?? 0],
      ingredientData: (json['ingredientData'] as List<dynamic>?)
              ?.map((i) => RecipeIngredientData.fromJson(i))
              .toList() ??
          [],
      steps: List<String>.from(json['steps'] ?? []),
      cookingTimeMinutes: json['cookingTimeMinutes'] ?? 0,
      difficulty: Difficulty.values[json['difficulty'] ?? 0],
      imageUrl: json['imageUrl'],
      storageInfo: json['storageInfo'],
      tip: json['tip'],
      isFavorite: json['isFavorite'] ?? false,
      userId: json['userId'],
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Firestore 문서에서 변환
  factory Recipe.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Recipe.fromJson({...data, 'id': doc.id});
  }
}

/// 레시피 재료 데이터 (Firestore 저장용)
class RecipeIngredientData {
  final String ingredientId;
  final double amount;
  final String unit;

  const RecipeIngredientData({
    required this.ingredientId,
    required this.amount,
    this.unit = 'g',
  });

  Map<String, dynamic> toJson() {
    return {
      'ingredientId': ingredientId,
      'amount': amount,
      'unit': unit,
    };
  }

  factory RecipeIngredientData.fromJson(Map<String, dynamic> json) {
    return RecipeIngredientData(
      ingredientId: json['ingredientId'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      unit: json['unit'] ?? 'g',
    );
  }

  RecipeIngredientData copyWith({double? amount}) {
    return RecipeIngredientData(
      ingredientId: ingredientId,
      amount: amount ?? this.amount,
      unit: unit,
    );
  }
}
