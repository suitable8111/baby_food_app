import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/ingredient.dart';
import '../models/recipe.dart';
import '../models/shared_recipe.dart';
import '../models/board_recipe.dart';
import '../models/user_profile.dart';
import '../models/food_diary_entry.dart';
import '../models/family_invite.dart';

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
  CollectionReference get _familyInvitesRef => _firestore.collection('family_invites');

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
  Future<String> publishToBoard(Recipe recipe, {String? photoUrl}) async {
    final docRef = await _boardRecipesRef.add({
      'recipeData': recipe.toJson(),
      'authorUserId': currentUserId,
      'authorEmail': currentUser?.email,
      'authorDisplayName': currentUser?.displayName,
      if (photoUrl != null) 'photoUrl': photoUrl,
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

  /// 날짜 범위로 일지 조회 (familyId 기준 + 본인 레거시 폴백)
  Future<List<FoodDiaryEntry>> getDiaryEntries(
    String familyId,
    DateTime start,
    DateTime end,
  ) async {
    // 1) familyId 기준 — 연동된 양쪽 모든 기록
    final snapshot = await _foodDiaryRef
        .where('familyId', isEqualTo: familyId)
        .get();

    // 2) 레거시 폴백: 본인의 옛 문서(familyId 필드 없음)만 추가 조회
    //    반드시 본인 uid로만 조회해야 Firestore 규칙 통과
    final uid = currentUserId;
    QuerySnapshot? legacySnapshot;
    if (uid != null) {
      legacySnapshot = await _foodDiaryRef
          .where('userId', isEqualTo: uid)
          .get();
    }

    // 중복 제거 (id 기준)
    final docMap = <String, DocumentSnapshot>{};
    for (final doc in snapshot.docs) {
      docMap[doc.id] = doc;
    }
    if (legacySnapshot != null) {
      for (final doc in legacySnapshot.docs) {
        docMap[doc.id] = doc;
      }
    }

    final list = docMap.values
        .map((doc) => FoodDiaryEntry.fromFirestore(doc))
        .where((e) => !e.date.isBefore(start) && e.date.isBefore(end))
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

  // ==================== 가족 연동 ====================

  /// 가족 초대 보내기
  Future<String> sendFamilyInvite({
    required String receiverEmail,
    String? senderNickname,
  }) async {
    final docRef = await _familyInvitesRef.add({
      'senderUserId': currentUserId,
      'senderEmail': currentUser?.email,
      'senderNickname': senderNickname,
      'receiverEmail': receiverEmail,
      'status': InviteStatus.pending.name,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  /// 받은 초대 목록 (pending만, 복합 인덱스 불필요하도록 클라이언트 필터)
  Future<List<FamilyInvite>> getPendingFamilyInvites(String email) async {
    final snapshot = await _familyInvitesRef
        .where('receiverEmail', isEqualTo: email)
        .get();
    final list = snapshot.docs
        .map((doc) => FamilyInvite.fromFirestore(doc))
        .where((invite) => invite.status == InviteStatus.pending)
        .toList();
    list.sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
    return list;
  }

  /// 보낸 초대 목록
  Future<List<FamilyInvite>> getSentFamilyInvites(String userId) async {
    final snapshot = await _familyInvitesRef
        .where('senderUserId', isEqualTo: userId)
        .get();
    final list = snapshot.docs.map((doc) => FamilyInvite.fromFirestore(doc)).toList();
    list.sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
    return list;
  }

  /// 초대 수락 → 양쪽 familyId/partnerUserId 설정 + 기존 diary 마이그레이션
  Future<void> acceptFamilyInvite(String inviteId) async {
    final inviteDoc = await _familyInvitesRef.doc(inviteId).get();
    if (!inviteDoc.exists) return;

    final data = inviteDoc.data() as Map<String, dynamic>;
    final senderUserId = data['senderUserId'] as String;

    // 수신자 uid 조회 (이메일 기준)
    final receiverEmail = data['receiverEmail'] as String;
    final receiverSnapshot = await _usersRef
        .where('email', isEqualTo: receiverEmail)
        .limit(1)
        .get();
    if (receiverSnapshot.docs.isEmpty) return;
    final receiverUserId = receiverSnapshot.docs.first.id;

    // sender의 familyId를 기준으로 (이미 있으면 재사용, 없으면 sender uid)
    final senderDoc = await _usersRef.doc(senderUserId).get();
    final senderData = senderDoc.data() as Map<String, dynamic>? ?? {};
    final familyId = senderData['familyId'] ?? senderUserId;

    final batch = _firestore.batch();

    // 초대 상태 업데이트
    batch.update(_familyInvitesRef.doc(inviteId), {
      'status': InviteStatus.accepted.name,
    });

    // 양쪽 프로필 업데이트
    batch.set(_usersRef.doc(senderUserId), {
      'familyId': familyId,
      'partnerUserId': receiverUserId,
    }, SetOptions(merge: true));

    batch.set(_usersRef.doc(receiverUserId), {
      'familyId': familyId,
      'partnerUserId': senderUserId,
    }, SetOptions(merge: true));

    await batch.commit();

    // 양쪽의 기존 diary 문서에 familyId 일괄 세팅
    await _migrateDiaryFamilyId(senderUserId, familyId);
    await _migrateDiaryFamilyId(receiverUserId, familyId);
  }

  /// 특정 사용자의 모든 diary 문서에 familyId를 세팅
  Future<void> _migrateDiaryFamilyId(String userId, String familyId) async {
    final snapshot = await _foodDiaryRef
        .where('userId', isEqualTo: userId)
        .get();

    if (snapshot.docs.isEmpty) return;

    // batch는 500개 제한이 있으므로 나눠서 처리
    final chunks = <List<DocumentSnapshot>>[];
    for (var i = 0; i < snapshot.docs.length; i += 400) {
      chunks.add(snapshot.docs.sublist(
        i,
        i + 400 > snapshot.docs.length ? snapshot.docs.length : i + 400,
      ));
    }

    for (final chunk in chunks) {
      final batch = _firestore.batch();
      for (final doc in chunk) {
        batch.update(doc.reference, {'familyId': familyId});
      }
      await batch.commit();
    }
  }

  /// 초대 거절
  Future<void> declineFamilyInvite(String inviteId) async {
    await _familyInvitesRef.doc(inviteId).update({
      'status': InviteStatus.declined.name,
    });
  }

  /// 가족 연동 해제 → 양쪽 familyId를 각자 uid로 복원 + diary 복원
  Future<void> unlinkFamily(String userId) async {
    final userDoc = await _usersRef.doc(userId).get();
    if (!userDoc.exists) return;

    final data = userDoc.data() as Map<String, dynamic>? ?? {};
    final partnerUserId = data['partnerUserId'] as String?;

    final batch = _firestore.batch();

    // 본인 복원
    batch.update(_usersRef.doc(userId), {
      'familyId': userId,
      'partnerUserId': FieldValue.delete(),
    });

    // 파트너 복원
    if (partnerUserId != null) {
      batch.update(_usersRef.doc(partnerUserId), {
        'familyId': partnerUserId,
        'partnerUserId': FieldValue.delete(),
      });
    }

    await batch.commit();

    // 양쪽 diary를 각자 userId로 복원
    await _migrateDiaryFamilyId(userId, userId);
    if (partnerUserId != null) {
      await _migrateDiaryFamilyId(partnerUserId, partnerUserId);
    }
  }
}
