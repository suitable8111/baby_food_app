import 'package:flutter/foundation.dart';
import '../models/ingredient.dart';
import '../models/recipe.dart';
import '../models/nutrition.dart';
import '../models/shared_recipe.dart';
import '../models/board_recipe.dart';
import '../services/firebase_service.dart';
import '../services/image_service.dart';
import '../data/ingredients_data.dart';
import '../data/recipes_data.dart' as local_recipes;

class RecipeProvider extends ChangeNotifier {
  final FirebaseService _firebaseService;

  List<Recipe> _defaultRecipes = [];
  List<Recipe> _userRecipes = [];
  List<Ingredient> _ingredients = [];
  Set<String> _favoriteIds = {};

  List<SharedRecipe> _receivedShares = [];
  List<SharedRecipe> _sentShares = [];
  List<BoardRecipe> _boardRecipes = [];

  BabyFoodStage? _selectedStage;
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;

  RecipeProvider(this._firebaseService) {
    _loadData();
  }

  // Getters
  List<Recipe> get defaultRecipes => _defaultRecipes;
  List<Recipe> get userRecipes => _userRecipes;
  List<Recipe> get allRecipes => [..._defaultRecipes, ..._userRecipes];
  List<Ingredient> get ingredients => _ingredients;
  BabyFoodStage? get selectedStage => _selectedStage;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<SharedRecipe> get receivedShares => _receivedShares;
  List<SharedRecipe> get sentShares => _sentShares;
  List<BoardRecipe> get boardRecipes => _boardRecipes;
  bool get isAdmin => _firebaseService.isAdmin;

  /// 필터링된 레시피 목록
  List<Recipe> get filteredRecipes {
    var result = allRecipes;

    if (_selectedStage != null) {
      result = result.where((r) => r.stage == _selectedStage).toList();
    }

    if (_searchQuery.isNotEmpty) {
      result = result.where((r) {
        final nameMatch =
            r.name.toLowerCase().contains(_searchQuery.toLowerCase());
        final ingredientMatch = r.ingredientData.any((data) {
          final ingredient = getIngredientById(data.ingredientId);
          return ingredient?.name
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ??
              false;
        });
        return nameMatch || ingredientMatch;
      }).toList();
    }

    return result;
  }

  /// 단계별 레시피
  List<Recipe> getRecipesByStage(BabyFoodStage stage) {
    return allRecipes.where((r) => r.stage == stage).toList();
  }

  /// 즐겨찾기 레시피
  List<Recipe> get favoriteRecipes {
    return allRecipes.where((r) => _favoriteIds.contains(r.id)).toList();
  }

