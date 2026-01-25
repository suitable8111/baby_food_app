import 'package:flutter/foundation.dart';
import '../models/ingredient.dart';
import '../models/nutrition.dart';
import '../data/ingredients_data.dart';

/// 커스텀 재료 항목 (양 조절 가능)
class CustomIngredientItem {
  final Ingredient ingredient;
  double amount; // 그램

  CustomIngredientItem({
    required this.ingredient,
    this.amount = 10,
  });

  Nutrition get nutrition => ingredient.getNutritionForGrams(amount);
}

class NutritionProvider extends ChangeNotifier {
  List<CustomIngredientItem> _selectedIngredients = [];
  int _babyAgeMonths = 6; // 아기 월령

  // Getters
  List<CustomIngredientItem> get selectedIngredients => _selectedIngredients;
  int get babyAgeMonths => _babyAgeMonths;

  /// 전체 재료 목록
  List<Ingredient> get allIngredients => defaultIngredients;

  /// 카테고리별 재료
  List<Ingredient> getIngredientsByCategory(IngredientCategory category) {
    return defaultIngredients.where((i) => i.category == category).toList();
  }

  /// 현재 단계에 사용 가능한 재료
  List<Ingredient> get availableIngredients {
    final stage = _getStageByAge(_babyAgeMonths);
    return defaultIngredients.where((i) => i.isAvailableAt(stage)).toList();
  }

  /// 월령에 따른 단계 계산
  BabyFoodStage _getStageByAge(int months) {
    if (months <= 6) return BabyFoodStage.early;
    if (months <= 9) return BabyFoodStage.middle;
    return BabyFoodStage.late;
  }

  /// 현재 단계
  BabyFoodStage get currentStage => _getStageByAge(_babyAgeMonths);

  /// 총 영양소 계산
  Nutrition get totalNutrition {
    if (_selectedIngredients.isEmpty) return Nutrition.empty;
    return _selectedIngredients.fold<Nutrition>(
      Nutrition.empty,
      (sum, item) => sum + item.nutrition,
    );
  }

  /// 일일 권장량 대비 비율 계산
  Map<String, double> get nutritionPercentages {
    final daily = DailyRecommendation.getByAge(_babyAgeMonths);
    final current = totalNutrition;

    return {
      '칼로리': daily.calories > 0 ? (current.calories / daily.calories * 100) : 0,
      '단백질': daily.protein > 0 ? (current.protein / daily.protein * 100) : 0,
      '철분': daily.iron > 0 ? (current.iron / daily.iron * 100) : 0,
      '칼슘': daily.calcium > 0 ? (current.calcium / daily.calcium * 100) : 0,
      '비타민A': daily.vitaminA > 0 ? (current.vitaminA / daily.vitaminA * 100) : 0,
      '비타민C': daily.vitaminC > 0 ? (current.vitaminC / daily.vitaminC * 100) : 0,
      '아연': daily.zinc > 0 ? (current.zinc / daily.zinc * 100) : 0,
    };
  }

  /// 아기 월령 설정
  void setBabyAge(int months) {
    _babyAgeMonths = months.clamp(4, 24);
    notifyListeners();
  }

  /// 재료 추가
  void addIngredient(Ingredient ingredient, {double amount = 10}) {
    // 이미 있으면 수량만 증가
    final existingIndex = _selectedIngredients.indexWhere(
      (item) => item.ingredient.id == ingredient.id
    );

    if (existingIndex >= 0) {
      _selectedIngredients[existingIndex].amount += amount;
    } else {
      _selectedIngredients.add(CustomIngredientItem(
        ingredient: ingredient,
        amount: amount,
      ));
    }
    notifyListeners();
  }

  /// 재료 제거
  void removeIngredient(String ingredientId) {
    _selectedIngredients.removeWhere((item) => item.ingredient.id == ingredientId);
    notifyListeners();
  }

  /// 재료 양 변경
  void updateIngredientAmount(String ingredientId, double newAmount) {
    final index = _selectedIngredients.indexWhere(
      (item) => item.ingredient.id == ingredientId
    );
    if (index >= 0 && newAmount > 0) {
      _selectedIngredients[index].amount = newAmount;
      notifyListeners();
    }
  }

  /// 전체 초기화
  void clearAll() {
    _selectedIngredients.clear();
    notifyListeners();
  }

  /// 재료 검색
  List<Ingredient> searchIngredients(String query) {
    if (query.isEmpty) return availableIngredients;
    return availableIngredients.where((i) =>
      i.name.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  /// 알레르기 재료 확인
  List<Ingredient> get allergenIngredients {
    return _selectedIngredients
        .where((item) => item.ingredient.isAllergen)
        .map((item) => item.ingredient)
        .toList();
  }

  /// 알레르기 경고 필요 여부
  bool get hasAllergenWarning => allergenIngredients.isNotEmpty;
}
