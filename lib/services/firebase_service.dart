import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/ingredient.dart';
import '../models/recipe.dart';
import '../models/shared_recipe.dart';
import '../models/board_recipe.dart';
import '../models/user_profile.dart';
import '../models/food_diary_entry.dart';

/// Firebase 서비스 클래스
/// Firestore 데이터 CRUD 및 인증 관리
class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // 컬렉션 참조
  CollectionReference get _ingredientsRef => _firestore.collection('ingredients');
  CollectionReference get _recipesRef => _firestore.collection('recipes');
  CollectionReference get _usersRef => _firestore.collection('users');
  CollectionReference get _sharedRecipesRef => _firestore.collection('shared_recipes');
  CollectionReference get _boardRecipesRef => _firestore.collection('board_recipes');
  CollectionReference get _foodDiaryRef => _firestore.collection('food_diary');

  // 현재 사용자
  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;
  bool get isLoggedIn => _auth.currentUser != null;
  bool get isAdmin => _auth.currentUser?.email == 'suitable8111@gmail.com';

  // ==================== 인증 ====================

  /// 이메일 회원가입
  Future<UserCredential> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // 사용자 프로필 업데이트
    if (displayName != null) {
      await credential.user?.updateDisplayName(displayName);
    }

    // Firestore에 사용자 문서 생성
    await _usersRef.doc(credential.user!.uid).set({
      'email': email,
      'displayName': displayName,
      'createdAt': FieldValue.serverTimestamp(),
      'favoriteRecipes': [],
    });

    return credential;
  }

  /// 이메일 로그인
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Google 로그인
  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'google-sign-in-cancelled',
        message: '구글 로그인이 취소되었습니다.',
      );
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);

    // 첫 로그인 시 Firestore 사용자 문서 생성 (기존 문서가 있으면 유지)
    final userDoc = await _usersRef.doc(userCredential.user!.uid).get();
    if (!userDoc.exists) {
      await _usersRef.doc(userCredential.user!.uid).set({
        'email': userCredential.user!.email,
        'displayName': userCredential.user!.displayName,
        'createdAt': FieldValue.serverTimestamp(),
        'favoriteRecipes': [],
      });
    }

    return userCredential;
  }

  /// 로그아웃
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// 비밀번호 재설정 이메일
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// 인증 상태 스트림
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ==================== 식재료 ====================

  /// 모든 식재료 가져오기
  Future<List<Ingredient>> getIngredients() async {
    final snapshot = await _ingredientsRef.get();
    return snapshot.docs.map((doc) => Ingredient.fromFirestore(doc)).toList();
  }

  /// 식재료 스트림
  Stream<List<Ingredient>> ingredientsStream() {
    return _ingredientsRef.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Ingredient.fromFirestore(doc)).toList());
  }

  /// 식재료 추가 (관리자용)
  Future<void> addIngredient(Ingredient ingredient) async {
    await _ingredientsRef.doc(ingredient.id).set(ingredient.toJson());
  }

  /// 여러 식재료 일괄 추가
  Future<void> addIngredientsBatch(List<Ingredient> ingredients) async {
    final batch = _firestore.batch();
    for (var ingredient in ingredients) {
      batch.set(_ingredientsRef.doc(ingredient.id), ingredient.toJson());
    }
    await batch.commit();
  }

  // ==================== 레시피 ====================

  /// 기본 레시피 가져오기 (userId가 null인 것들)
  Future<List<Recipe>> getDefaultRecipes() async {
    final snapshot = await _recipesRef
        .where('userId', isNull: true)
        .get();
    return snapshot.docs.map((doc) => Recipe.fromFirestore(doc)).toList();
  }

  /// 기본 레시피 스트림
  Stream<List<Recipe>> defaultRecipesStream() {
    return _recipesRef
        .where('userId', isNull: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Recipe.fromFirestore(doc)).toList());
  }

  /// 사용자 커스텀 레시피 가져오기
  Future<List<Recipe>> getUserRecipes(String userId) async {
    final snapshot = await _recipesRef
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => Recipe.fromFirestore(doc)).toList();
  }

  /// 사용자 레시피 스트림
  Stream<List<Recipe>> userRecipesStream(String userId) {
    return _recipesRef
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Recipe.fromFirestore(doc)).toList());
  }

  /// 레시피 추가
  Future<String> addRecipe(Recipe recipe) async {
    final docRef = await _recipesRef.add({
      ...recipe.toJson(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  /// 기본 레시피 추가 (관리자용)
  Future<void> addDefaultRecipe(Recipe recipe) async {
    await _recipesRef.doc(recipe.id).set({
      ...recipe.toJson(),
      'userId': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// 여러 기본 레시피 일괄 추가
  Future<void> addDefaultRecipesBatch(List<Recipe> recipes) async {
    final batch = _firestore.batch();
    for (var recipe in recipes) {
      final data = recipe.toJson();
      data['userId'] = null;
      data['createdAt'] = FieldValue.serverTimestamp();
      batch.set(_recipesRef.doc(recipe.id), data);
    }
    await batch.commit();
  }

  /// 레시피 수정
  Future<void> updateRecipe(String recipeId, Recipe recipe) async {
    await _recipesRef.doc(recipeId).update({
      ...recipe.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 레시피 삭제
  Future<void> deleteRecipe(String recipeId) async {
    await _recipesRef.doc(recipeId).delete();
  }

  /// 레시피 ID로 가져오기
  Future<Recipe?> getRecipeById(String recipeId) async {
    final doc = await _recipesRef.doc(recipeId).get();
    if (doc.exists) {
      return Recipe.fromFirestore(doc);
    }
    return null;
  }

  // ==================== 즐겨찾기 ====================

  /// 즐겨찾기 토글
  Future<void> toggleFavorite(String recipeId) async {
    if (currentUserId == null) return;

    final userDoc = _usersRef.doc(currentUserId);
    final userData = await userDoc.get();

    List<String> favorites;

    if (userData.exists) {
      favorites = List<String>.from(
          (userData.data() as Map<String, dynamic>)['favoriteRecipes'] ?? []);
    } else {
      // 사용자 문서가 없으면 생성
      favorites = [];
    }

    if (favorites.contains(recipeId)) {
      favorites.remove(recipeId);
    } else {
      favorites.add(recipeId);
    }

    // set with merge를 사용하여 문서가 없으면 생성, 있으면 업데이트
    await userDoc.set({
      'favoriteRecipes': favorites,
      'email': currentUser?.email,
    }, SetOptions(merge: true));
  }

  /// 즐겨찾기 목록 가져오기
  Future<List<String>> getFavoriteRecipeIds() async {
    if (currentUserId == null) return [];

    final userData = await _usersRef.doc(currentUserId).get();
    if (userData.exists) {
      return List<String>.from(
          (userData.data() as Map<String, dynamic>)['favoriteRecipes'] ?? []);
    }
    return [];
  }

  /// 즐겨찾기 스트림
  Stream<List<String>> favoriteRecipeIdsStream() {
    if (currentUserId == null) return Stream.value([]);

    return _usersRef.doc(currentUserId).snapshots().map((doc) {
      if (doc.exists) {
        return List<String>.from(
            (doc.data() as Map<String, dynamic>)['favoriteRecipes'] ?? []);
      }
      return <String>[];
    });
  }

  // ==================== 초기 데이터 업로드 ====================

  /// 초기 데이터가 있는지 확인
  Future<bool> hasInitialData() async {
    final ingredientsSnapshot = await _ingredientsRef.limit(1).get();
    return ingredientsSnapshot.docs.isNotEmpty;
  }

  // ==================== 사용자 프로필 ====================

  /// 사용자 프로필 로드
  Future<UserProfile?> getUserProfile(String userId) async {
    final doc = await _usersRef.doc(userId).get();
    if (!doc.exists) return null;
    return UserProfile.fromFirestore(doc);
  }

  /// 사용자 프로필 업데이트
  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    await _usersRef.doc(userId).set(data, SetOptions(merge: true));
  }

  // ==================== 1:1 레시피 공유 ====================

  /// 레시피 공유
  Future<String> shareRecipe({
    required Recipe recipe,
    required String receiverEmail,
  }) async {
    final docRef = await _sharedRecipesRef.add({
      'senderUserId': currentUserId,
      'senderEmail': currentUser?.email,
      'receiverEmail': receiverEmail,
      'recipeData': recipe.toJson(),
      'status': ShareStatus.pending.name,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  /// 받은 공유 목록
  Future<List<SharedRecipe>> getReceivedShares(String email) async {
    final snapshot = await _sharedRecipesRef
        .where('receiverEmail', isEqualTo: email)
        .get();
    final list = snapshot.docs.map((doc) => SharedRecipe.fromFirestore(doc)).toList();
    list.sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
    return list;
  }

  /// 보낸 공유 목록
  Future<List<SharedRecipe>> getSentShares(String userId) async {
    final snapshot = await _sharedRecipesRef
        .where('senderUserId', isEqualTo: userId)
        .get();
    final list = snapshot.docs.map((doc) => SharedRecipe.fromFirestore(doc)).toList();
    list.sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
    return list;
  }

  /// 공유 수락
  Future<void> acceptSharedRecipe(String shareId) async {
    await _sharedRecipesRef.doc(shareId).update({
      'status': ShareStatus.accepted.name,
    });
  }

  /// 공유 거절
  Future<void> declineSharedRecipe(String shareId) async {
    await _sharedRecipesRef.doc(shareId).update({
      'status': ShareStatus.declined.name,
    });
  }

  /// 이메일로 사용자 존재 여부 확인
  Future<bool> userExistsByEmail(String email) async {
    final snapshot = await _usersRef
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  // ==================== 레시피 게시판 ====================

  /// 게시판에 레시피 게시
  Future<String> publishToBoard(Recipe recipe) async {
    final docRef = await _boardRecipesRef.add({
      'recipeData': recipe.toJson(),
      'authorUserId': currentUserId,
      'authorEmail': currentUser?.email,
      'authorDisplayName': currentUser?.displayName,
      'publishedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  /// 게시판 레시피 목록
  Future<List<BoardRecipe>> getBoardRecipes() async {
    final snapshot = await _boardRecipesRef
        .orderBy('publishedAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => BoardRecipe.fromFirestore(doc)).toList();
  }

  /// 게시판 레시피 수정
  Future<void> updateBoardRecipe(String boardId, Recipe recipe) async {
    await _boardRecipesRef.doc(boardId).update({
      'recipeData': recipe.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 게시판 레시피 삭제
  Future<void> deleteBoardRecipe(String boardId) async {
    await _boardRecipesRef.doc(boardId).delete();
  }

  // ==================== 이유식 일지 ====================

  /// 일지 엔트리 추가
  Future<String> addDiaryEntry(FoodDiaryEntry entry) async {
    final docRef = await _foodDiaryRef.add({
      ...entry.toJson(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  /// 날짜 범위로 일지 조회
  Future<List<FoodDiaryEntry>> getDiaryEntries(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    final snapshot = await _foodDiaryRef
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .get();
    final list = snapshot.docs
        .map((doc) => FoodDiaryEntry.fromFirestore(doc))
        .toList();
    list.sort((a, b) => a.mealTime.compareTo(b.mealTime));
    return list;
  }

  /// 일지 엔트리 수정
  Future<void> updateDiaryEntry(String entryId, Map<String, dynamic> data) async {
    await _foodDiaryRef.doc(entryId).update(data);
  }

  /// 일지 엔트리 삭제
  Future<void> deleteDiaryEntry(String entryId) async {
    await _foodDiaryRef.doc(entryId).delete();
  }
}
