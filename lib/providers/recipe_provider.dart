import 'package:flutter/foundation.dart';
import '../models/ingredient.dart';
import '../models/recipe.dart';
import '../data/recipes_data.dart';

class RecipeProvider extends ChangeNotifier {
  List<Recipe> _recipes = [];
  BabyFoodStage? _selectedStage;
  String _searchQuery = '';
  Set<String> _favoriteIds = {};

  RecipeProvider() {
    _recipes = List.from(defaultRecipes);
  }

  // Getters
  List<Recipe> get recipes => _recipes;
  BabyFoodStage? get selectedStage => _selectedStage;
  String get searchQuery => _searchQuery;

  /// 필터링된 레시피 목록
  List<Recipe> get filteredRecipes {
    var result = _recipes;

    // 단계 필터
    if (_selectedStage != null) {
      result = result.where((r) => r.stage == _selectedStage).toList();
    }

    // 검색어 필터
    if (_searchQuery.isNotEmpty) {
      result = result.where((r) =>
        r.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        r.ingredients.any((i) =>
          i.ingredient.name.toLowerCase().contains(_searchQuery.toLowerCase())
        )
      ).toList();
    }

    return result;
  }

  /// 단계별 레시피
  List<Recipe> getRecipesByStage(BabyFoodStage stage) {
    return _recipes.where((r) => r.stage == stage).toList();
  }

  /// 즐겨찾기 레시피
  List<Recipe> get favoriteRecipes {
    return _recipes.where((r) => _favoriteIds.contains(r.id)).toList();
  }

  /// 단계 필터 설정
  void setStageFilter(BabyFoodStage? stage) {
    _selectedStage = stage;
    notifyListeners();
  }

  /// 검색어 설정
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// 즐겨찾기 토글
  void toggleFavorite(String recipeId) {
    if (_favoriteIds.contains(recipeId)) {
      _favoriteIds.remove(recipeId);
    } else {
      _favoriteIds.add(recipeId);
    }
    notifyListeners();
  }

  /// 즐겨찾기 여부 확인
  bool isFavorite(String recipeId) {
    return _favoriteIds.contains(recipeId);
  }

  /// ID로 레시피 찾기
  Recipe? getRecipeById(String id) {
    try {
      return _recipes.firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 필터 초기화
  void clearFilters() {
    _selectedStage = null;
    _searchQuery = '';
    notifyListeners();
  }
}
