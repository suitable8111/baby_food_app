import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../services/firebase_service.dart';

/// 인증 상태
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

/// 인증 Provider
class AuthProvider extends ChangeNotifier {
  final FirebaseService _firebaseService;

  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _errorMessage;
  UserProfile? _userProfile;
  UserProfile? _partnerProfile;

  AuthProvider(this._firebaseService) {
    // 인증 상태 변화 구독
    _firebaseService.authStateChanges.listen(_onAuthStateChanged);
  }

  // Getters
  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;
  String? get userId => _user?.uid;
  String? get userEmail => _user?.email;
  String? get displayName => _userProfile?.nickname ?? _user?.displayName;
  bool get isAdmin => _user?.email == 'suitable8111@gmail.com';
  UserProfile? get userProfile => _userProfile;
  UserProfile? get partnerProfile => _partnerProfile;
  String get familyId => _userProfile?.effectiveFamilyId ?? _user?.uid ?? '';
  bool get hasPartner => _userProfile?.partnerUserId != null;

  /// 인증 상태 변화 핸들러
  void _onAuthStateChanged(User? user) async {
    _user = user;
    if (user != null) {
      _status = AuthStatus.authenticated;
      await loadUserProfile();
    } else {
      _status = AuthStatus.unauthenticated;
      _userProfile = null;
    }
    notifyListeners();
  }

  /// 사용자 프로필 로드 (파트너 프로필도 함께)
  Future<void> loadUserProfile() async {
    if (_user == null) return;
    try {
      _userProfile = await _firebaseService.getUserProfile(_user!.uid);
      // 프로필이 없으면 기본값으로 생성
      _userProfile ??= UserProfile(
        userId: _user!.uid,
        email: _user!.email ?? '',
      );
      // 파트너 프로필 로드
      final partnerId = _userProfile?.partnerUserId;
      if (partnerId != null) {
        _partnerProfile = await _firebaseService.getUserProfile(partnerId);
      } else {
        _partnerProfile = null;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('프로필 로드 실패: $e');
    }
  }

  /// 사용자 프로필 업데이트
  Future<bool> updateUserProfile(UserProfile profile) async {
    if (_user == null) return false;
    try {
      await _firebaseService.updateUserProfile(_user!.uid, profile.toJson());
      _userProfile = profile;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('프로필 업데이트 실패: $e');
      _errorMessage = '프로필 저장에 실패했습니다.';
      notifyListeners();
      return false;
    }
  }

  /// 파트너 연동 (초대 수락)
  Future<bool> linkPartner(String inviteId) async {
    try {
      await _firebaseService.acceptFamilyInvite(inviteId);
      await loadUserProfile();
      return true;
    } catch (e) {
      debugPrint('파트너 연동 실패: $e');
      return false;
    }
  }

  /// 파트너 연동 해제
  Future<bool> unlinkPartner() async {
    if (_user == null) return false;
    try {
      await _firebaseService.unlinkFamily(_user!.uid);
      _partnerProfile = null;
      await loadUserProfile();
      return true;
    } catch (e) {
      debugPrint('연동 해제 실패: $e');
      return false;
    }
  }

  /// 회원가입
  Future<bool> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      await _firebaseService.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = _getErrorMessage(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = '회원가입 중 오류가 발생했습니다.';
      notifyListeners();
      return false;
    }
  }

  /// 로그인
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      await _firebaseService.signIn(
        email: email,
        password: password,
      );

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = _getErrorMessage(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = '로그인 중 오류가 발생했습니다.';
      notifyListeners();
      return false;
    }
  }

  /// Google 로그인
  Future<bool> signInWithGoogle() async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      await _firebaseService.signInWithGoogle();

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'google-sign-in-cancelled') {
        // 사용자가 취소한 경우 조용히 원래 상태로 복귀
        _status = _user != null
            ? AuthStatus.authenticated
            : AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
      _status = AuthStatus.error;
      _errorMessage = _getErrorMessage(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Google 로그인 중 오류가 발생했습니다.';
      notifyListeners();
      return false;
    }
  }

  /// 로그아웃
  Future<void> signOut() async {
    try {
      await _firebaseService.signOut();
      _status = AuthStatus.unauthenticated;
      _user = null;
      _userProfile = null;
      _partnerProfile = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = '로그아웃 중 오류가 발생했습니다.';
      notifyListeners();
    }
  }

  /// 비밀번호 재설정 이메일 전송
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      _errorMessage = null;
      await _firebaseService.sendPasswordResetEmail(email);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getErrorMessage(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = '이메일 전송 중 오류가 발생했습니다.';
      notifyListeners();
      return false;
    }
  }

  /// 에러 메시지 초기화
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Firebase 에러 코드 -> 한글 메시지
  String _getErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return '이미 사용 중인 이메일입니다.';
      case 'invalid-email':
        return '유효하지 않은 이메일 형식입니다.';
      case 'weak-password':
        return '비밀번호가 너무 약합니다. (6자 이상)';
      case 'user-not-found':
        return '등록되지 않은 이메일입니다.';
      case 'wrong-password':
        return '비밀번호가 일치하지 않습니다.';
      case 'too-many-requests':
        return '너무 많은 시도가 있었습니다. 잠시 후 다시 시도해주세요.';
      case 'user-disabled':
        return '비활성화된 계정입니다.';
      case 'operation-not-allowed':
        return '이 작업은 허용되지 않습니다.';
      case 'invalid-credential':
        return '이메일 또는 비밀번호가 올바르지 않습니다.';
      case 'account-exists-with-different-credential':
        return '이미 동일한 이메일로 가입된 계정이 있습니다. 기존 로그인 방식을 사용해주세요.';
      case 'google-sign-in-cancelled':
        return '';
      default:
        return '오류가 발생했습니다. ($code)';
    }
  }
}
