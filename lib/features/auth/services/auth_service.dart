import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  GoogleSignIn? _googleSignIn;

  GoogleSignIn _getGoogleSignIn() {
    // 웹에서는 clientId가 필요. 없으면 런타임 초기화를 건너뛰기 위해 안전 가드 적용
    if (kIsWeb) {
      final clientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'];
      if (clientId == null || clientId.isEmpty) {
        // 최소한의 더미 객체 생성(실제 호출 전까지 초기화 안 함)
        return GoogleSignIn(clientId: '');
      }
      return GoogleSignIn(
        clientId: clientId,
        scopes: const ['email', 'profile'],
      );
    }
    return GoogleSignIn(scopes: const ['email', 'profile']);
  }

  // 현재 로그인된 사용자 정보
  UserInfo? _currentUser;
  UserInfo? get currentUser => _currentUser;

  // 로그인 상태 확인
  bool get isLoggedIn => _currentUser != null;

  // 앱 시작시 로그인 상태 복원
  Future<bool> restoreLoginState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final userName = prefs.getString('user_name');
      final userEmail = prefs.getString('user_email');
      final userPhoto = prefs.getString('user_photo');
      final loginProvider = prefs.getString('login_provider');

      if (userId != null && userName != null && userEmail != null) {
        _currentUser = UserInfo(
          id: userId,
          name: userName,
          email: userEmail,
          photoUrl: userPhoto,
          provider: loginProvider ?? 'unknown',
        );
        return true;
      }
      return false;
    } catch (e) {
      print('로그인 상태 복원 실패: $e');
      return false;
    }
  }

  // Google 로그인
  Future<AuthResult> signInWithGoogle() async {
    try {
      _googleSignIn ??= _getGoogleSignIn();
      // 기존 로그인 세션 확인
      final GoogleSignInAccount? account = await _googleSignIn!.signInSilently();
      
      final GoogleSignInAccount? googleUser = account ?? await _googleSignIn!.signIn();
      
      if (googleUser == null) {
        return AuthResult.cancelled();
      }

      _currentUser = UserInfo(
        id: googleUser.id,
        name: googleUser.displayName ?? '',
        email: googleUser.email,
        photoUrl: googleUser.photoUrl,
        provider: 'google',
      );

      await _saveUserInfo(_currentUser!);
      return AuthResult.success(_currentUser!);
    } catch (error) {
      print('Google 로그인 에러: $error');
      return AuthResult.error('Google 로그인에 실패했습니다: $error');
    }
  }

  // Apple 로그인
  Future<AuthResult> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final fullName = credential.givenName != null && credential.familyName != null
          ? '${credential.givenName} ${credential.familyName}'
          : credential.email?.split('@').first ?? 'Apple User';

      _currentUser = UserInfo(
        id: credential.userIdentifier ?? '',
        name: fullName,
        email: credential.email ?? '',
        photoUrl: null,
        provider: 'apple',
      );

      await _saveUserInfo(_currentUser!);
      return AuthResult.success(_currentUser!);
    } catch (error) {
      print('Apple 로그인 에러: $error');
      return AuthResult.error('Apple 로그인에 실패했습니다: $error');
    }
  }

  // Kakao 로그인 (현재는 웹에서 지원하지 않으므로 더미 구현)
  Future<AuthResult> signInWithKakao() async {
    // 실제 Kakao 로그인은 웹에서 복잡한 설정이 필요하므로
    // 현재는 더미 로그인으로 구현
    await Future.delayed(const Duration(seconds: 1));
    
    _currentUser = UserInfo(
      id: 'kakao_demo_user',
      name: '카카오 사용자',
      email: 'kakao@example.com',
      photoUrl: null,
      provider: 'kakao',
    );

    await _saveUserInfo(_currentUser!);
    return AuthResult.success(_currentUser!);
  }

  // 로그아웃
  Future<void> signOut() async {
    try {
      if (_currentUser?.provider == 'google') {
        await _googleSignIn?.signOut();
      }
      
      _currentUser = null;
      
      // SharedPreferences에서 사용자 정보 삭제
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      print('로그아웃 에러: $e');
    }
  }

  // 사용자 정보 저장
  Future<void> _saveUserInfo(UserInfo user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', user.id);
      await prefs.setString('user_name', user.name);
      await prefs.setString('user_email', user.email);
      if (user.photoUrl != null) {
        await prefs.setString('user_photo', user.photoUrl!);
      }
      await prefs.setString('login_provider', user.provider);
    } catch (e) {
      print('사용자 정보 저장 실패: $e');
    }
  }
}

// 사용자 정보 클래스
class UserInfo {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final String provider;

  UserInfo({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.provider,
  });

  @override
  String toString() {
    return 'UserInfo(id: $id, name: $name, email: $email, provider: $provider)';
  }
}

// 로그인 결과 클래스
class AuthResult {
  final bool isSuccess;
  final UserInfo? user;
  final String? error;
  final bool isCancelled;

  AuthResult._({
    required this.isSuccess,
    this.user,
    this.error,
    this.isCancelled = false,
  });

  factory AuthResult.success(UserInfo user) {
    return AuthResult._(isSuccess: true, user: user);
  }

  factory AuthResult.error(String error) {
    return AuthResult._(isSuccess: false, error: error);
  }

  factory AuthResult.cancelled() {
    return AuthResult._(isSuccess: false, isCancelled: true);
  }
}

