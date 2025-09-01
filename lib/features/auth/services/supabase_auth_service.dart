import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_client_provider.dart';
import '../../../core/services/nickname_generator_service.dart';

class SupabaseAuthService {
  static final SupabaseAuthService _instance = SupabaseAuthService._internal();
  factory SupabaseAuthService() => _instance;
  SupabaseAuthService._internal();

  SupabaseClient get _client => SupabaseClientProvider.client;

  // 현재 로그인된 사용자
  User? get currentUser => _client.auth.currentUser;
  
  // 로그인 상태 확인
  bool get isLoggedIn => currentUser != null;

  // 사용자 정보를 UserInfo 형태로 변환
  UserInfo? get currentUserInfo {
    final user = currentUser;
    if (user == null) return null;
    
    return UserInfo(
      id: user.id,
      name: user.userMetadata?['full_name'] ?? user.email?.split('@')[0] ?? 'User',
      nickname: user.userMetadata?['nickname'] ?? user.userMetadata?['full_name'] ?? user.email?.split('@')[0] ?? 'User',
      email: user.email ?? '',
      photoUrl: user.userMetadata?['avatar_url'],
      provider: user.appMetadata['provider'] ?? 'email',
    );
  }

  // 앱 시작시 로그인 상태 복원 (Supabase가 자동으로 처리)
  Future<bool> restoreLoginState() async {
    try {
      // Supabase는 자동으로 세션을 복원하므로 현재 사용자만 확인
      return currentUser != null;
    } catch (e) {
      debugPrint('로그인 상태 복원 실패: $e');
      return false;
    }
  }