  /// 재료 ID로 찾기
  Ingredient? getIngredientById(String id) {
    try {
      return _ingredients.firstWhere((i) => i.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 레시피의 총 영양소 계산
  Nutrition getRecipeNutrition(Recipe recipe) {
    return recipe.calculateNutrition(_ingredients);
  }

  /// 레시피에 알레르기 재료 있는지 확인
  bool recipeHasAllergens(Recipe recipe) {
    return recipe.hasAllergens(_ingredients);
  }

  /// 레시피의 알레르기 재료 목록
  List<Ingredient> getRecipeAllergens(Recipe recipe) {
    return recipe.getAllergens(_ingredients);
  }

  /// 데이터 로드
  Future<void> _loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 기본 재료 및 레시피는 항상 로컬 데이터 사용
      _ingredients = defaultIngredients;
      _defaultRecipes = local_recipes.defaultRecipes;

      // Firestore에서 사용자 데이터 로드 시도
      try {
        if (_firebaseService.isLoggedIn) {
          _userRecipes =
              await _firebaseService.getUserRecipes(_firebaseService.currentUserId!);
          _favoriteIds =
              (await _firebaseService.getFavoriteRecipeIds()).toSet();
        }
      } catch (e) {
        debugPrint('Firestore 로드 실패: $e');
      }

      _errorMessage = null;
    } catch (e) {
      _errorMessage = '데이터를 불러오는 중 오류가 발생했습니다.';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 데이터 새로고침
  Future<void> refresh() async {
    await _loadData();
  }

  /// 사용자 로그인 시 데이터 새로고침
  Future<void> onUserLogin() async {
    if (_firebaseService.isLoggedIn) {
      _userRecipes =
          await _firebaseService.getUserRecipes(_firebaseService.currentUserId!);
      _favoriteIds = (await _firebaseService.getFavoriteRecipeIds()).toSet();
      await loadReceivedShares();
      await loadSentShares();
      await loadBoardRecipes();
      notifyListeners();
    }
  }

  /// 사용자 로그아웃 시 데이터 초기화
  void onUserLogout() {
    _userRecipes = [];
    _favoriteIds = {};
    _receivedShares = [];
    _sentShares = [];
    notifyListeners();
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

  /// 필터 초기화
  void clearFilters() {
    _selectedStage = null;
    _searchQuery = '';
    notifyListeners();
  }

  /// 즐겨찾기 토글 (로그인 안 된 경우 false 반환)
  Future<bool> toggleFavorite(String recipeId) async {
    if (!_firebaseService.isLoggedIn) return false;

    if (_favoriteIds.contains(recipeId)) {
      _favoriteIds.remove(recipeId);
    } else {
      _favoriteIds.add(recipeId);
    }
    notifyListeners();

    try {
      await _firebaseService.toggleFavorite(recipeId);
    } catch (e) {
      // 롤백
      if (_favoriteIds.contains(recipeId)) {
        _favoriteIds.remove(recipeId);
      } else {
        _favoriteIds.add(recipeId);
      }
      notifyListeners();
    }

    return true;
  }

  /// 즐겨찾기 여부 확인
  bool isFavorite(String recipeId) {
    return _favoriteIds.contains(recipeId);
  }

  /// 사용자 레시피 추가
  Future<String?> addUserRecipe(Recipe recipe) async {
    if (!_firebaseService.isLoggedIn) return null;

    try {
      final newRecipe = recipe.copyWith(
        userId: _firebaseService.currentUserId,
        createdAt: DateTime.now(),
      );
      final id = await _firebaseService.addRecipe(newRecipe);

      _userRecipes.insert(0, newRecipe.copyWith(id: id));
      notifyListeners();

      return id;
    } catch (e) {
      _errorMessage = '레시피 저장에 실패했습니다.';
      notifyListeners();
      return null;
    }
  }

  /// 사용자 레시피 수정
  Future<bool> updateUserRecipe(String recipeId, Recipe recipe) async {
    if (!_firebaseService.isLoggedIn) return false;

    try {
      final updatedRecipe = recipe.copyWith(updatedAt: DateTime.now());
      await _firebaseService.updateRecipe(recipeId, updatedRecipe);

      final index = _userRecipes.indexWhere((r) => r.id == recipeId);
      if (index >= 0) {
        _userRecipes[index] = updatedRecipe;
        notifyListeners();
      }

      return true;
    } catch (e) {
      _errorMessage = '레시피 수정에 실패했습니다.';
      notifyListeners();
      return false;
    }
  }

  /// 사용자 레시피 삭제
  Future<bool> deleteUserRecipe(String recipeId) async {
    if (!_firebaseService.isLoggedIn) return false;

    try {
      await _firebaseService.deleteRecipe(recipeId);
      _userRecipes.removeWhere((r) => r.id == recipeId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = '레시피 삭제에 실패했습니다.';
      notifyListeners();
      return false;
    }
  }

  /// ID로 레시피 찾기
  Recipe? getRecipeById(String id) {
    try {
      return allRecipes.firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }

  // ==================== 1:1 레시피 공유 ====================

  /// 레시피 공유
  Future<bool> shareRecipe(Recipe recipe, String receiverEmail) async {
    if (!_firebaseService.isLoggedIn) return false;

    try {
      await _firebaseService.shareRecipe(
        recipe: recipe,
        receiverEmail: receiverEmail,
      );
      await loadSentShares();
      return true;
    } catch (e) {
      _errorMessage = '레시피 공유에 실패했습니다.';
      notifyListeners();
      return false;
    }
  }

  /// 받은 공유 로드
  Future<void> loadReceivedShares() async {
    if (!_firebaseService.isLoggedIn) return;
    try {
      _receivedShares = await _firebaseService
          .getReceivedShares(_firebaseService.currentUser!.email!);
      notifyListeners();
    } catch (e) {
      debugPrint('받은 공유 로드 실패: $e');
    }
  }

  /// 보낸 공유 로드
  Future<void> loadSentShares() async {
    if (!_firebaseService.isLoggedIn) return;
    try {
      _sentShares = await _firebaseService
          .getSentShares(_firebaseService.currentUserId!);
      notifyListeners();
    } catch (e) {
      debugPrint('보낸 공유 로드 실패: $e');
    }
  }

  /// 공유 수락 (내 레시피로 저장)
  Future<bool> acceptShare(SharedRecipe share) async {
    if (!_firebaseService.isLoggedIn) return false;

    try {
      await _firebaseService.acceptSharedRecipe(share.id);
      final recipe = share.toRecipe().copyWith(
            id: '',
            userId: _firebaseService.currentUserId,
            createdAt: DateTime.now(),
          );
      await addUserRecipe(recipe);
      await loadReceivedShares();
      return true;
    } catch (e) {
      _errorMessage = '공유 수락에 실패했습니다.';
      notifyListeners();
      return false;
    }
  }

  /// 공유 거절
  Future<bool> declineShare(String shareId) async {
    if (!_firebaseService.isLoggedIn) return false;

    try {
      await _firebaseService.declineSharedRecipe(shareId);
      await loadReceivedShares();
      return true;
    } catch (e) {
      _errorMessage = '공유 거절에 실패했습니다.';
      notifyListeners();
      return false;
    }
  }

  /// 대기 중인 공유 수
  int get pendingShareCount =>
      _receivedShares.where((s) => s.status == ShareStatus.pending).length;

  // ==================== 레시피 게시판 ====================

  /// 게시판 레시피 로드
  Future<void> loadBoardRecipes() async {
    try {
      _boardRecipes = await _firebaseService.getBoardRecipes();
      notifyListeners();
    } catch (e) {
      debugPrint('게시판 레시피 로드 실패: $e');
    }
  }

  /// 게시판에 레시피 게시
  Future<bool> publishToBoard(Recipe recipe) async {
    if (!_firebaseService.isLoggedIn) return false;

    try {
      final userId = _firebaseService.currentUserId ?? '';
      String? photoUrl;

      final imageUrl = recipe.imageUrl;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        if (imageUrl.startsWith('http')) {
          photoUrl = imageUrl;
        } else if (ImageService().isLocalFile(imageUrl)) {
          final fileId =
              '${userId}_${DateTime.now().millisecondsSinceEpoch}';
          photoUrl = await ImageService()
              .uploadLocalRecipePhoto(userId, fileId, imageUrl);
        }
      }

      await _firebaseService.publishToBoard(recipe, photoUrl: photoUrl);
      await loadBoardRecipes();
      return true;
    } catch (e) {
      _errorMessage = '게시판 게시에 실패했습니다.';
      notifyListeners();
      return false;
    }
  }

  /// 게시판 레시피를 내 레시피로 저장
  Future<String?> saveBoardRecipeToMyRecipes(BoardRecipe boardRecipe) async {
    if (!_firebaseService.isLoggedIn) return null;

    final recipe = boardRecipe.toRecipe().copyWith(
          id: '',
          userId: _firebaseService.currentUserId,
          createdAt: DateTime.now(),
        );
    return addUserRecipe(recipe);
  }

  /// 게시판 레시피 수정 (작성자 또는 관리자)
  Future<bool> updateBoardRecipe(String boardId, Recipe recipe) async {
    if (!_firebaseService.isLoggedIn) return false;

    try {
      await _firebaseService.updateBoardRecipe(boardId, recipe);
      await loadBoardRecipes();
      return true;
    } catch (e) {
      _errorMessage = '게시판 레시피 수정에 실패했습니다.';
      notifyListeners();
      return false;
    }
  }

  /// 게시판 레시피 삭제 (작성자 또는 관리자)
  Future<bool> deleteBoardRecipe(String boardId) async {
    if (!_firebaseService.isLoggedIn) return false;

    try {
      await _firebaseService.deleteBoardRecipe(boardId);
      await loadBoardRecipes();
      return true;
    } catch (e) {
      _errorMessage = '게시판 레시피 삭제에 실패했습니다.';
      notifyListeners();
      return false;
    }
  }

  /// 게시판 레시피 편집/삭제 권한 확인
  bool canEditBoardRecipe(BoardRecipe boardRecipe) {
    if (!_firebaseService.isLoggedIn) return false;
    return _firebaseService.isAdmin ||
        boardRecipe.authorUserId == _firebaseService.currentUserId;
  }

  /// 게시판 즐겨찾기 토글
  Future<bool> toggleBoardFavorite(String boardId) async {
    final favoriteKey = 'board_$boardId';
    return toggleFavorite(favoriteKey);
  }

  /// 게시판 즐겨찾기 여부
  bool isBoardFavorite(String boardId) {
    return isFavorite('board_$boardId');
  }
}
