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

  // 사용자 정보를 UserInfo 형태로 변환 (profiles 테이블에서 닉네임 가져오기)
  UserInfo? get currentUserInfo {
    final user = currentUser;
    if (user == null) return null;
    
    return UserInfo(
      id: user.id,
      name: user.userMetadata?['full_name'] ?? user.email?.split('@')[0] ?? 'User',
      nickname: 'profiles에서 가져올 예정', // TODO: profiles 테이블에서 실시간으로 가져와야 함
      email: user.email ?? '',
      photoUrl: user.userMetadata?['avatar_url'],
      provider: user.appMetadata['provider'] ?? 'email',
    );
  }

  // nickname 필드가 없는 사용자에게 자동으로 nickname 추가
  Future<void> _ensureNicknameExists(User user) async {
    try {
      final existingName = user.userMetadata?['name'] ?? 
                          user.userMetadata?['full_name'] ?? 
                          user.email?.split('@')[0] ?? 
                          'User';
      
      debugPrint('🔧 [_ensureNicknameExists] nickname 필드 없는 사용자 발견: ${user.email}');
      debugPrint('📋 [_ensureNicknameExists] 기존 name: $existingName');
      
      // nickname 필드 추가
      await _client.auth.updateUser(
        UserAttributes(
          data: {
            ...user.userMetadata ?? {},
            'nickname': existingName,  // 기존 name을 nickname으로 복사
          }
        )
      );
      
      debugPrint('✅ [_ensureNicknameExists] nickname 필드 추가 완료: $existingName');
    } catch (e) {
      debugPrint('❌ [_ensureNicknameExists] nickname 필드 추가 실패: $e');
    }
  }

  // 탈퇴한 계정인지 확인 (보안 중요!)
  Future<bool> isDeletedAccount() async {
    final user = currentUser;
    if (user == null) return false;

    try {
      debugPrint('🔒 [isDeletedAccount] 탈퇴 계정 여부 확인: ${user.email}');
      
      final profile = await _client
          .from('profiles')
          .select('provider, email')
          .eq('id', user.id)
          .maybeSingle();

      // profiles에 없거나 provider가 'deleted'면 탈퇴한 계정
      final isDeleted = profile == null || profile['provider'] == 'deleted';
      
      debugPrint('📋 [isDeletedAccount] 프로필 상태: $profile');
      debugPrint('🔒 [isDeletedAccount] 탈퇴 계정 여부: $isDeleted');
      
      return isDeleted;
    } catch (e) {
      debugPrint('❌ [isDeletedAccount] 탈퇴 계정 확인 에러: $e');
      return false;
    }
  }

  // 안전한 사용자 정보 가져오기 (탈퇴 계정 처리 포함)
  Future<UserInfo?> getSafeCurrentUserInfo() async {
    final user = currentUser;
    if (user == null) return null;

    // 탈퇴한 계정인지 확인
    final isDeleted = await isDeletedAccount();
    if (isDeleted) {
      debugPrint('🚨 [getSafeCurrentUserInfo] 탈퇴한 계정으로 로그인 시도 감지!');
      debugPrint('🔄 [getSafeCurrentUserInfo] 자동 로그아웃 처리...');
      
      // 탈퇴한 계정이면 강제 로그아웃
      try {
        await signOut();
        return null;
      } catch (e) {
        debugPrint('❌ [getSafeCurrentUserInfo] 강제 로그아웃 실패: $e');
        return null;
      }
    }

    return currentUserInfo;
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
      debugPrint('🚀 [signUpWithEmail] 이메일 회원가입 시작: $email');
      
      // 1. 회원가입 먼저 진행
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        debugPrint('🎉 [signUpWithEmail] 회원가입 성공! 사용자 ID: ${response.user!.id}');
        
        // 간단하게 프로필 바로 생성 (아까 잘 됐던 방식)
        final nickname = 'ㅊㅊㅊ독서가${DateTime.now().millisecondsSinceEpoch % 10000}';
        
        await _client.from('profiles').insert({
          'id': response.user!.id,
          'email': response.user!.email,
          'nickname': nickname,
          'full_name': nickname,
          'provider': 'email',
        });
        
        debugPrint('✅ [signUpWithEmail] 프로필 생성 완료: $nickname');
        return AuthResult.success(_convertToUserInfo(response.user!));
      } else {
        return AuthResult.error('회원가입에 실패했습니다.');
      }
    } catch (error) {
      debugPrint('❌ [signUpWithEmail] 이메일 회원가입 에러: $error');
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
          debugPrint('🔍 [signInWithGoogle] 사용자 메타데이터: ${user.userMetadata}');
          debugPrint('🔍 [signInWithGoogle] 닉네임 확인 전 사용자 정보: ${_convertToUserInfo(user)}');
          
          // 프로필 생성 완료까지 대기
          await _createUserProfileWithRetry(user);
          
          // 충분한 대기 시간 (DB 반영 + 캐시 업데이트)
          await Future.delayed(Duration(milliseconds: 1500));
          
          // 업데이트된 사용자 정보 다시 가져오기
          final updatedUser = currentUser;
          debugPrint('🔍 [signInWithGoogle] 닉네임 확인 후 사용자 정보: ${_convertToUserInfo(updatedUser!)}');
          
          return AuthResult.success(_convertToUserInfo(updatedUser));
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
        await _createUserProfile(user); // 프로필 생성
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
        debugPrint('🔍 [signInWithKakao] 사용자 메타데이터: ${user.userMetadata}');
        debugPrint('🔍 [signInWithKakao] 닉네임 확인 전 사용자 정보: ${_convertToUserInfo(user)}');
        
        await _createUserProfile(user); // 프로필 생성
        
        // 업데이트된 사용자 정보 다시 가져오기
        final updatedUser = currentUser;
        debugPrint('🔍 [signInWithKakao] 닉네임 확인 후 사용자 정보: ${_convertToUserInfo(updatedUser!)}');
        
        return AuthResult.success(_convertToUserInfo(updatedUser));
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

  // 회원 탈퇴 (간단하고 확실한 버전)
  Future<bool> deleteAccount() async {
    final user = currentUser;
    if (user == null) {
      debugPrint('❌ [deleteAccount] 사용자가 로그인되어 있지 않음');
      return false;
    }

    debugPrint('🗑️ [deleteAccount] 간단한 탈퇴 처리 시작: ${user.email}');
    debugPrint('👤 [deleteAccount] 사용자 ID: ${user.id}');

    try {
      // 🎯 핵심만 간단하게: profiles 데이터 삭제 + 로그아웃
      
      // 1. profiles 테이블에서 사용자 데이터 삭제 (강화된 방법)
      debugPrint('🗑️ [deleteAccount] 사용자 프로필 삭제 중...');
      
      // 먼저 현재 프로필 존재 확인
      final existingProfile = await _client
          .from('profiles')
          .select('*')
          .eq('id', user.id)
          .maybeSingle();
      
      debugPrint('📋 [deleteAccount] 삭제 전 프로필 확인: $existingProfile');
      
      if (existingProfile != null) {
        // 여러 방법으로 삭제 시도
        try {
          // 방법 1: 일반 DELETE
          final deleteResult = await _client
              .from('profiles')
              .delete()
              .eq('id', user.id);
          
          debugPrint('📋 [deleteAccount] DELETE 결과: $deleteResult');
          
          // 삭제 후 확인
          final checkAfterDelete = await _client
              .from('profiles')
              .select('id')
              .eq('id', user.id)
              .maybeSingle();
          
          if (checkAfterDelete == null) {
            debugPrint('✅ [deleteAccount] 프로필 삭제 성공 확인!');
          } else {
            debugPrint('⚠️ [deleteAccount] 프로필이 여전히 존재함, 다른 방법 시도...');
            
            // 방법 2: UPDATE로 데이터 무력화
            await _client
                .from('profiles')
                .update({
                  'email': 'deleted_${user.id}@deleted.com',
                  'nickname': 'deleted_${user.id.substring(0, 8)}',
                  'full_name': '탈퇴된계정',
                  'provider': 'deleted',
                  'updated_at': DateTime.now().toIso8601String(),
                })
                .eq('id', user.id);
            
            debugPrint('✅ [deleteAccount] 프로필 비활성화 완료');
          }
          
        } catch (deleteError) {
          debugPrint('❌ [deleteAccount] 일반 삭제 실패: $deleteError');
          
          // 방법 3: RPC 함수 사용 (강제)
          try {
            await _client.rpc('force_delete_user_profile', params: {
              'user_id': user.id
            });
            debugPrint('✅ [deleteAccount] RPC를 통한 강제 삭제 완료');
          } catch (rpcError) {
            debugPrint('⚠️ [deleteAccount] RPC 삭제도 실패: $rpcError');
          }
        }
      } else {
        debugPrint('ℹ️ [deleteAccount] 프로필이 이미 없음 (이미 삭제된 상태)');
      }

      // 2. 메타데이터도 완전 삭제 (중요!)
      debugPrint('🗑️ [deleteAccount] 메타데이터 완전 삭제 중...');
      
      await _client.auth.updateUser(
        UserAttributes(
          data: {
            'account_status': 'deleted',
            'nickname': null,
            'full_name': null,
            'name': null,
            'display_name': null,
          }
        )
      );
      
      debugPrint('✅ [deleteAccount] 메타데이터 삭제 완료');

      // 3. 로그아웃 처리
      debugPrint('🔄 [deleteAccount] 로그아웃 처리 중...');
      await _client.auth.signOut();
      debugPrint('✅ [deleteAccount] 로그아웃 완료');
      
      debugPrint('🎉 [deleteAccount] 탈퇴 처리 성공!');
      return true;

    } catch (e) {
      debugPrint('❌ [deleteAccount] 탈퇴 처리 에러: $e');
      debugPrint('🔍 [deleteAccount] 에러 타입: ${e.runtimeType}');
      debugPrint('📄 [deleteAccount] 에러 상세: ${e.toString()}');
      
      // 에러가 발생해도 로그아웃은 시도
      try {
        debugPrint('🔄 [deleteAccount] 에러 발생, 로그아웃만 시도...');
        await _client.auth.signOut();
        debugPrint('✅ [deleteAccount] 로그아웃 완료 (에러 후)');
        return true; // 로그아웃은 성공했으므로 true
      } catch (logoutError) {
        debugPrint('❌ [deleteAccount] 로그아웃도 실패: $logoutError');
        return false;
      }
    }
  }

  // 닉네임 중복 체크
  Future<bool> checkNicknameExists(String nickname) async {
    try {
      debugPrint('🔍 [checkNicknameExists] 닉네임 중복 체크: $nickname');
      
      final result = await _client
          .from('profiles')
          .select('id')
          .eq('nickname', nickname)
          .maybeSingle();
      
      final exists = result != null;
      debugPrint('📋 [checkNicknameExists] 중복 체크 결과: $exists (결과: $result)');
      return exists;
    } catch (e) {
      debugPrint('❌ [checkNicknameExists] 닉네임 중복 체크 에러: $e');
      debugPrint('🔍 [checkNicknameExists] 에러 타입: ${e.runtimeType}');
      
      // profiles 테이블이 없는 경우 (테이블 미생성)
      if (e.toString().contains('relation "public.profiles" does not exist') || 
          e.toString().contains('does not exist')) {
        debugPrint('⚠️ [checkNicknameExists] profiles 테이블이 없습니다. ADD_NICKNAME_FEATURE.sql을 실행해주세요!');
        return false; // 테이블이 없으면 중복이 아님으로 처리
      }
      
      // 권한 문제인 경우
      if (e.toString().contains('permission denied') || e.toString().contains('RLS')) {
        debugPrint('⚠️ [checkNicknameExists] RLS 권한 문제가 있습니다.');
      }
      
      return true; // 기타 에러 발생시 안전하게 중복으로 간주
    }
  }

  // 닉네임 업데이트
  Future<bool> updateNickname(String newNickname) async {
    final user = currentUser;
    if (user == null) {
      debugPrint('❌ [updateNickname] 사용자가 로그인되어 있지 않음');
      return false;
    }

    debugPrint('🔄 [updateNickname] 닉네임 업데이트 시작: $newNickname');
    debugPrint('👤 [updateNickname] 사용자 ID: ${user.id}');

    try {
      // 1. profiles 테이블 존재 확인 및 현재 사용자 프로필 체크
      debugPrint('🔍 [updateNickname] 현재 사용자 프로필 조회 중...');
      final currentProfile = await _client
          .from('profiles')
          .select('nickname')
          .eq('id', user.id)
          .maybeSingle();
      
      debugPrint('📋 [updateNickname] 현재 프로필: $currentProfile');

      // 2. 중복 체크 (다른 사용자가 사용 중인지)
      debugPrint('🔍 [updateNickname] 중복 닉네임 체크 중...');
      final existingUser = await _client
          .from('profiles')
          .select('id')
          .eq('nickname', newNickname)
          .neq('id', user.id)
          .maybeSingle();

      if (existingUser != null) {
        debugPrint('❌ [updateNickname] 중복된 닉네임: ${existingUser['id']}가 이미 사용 중');
        return false;
      }

      debugPrint('✅ [updateNickname] 닉네임 중복 없음, 업데이트 진행');

      // 3. 닉네임 업데이트 (profiles 테이블)
      debugPrint('🔄 [updateNickname] profiles 테이블 업데이트 중...');
      await _client
          .from('profiles')
          .update({'nickname': newNickname, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', user.id);

      debugPrint('✅ [updateNickname] profiles 테이블 업데이트 완료');

      // 4. 사용자 메타데이터도 업데이트
      debugPrint('🔄 [updateNickname] 사용자 메타데이터 업데이트 중...');
      await _client.auth.updateUser(
        UserAttributes(
          data: {
            ...user.userMetadata ?? {},
            'nickname': newNickname,
          }
        )
      );

      debugPrint('🎉 [updateNickname] 닉네임 업데이트 성공: $newNickname');
      return true;
    } catch (e) {
      debugPrint('❌ [updateNickname] 닉네임 업데이트 에러: $e');
      debugPrint('🔍 [updateNickname] 에러 타입: ${e.runtimeType}');
      debugPrint('📄 [updateNickname] 에러 상세: ${e.toString()}');
      
      // profiles 테이블이 없는 경우
      if (e.toString().contains('relation "public.profiles" does not exist') || 
          e.toString().contains('does not exist')) {
        debugPrint('⚠️ [updateNickname] profiles 테이블이 없습니다!');
        debugPrint('🔧 [updateNickname] 메타데이터만 업데이트하여 임시 처리합니다.');
        
        try {
          // profiles 테이블이 없으면 메타데이터만 업데이트
          await _client.auth.updateUser(
            UserAttributes(
              data: {
                ...user.userMetadata ?? {},
                'nickname': newNickname,
              }
            )
          );
          
          debugPrint('✅ [updateNickname] 메타데이터 업데이트 성공 (임시 처리)');
          debugPrint('⚠️ [updateNickname] 완전한 기능을 위해 ADD_NICKNAME_FEATURE.sql을 실행해주세요!');
          return true;
        } catch (metadataError) {
          debugPrint('❌ [updateNickname] 메타데이터 업데이트도 실패: $metadataError');
          return false;
        }
      }
      
      // 권한 문제인 경우
      if (e.toString().contains('permission denied') || e.toString().contains('RLS')) {
        debugPrint('⚠️ [updateNickname] RLS 권한 문제입니다. Supabase 정책을 확인해주세요.');
      }
      
      return false;
    }
  }

  // 사용 가능한 닉네임인지 확인
  Future<bool> isNicknameAvailable(String nickname) async {
    final user = currentUser;
    if (user == null) {
      debugPrint('❌ [isNicknameAvailable] 사용자가 로그인되어 있지 않음');
      return false;
    }

    debugPrint('🔍 [isNicknameAvailable] 닉네임 사용 가능 여부 확인: $nickname');
    debugPrint('👤 [isNicknameAvailable] 현재 사용자 ID: ${user.id}');

    // 기본 유효성 검사
    final nicknameService = NicknameGeneratorService();
    if (!nicknameService.isValidNickname(nickname)) {
      debugPrint('❌ [isNicknameAvailable] 유효하지 않은 닉네임 형식');
      return false;
    }

    if (nicknameService.containsInappropriateContent(nickname)) {
      debugPrint('❌ [isNicknameAvailable] 부적절한 내용 포함');
      return false;
    }

    // 중복 체크 (현재 사용자 제외)
    try {
      final existingUser = await _client
          .from('profiles')
          .select('id')
          .eq('nickname', nickname)
          .neq('id', user.id) // 현재 사용자는 제외
          .maybeSingle();

      final isAvailable = existingUser == null;
      debugPrint('✅ [isNicknameAvailable] 중복 체크 결과: $isAvailable');
      debugPrint('📋 [isNicknameAvailable] 기존 사용자: $existingUser');
      
      return isAvailable;
    } catch (e) {
      debugPrint('❌ [isNicknameAvailable] 중복 체크 에러: $e');
      return false; // 에러 발생시 안전하게 사용 불가로 처리
    }
  }

  // 재시도 로직이 포함된 프로필 생성
  Future<void> _createUserProfileWithRetry(User user) async {
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        debugPrint('🔄 [_createUserProfileWithRetry] 시도 $attempt/3');
        await _createUserProfile(user);
        debugPrint('✅ [_createUserProfileWithRetry] $attempt번째 시도에서 성공');
        return; // 성공하면 종료
      } catch (e) {
        debugPrint('❌ [_createUserProfileWithRetry] $attempt번째 시도 실패: $e');
        if (attempt < 3) {
          await Future.delayed(Duration(milliseconds: 500)); // 0.5초 대기
        }
      }
    }
    debugPrint('💥 [_createUserProfileWithRetry] 3번 모두 실패, 포기');
  }

  // 사용자 프로필 생성 또는 업데이트 (탈퇴 후 재가입 대응)
  Future<void> _createUserProfile(User user) async {
    try {
      debugPrint('🔧 [_createUserProfile] 프로필 확인/생성 시작: ${user.email}');
      
      // 기존 프로필 확인 (닉네임까지 포함해서)
      final existingProfile = await _client
          .from('profiles')
          .select('id, nickname')
          .eq('id', user.id)
          .maybeSingle();
      
      // 닉네임 생성
      final nicknameService = NicknameGeneratorService();
      String nickname = nicknameService.generateRandomNickname();
      
      // 중복 체크 (최대 5번 시도)
      for (int i = 1; i <= 5; i++) {
        final isDuplicate = await checkNicknameExists(nickname);
        if (!isDuplicate) {
          break;
        }
        nickname = '${nicknameService.generateRandomNickname()}$i';
      }
      
      debugPrint('🎯 [_createUserProfile] 생성된 닉네임: $nickname');
      
      if (existingProfile != null) {
        // 프로필이 이미 있으면 업데이트 (탈퇴 후 재가입 대응)
        debugPrint('🔄 [_createUserProfile] 기존 프로필 업데이트 (재가입 처리)');
        
        await _client.from('profiles').update({
          'email': user.email,
          'full_name': nickname,
          'nickname': nickname,
          'provider': user.appMetadata['provider'] ?? 'email',
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', user.id);
        
        debugPrint('✅ [_createUserProfile] 프로필 업데이트 완료: $nickname');
        
      } else {
        // 프로필이 없으면 새로 생성
        debugPrint('📝 [_createUserProfile] 새 프로필 생성');
        
        await _client.from('profiles').insert({
          'id': user.id,
          'email': user.email,
          'full_name': nickname,
          'nickname': nickname,
          'provider': user.appMetadata['provider'] ?? 'email',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        
        debugPrint('✅ [_createUserProfile] 프로필 생성 완료: $nickname');
      }
      
    } catch (e) {
      debugPrint('❌ [_createUserProfile] 프로필 처리 실패: $e');
      // 프로필 생성 실패해도 로그인은 계속 진행
    }
  }

  // 이전 함수 (더 이상 사용하지 않음)
  Future<void> _ensureUserHasNickname_DEPRECATED(User user) async {
    try {
      debugPrint('🎯 [_ensureUserHasNickname] 사용자 닉네임 확인 중: ${user.email}');
      
      // profiles 테이블에서 현재 사용자 정보 조회
      final profile = await _client
          .from('profiles')
          .select('nickname')
          .eq('id', user.id)
          .maybeSingle();

      final currentNickname = profile?['nickname'] as String?;
      debugPrint('📋 [_ensureUserHasNickname] 현재 닉네임: $currentNickname');

      // 안전한 닉네임 관리: 한 번만 교체, 이후 유지
      final provider = user.appMetadata['provider'] ?? 'email';
      final isOAuthUser = provider != 'email';
      
      debugPrint('🔍 [_ensureUserHasNickname] 사용자 제공자: $provider');
      debugPrint('🔍 [_ensureUserHasNickname] OAuth 사용자 여부: $isOAuthUser');
      
      // 🎯 탈퇴한 사용자 재가입 감지: profiles 없으면 = 탈퇴 후 재가입
      final isDeletedUserReturning = profile == null; // profiles에 없음 = 탈퇴한 사용자
      
      debugPrint('🔍 [_ensureUserHasNickname] 탈퇴 후 재가입 여부: $isDeletedUserReturning');
      
      // 새 닉네임 생성 조건 (스마트하게 판단)
      final shouldGenerateNewNickname = 
          // 1. 탈퇴한 사용자의 재가입 (무조건 새 닉네임!)
          isDeletedUserReturning ||
          // 2. 닉네임 자체가 없거나 비어있음
          currentNickname == null || 
          currentNickname.isEmpty ||
          // 3. 너무 짧은 임시 닉네임
          currentNickname.length < 2;
      
      debugPrint('🔍 [_ensureUserHasNickname] 새 닉네임 생성 필요: $shouldGenerateNewNickname');
      debugPrint('🔍 [_ensureUserHasNickname] 현재 닉네임: "$currentNickname" (길이: ${currentNickname?.length})');
      
      if (!shouldGenerateNewNickname) {
        debugPrint('✅ [_ensureUserHasNickname] 기존 닉네임 유지: "$currentNickname"');
        return; // 기존 닉네임 유지하고 함수 종료
      }

      // DB 트리거가 자동으로 프로필을 생성했을 것이므로, 잠시 대기 후 확인
      debugPrint('⏳ [_ensureUserHasNickname] DB 트리거 처리 대기 중...');
      await Future.delayed(Duration(seconds: 1)); // 트리거 처리 시간 대기
      
      // 프로필이 생성되었는지 다시 확인
      try {
        final updatedProfile = await _client
            .from('profiles')
            .select('nickname, full_name')
            .eq('id', user.id)
            .maybeSingle();
        
        if (updatedProfile != null && updatedProfile['nickname'] != null) {
          debugPrint('✅ [_ensureUserHasNickname] DB 트리거로 생성된 프로필 확인: ${updatedProfile['nickname']}');
          return;
        }
      } catch (e) {
        debugPrint('⚠️ [_ensureUserHasNickname] 프로필 확인 실패: $e');
      }

      // 만약 트리거가 실패했다면 기본 처리 (보조적으로만)
      debugPrint('🔄 [_ensureUserHasNickname] 트리거 실패시 보조 처리...');
      try {
        await _client.auth.updateUser(
          UserAttributes(
            data: {
              'needs_profile': 'true', // 트리거 실패 마커
            }
          )
        );
        
        debugPrint('⚠️ [_ensureUserHasNickname] 트리거 실패 마커 설정 완료');
      } catch (metaError) {
        debugPrint('⚠️ [_ensureUserHasNickname] 메타데이터 업데이트 실패: $metaError');
      }

      debugPrint('⚠️ [_ensureUserHasNickname] DB 트리거 처리 필요');
    } catch (e) {
      debugPrint('❌ [_ensureUserHasNickname] OAuth 사용자 닉네임 설정 에러: $e');
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