  // 이메일 로그인
  Future<AuthResult> signInWithEmail(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        return AuthResult.success(_convertToUserInfo(response.user!));
      } else {
        return AuthResult.error('로그인에 실패했습니다.');
      }
    } catch (error) {
      debugPrint('이메일 로그인 에러: $error');
      return AuthResult.error('이메일 로그인에 실패했습니다: $error');
    }
  }

  // 이메일 회원가입
  Future<AuthResult> signUpWithEmail(String email, String password) async {
    try {
      // 1. 먼저 랜덤 닉네임 생성
      final nicknameService = NicknameGeneratorService();
      final uniqueNickname = await nicknameService.generateUniqueNickname(
        checkDuplicate: checkNicknameExists,
      );

      // 2. 회원가입 진행
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'nickname': uniqueNickname,
          'full_name': uniqueNickname, // 기본 이름도 닉네임으로 설정
        }
      );

      if (response.user != null) {
        debugPrint('🎉 회원가입 성공! 자동 생성된 닉네임: $uniqueNickname');
        return AuthResult.success(_convertToUserInfo(response.user!));
      } else {
        return AuthResult.error('회원가입에 실패했습니다.');
      }
    } catch (error) {
      debugPrint('이메일 회원가입 에러: $error');
      return AuthResult.error('회원가입에 실패했습니다: $error');
    }
  }

  // Google 로그인
  Future<AuthResult> signInWithGoogle() async {
    try {
      debugPrint('🔵 Google 로그인 시작');
      
      final response = await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'com.example.bookreviewapp://login-callback/',
      );

      debugPrint('🔵 Google OAuth 응답: $response');

      // 웹에서는 리다이렉트되므로 바로 결과를 확인할 수 없음
      if (kIsWeb) {
        debugPrint('🔵 웹 환경: 리다이렉트 진행 중');
        // 웹에서는 리다이렉트 후 세션이 복원되므로 대기
        await Future.delayed(const Duration(seconds: 1));
        
        final user = currentUser;
        if (user != null) {
          debugPrint('🔵 웹 로그인 성공: ${user.email}');
          await _ensureUserHasNickname(user); // 닉네임 확인 및 생성
          return AuthResult.success(_convertToUserInfo(user));
        } else {
          debugPrint('🔵 웹 로그인 대기 중 (리다이렉트 필요)');
          // 리다이렉트가 진행 중이므로 성공으로 간주
          return AuthResult.success(UserInfo(
            id: 'pending',
            name: 'Google User',
            nickname: 'Google User',
            email: 'pending@google.com',
            provider: 'google',
          ));
        }
      }

      // 모바일에서는 응답을 바로 확인
      await Future.delayed(const Duration(seconds: 2)); // OAuth 완료 대기
      final user = currentUser;
      if (user != null) {
        debugPrint('🔵 모바일 로그인 성공: ${user.email}');
        await _ensureUserHasNickname(user); // 닉네임 확인 및 생성
        return AuthResult.success(_convertToUserInfo(user));
      } else {
        debugPrint('🔵 모바일 로그인 실패: 사용자 정보 없음');
        return AuthResult.error('Google 로그인에 실패했습니다.');
      }
    } catch (error) {
      debugPrint('🔴 Google 로그인 에러: $error');
      if (error.toString().contains('cancelled') || error.toString().contains('canceled')) {
        return AuthResult.cancelled();
      }
      return AuthResult.error('Google 로그인에 실패했습니다: $error');
    }
  }

  // Apple 로그인 (임시 더미 버전)
  Future<AuthResult> signInWithApple() async {
    try {
      // 실제 OAuth 설정이 없으므로 더미 계정으로 이메일 로그인 시도
      return await signInWithEmail('apple.demo@example.com', 'password123');
    } catch (error) {
      debugPrint('Apple 로그인 에러: $error');
      return AuthResult.error('Apple 로그인에 실패했습니다: $error');
    }
  }

  // 카카오 로그인
  Future<AuthResult> signInWithKakao() async {
    try {
      debugPrint('🟡 카카오 로그인 시작');
      
      final response = await _client.auth.signInWithOAuth(
        OAuthProvider.kakao,
        redirectTo: kIsWeb ? null : 'com.example.bookreviewapp://kakao/callback',
      );

      debugPrint('🟡 카카오 OAuth 응답: $response');

      if (kIsWeb) {
        debugPrint('🟡 웹 환경: 카카오 리다이렉트 진행 중');
        // 웹에서는 리다이렉트가 발생하므로 여기서 바로 성공 응답을 보내지 않음
        return AuthResult.success(UserInfo(
          id: 'pending_kakao',
          name: 'Kakao User',
          nickname: 'Kakao User',
          email: 'pending@kakao.com',
          provider: 'kakao',
        ));
      }

      // 모바일에서는 응답을 기다림
      await Future.delayed(const Duration(seconds: 2));
      final user = currentUser;
      if (user != null) {
        debugPrint('🟡 카카오 모바일 로그인 성공: ${user.email}');
        await _ensureUserHasNickname(user); // 닉네임 확인 및 생성
        return AuthResult.success(_convertToUserInfo(user));
      } else {
        debugPrint('🟡 카카오 모바일 로그인 실패: 사용자 정보 없음');
        return AuthResult.error('카카오 로그인에 실패했습니다.');
      }
    } catch (error) {
      debugPrint('🔴 카카오 로그인 에러: $error');
      if (error.toString().contains('cancelled') || error.toString().contains('canceled')) {
        return AuthResult.cancelled();
      }
      return AuthResult.error('카카오 로그인에 실패했습니다: $error');
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      debugPrint('로그아웃 에러: $e');
    }
  }

  // 닉네임 중복 체크
  Future<bool> checkNicknameExists(String nickname) async {
    try {
      final result = await _client
          .from('profiles')
          .select('id')
          .eq('nickname', nickname)
          .maybeSingle();
      
      return result != null;
    } catch (e) {
      debugPrint('닉네임 중복 체크 에러: $e');
      return true; // 에러 발생시 안전하게 중복으로 간주
    }
  }

  // 닉네임 업데이트
  Future<bool> updateNickname(String newNickname) async {
    final user = currentUser;
    if (user == null) return false;

    try {
      // 1. 중복 체크 (다른 사용자가 사용 중인지)
      final existingUser = await _client
          .from('profiles')
          .select('id')
          .eq('nickname', newNickname)
          .neq('id', user.id)
          .maybeSingle();

      if (existingUser != null) {
        return false; // 이미 다른 사용자가 사용 중
      }

      // 2. 닉네임 업데이트 (profiles 테이블)
      await _client
          .from('profiles')
          .update({'nickname': newNickname, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', user.id);

      // 3. 사용자 메타데이터도 업데이트
      await _client.auth.updateUser(
        UserAttributes(
          data: {
            ...user.userMetadata ?? {},
            'nickname': newNickname,
          }
        )
      );

      return true;
    } catch (e) {
      debugPrint('닉네임 업데이트 에러: $e');
      return false;
    }
  }

  // 사용 가능한 닉네임인지 확인
  Future<bool> isNicknameAvailable(String nickname) async {
    // 기본 유효성 검사
    final nicknameService = NicknameGeneratorService();
    if (!nicknameService.isValidNickname(nickname)) {
      return false;
    }

    if (nicknameService.containsInappropriateContent(nickname)) {
      return false;
    }

    // 중복 체크
    return !(await checkNicknameExists(nickname));
  }

  // 새로운 OAuth 사용자를 위한 닉네임 생성 및 설정
  Future<void> _ensureUserHasNickname(User user) async {
    try {
      // profiles 테이블에서 현재 사용자 정보 조회
      final profile = await _client
          .from('profiles')
          .select('nickname')
          .eq('id', user.id)
          .maybeSingle();

      // 닉네임이 없는 경우에만 생성
      if (profile == null || profile['nickname'] == null || (profile['nickname'] as String).isEmpty) {
        debugPrint('🎯 OAuth 사용자 닉네임 생성 중...');
        
        final nicknameService = NicknameGeneratorService();
        final uniqueNickname = await nicknameService.generateUniqueNickname(
          checkDuplicate: checkNicknameExists,
        );

        // profiles 테이블 업데이트
        await _client
            .from('profiles')
            .update({'nickname': uniqueNickname})
            .eq('id', user.id);

        // 사용자 메타데이터 업데이트
        await _client.auth.updateUser(
          UserAttributes(
            data: {
              ...user.userMetadata ?? {},
              'nickname': uniqueNickname,
            }
          )
        );

        debugPrint('🎉 OAuth 사용자 닉네임 생성 완료: $uniqueNickname');
      }
    } catch (e) {
      debugPrint('OAuth 사용자 닉네임 설정 에러: $e');
    }
  }

  // User를 UserInfo로 변환
  UserInfo _convertToUserInfo(User user) {
    return UserInfo(
      id: user.id,
      name: user.userMetadata?['full_name'] ?? 
            user.userMetadata?['name'] ?? 
            user.email?.split('@')[0] ?? 
            'User',
      nickname: user.userMetadata?['nickname'] ?? 
                user.userMetadata?['full_name'] ?? 
                user.userMetadata?['name'] ?? 
                user.email?.split('@')[0] ?? 
                'User',
      email: user.email ?? '',
      photoUrl: user.userMetadata?['avatar_url'] ?? user.userMetadata?['picture'],
      provider: user.appMetadata['provider'] ?? 'email',
    );
  }

  // 인증 상태 변경 리스너
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}

// 기존 UserInfo와 AuthResult 클래스는 그대로 사용
// 사용자 정보 클래스
class UserInfo {
  final String id;
  final String name;
  final String nickname;
  final String email;
  final String? photoUrl;
  final String provider;

  UserInfo({
    required this.id,
    required this.name,
    required this.nickname,
    required this.email,
    this.photoUrl,
    required this.provider,
  });

  @override
  String toString() {
    return 'UserInfo(id: $id, name: $name, nickname: $nickname, email: $email, provider: $provider)';
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
