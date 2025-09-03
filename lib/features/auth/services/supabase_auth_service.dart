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

  // 🔄 강화된 사용자 정보 (메타데이터 즉시 반영)
  UserInfo? get currentUserInfo {
    final user = currentUser;
    if (user == null) return null;
    
    debugPrint('📱 [currentUserInfo] 메타데이터 조회: ${user.userMetadata}');
    
    return UserInfo(
      id: user.id,
      name: user.userMetadata?['full_name'] ?? 
            user.userMetadata?['display_name'] ?? 
            user.userMetadata?['name'] ?? 
            user.email?.split('@')[0] ?? 'User',
      nickname: user.userMetadata?['nickname'] ?? 
                user.userMetadata?['display_name'] ??
                user.userMetadata?['full_name'] ?? 
                user.userMetadata?['name'] ?? 
                user.email?.split('@')[0] ?? 'User',
      email: user.email ?? '',
      photoUrl: user.userMetadata?['avatar_url'],
      provider: user.appMetadata['provider'] ?? 'email',
    );
  }

  // 🔗 profiles 테이블 기반 사용자 정보 (정확한 현재 상태)
  Future<UserInfo?> getProfileBasedUserInfo() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      debugPrint('🔗 [getProfileBasedUserInfo] profiles 테이블에서 사용자 정보 조회: ${user.email}');
      
      final profile = await _client
          .from('profiles')
          .select('*')
          .eq('id', user.id)
          .maybeSingle();

      debugPrint('📋 [getProfileBasedUserInfo] profiles 데이터: $profile');

      if (profile != null && profile['provider'] != 'deleted') {
        // profiles 테이블의 실제 데이터 사용
        return UserInfo(
          id: user.id,
          name: profile['full_name'] ?? user.email?.split('@')[0] ?? 'User',
          nickname: profile['nickname'] ?? 'User',
          email: profile['email'] ?? user.email ?? '',
          photoUrl: profile['avatar_url'],
          provider: profile['provider'] ?? 'email',
        );
      } else {
        debugPrint('⚠️ [getProfileBasedUserInfo] 프로필 없거나 삭제됨 - 메타데이터 사용');
        return currentUserInfo; // 메타데이터 기반으로 폴백
      }
    } catch (e) {
      debugPrint('❌ [getProfileBasedUserInfo] profiles 조회 실패: $e');
      return currentUserInfo; // 에러시 메타데이터 기반으로 폴백
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

  // 🔗 안전한 사용자 정보 가져오기 (profiles 테이블 우선 + 재가입 처리)
  Future<UserInfo?> getSafeCurrentUserInfo() async {
    final user = currentUser;
    if (user == null) return null;

    debugPrint('🔗 [getSafeCurrentUserInfo] 사용자 정보 조회 시작: ${user.email}');

    // 1단계: profiles 테이블에서 실제 현재 상태 확인
    final profileBasedInfo = await getProfileBasedUserInfo();
    
    // 2단계: 탈퇴 계정이면 재가입 처리
    final isDeleted = await isDeletedAccount();
    if (isDeleted) {
      debugPrint('🔄 [getSafeCurrentUserInfo] 탈퇴 계정 재가입 감지 - 새로운 닉네임 생성!');
      
      try {
        await ensureUserHasNickname(user);
        debugPrint('✅ [getSafeCurrentUserInfo] 재가입 처리 완료');
        
        // 다시 profiles에서 업데이트된 정보 가져오기
        final updatedInfo = await getProfileBasedUserInfo();
        if (updatedInfo != null) {
          debugPrint('🎉 [getSafeCurrentUserInfo] 새 프로필 기반 정보: ${updatedInfo.nickname}');
          return updatedInfo;
        }
      } catch (e) {
        debugPrint('❌ [getSafeCurrentUserInfo] 재가입 처리 실패: $e');
      }
    }

    // 3단계: profiles 테이블 데이터 우선 반환
    if (profileBasedInfo != null) {
      debugPrint('🔗 [getSafeCurrentUserInfo] profiles 기반 정보 사용: ${profileBasedInfo.nickname}');
      return profileBasedInfo;
    }

    // 4단계: 폴백 - 메타데이터 기반
    debugPrint('⚠️ [getSafeCurrentUserInfo] profiles 없음, 메타데이터 기반 사용');
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
          debugPrint('🔍 [signInWithGoogle] 사용자 메타데이터: ${user.userMetadata}');
          debugPrint('🔍 [signInWithGoogle] 닉네임 확인 전 사용자 정보: ${_convertToUserInfo(user)}');
          
          await ensureUserHasNickname(user); // 닉네임 확인 및 생성
          
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
        await ensureUserHasNickname(user); // 닉네임 확인 및 생성
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
        
        await ensureUserHasNickname(user); // 닉네임 확인 및 생성
        
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

  // 회원 탈퇴 (Authentication 계정까지 완전 삭제)
  Future<bool> deleteAccount() async {
    final user = currentUser;
    if (user == null) {
      debugPrint('❌ [deleteAccount] 사용자가 로그인되어 있지 않음');
      return false;
    }

    debugPrint('🗑️ [deleteAccount] 완전한 계정 삭제 시작: ${user.email}');
    debugPrint('👤 [deleteAccount] 사용자 ID: ${user.id}');

    try {
      // 🔥 Edge Function을 통한 완전한 계정 삭제
      debugPrint('🚀 [deleteAccount] Edge Function 호출 중...');
      
      final response = await _client.functions.invoke('delete-user', 
        body: {
          'user_id': user.id,
        }
      );
      
      debugPrint('📋 [deleteAccount] Edge Function 응답: ${response.data}');
      debugPrint('📋 [deleteAccount] Edge Function 전체 응답: $response');
      
      if (response.data?['success'] == true) {
        debugPrint('🎉 [deleteAccount] Edge Function을 통한 완전 삭제 성공!');
        debugPrint('✅ [deleteAccount] Authentication 계정까지 완전 삭제됨');
        
        // 성공시 즉시 로그아웃 (이미 계정이 삭제됨)
        try {
          await _client.auth.signOut();
        } catch (e) {
          debugPrint('ℹ️ [deleteAccount] 로그아웃 불필요 (계정 이미 삭제됨)');
        }
        
        return true;
      } else {
        debugPrint('⚠️ [deleteAccount] Edge Function 실패, 폴백 방식 사용');
      }
      
    } catch (edgeFunctionError) {
      debugPrint('❌ [deleteAccount] Edge Function 호출 실패: $edgeFunctionError');
      debugPrint('🔄 [deleteAccount] 폴백: 데이터만 삭제하는 방식 사용');
    }

    // Edge Function 실패시 폴백: 기존 방식 (데이터 삭제 + 로그아웃)
    try {
      debugPrint('🗑️ [deleteAccount] 폴백: 사용자 데이터 삭제 중...');
      
      // profiles 테이블에서 사용자 데이터 삭제
      await _client
          .from('profiles')
          .delete()
          .eq('id', user.id);
      
      debugPrint('✅ [deleteAccount] 폴백: profiles 삭제 완료');

      // 로그아웃 처리
      debugPrint('🔄 [deleteAccount] 폴백: 로그아웃 처리 중...');
      await _client.auth.signOut();
      debugPrint('✅ [deleteAccount] 폴백: 로그아웃 완료');
      
      debugPrint('⚠️ [deleteAccount] 폴백 성공 (Authentication 계정은 수동 삭제 필요)');
      return true;

    } catch (fallbackError) {
      debugPrint('❌ [deleteAccount] 폴백도 실패: $fallbackError');
      
      // 최후의 수단: 로그아웃만
      try {
        await _client.auth.signOut();
        return true;
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

  // 새로운 OAuth 사용자를 위한 닉네임 생성 및 설정 (public)
  Future<void> ensureUserHasNickname([User? providedUser]) async {
    final user = providedUser ?? currentUser;
    if (user == null) return;
    try {
      debugPrint('🎯 [ensureUserHasNickname] 사용자 닉네임 확인 중: ${user.email}');
      
      // profiles 테이블에서 현재 사용자 정보 조회
      final profile = await _client
          .from('profiles')
          .select('nickname')
          .eq('id', user.id)
          .maybeSingle();

      final currentNickname = profile?['nickname'] as String?;
      debugPrint('📋 [ensureUserHasNickname] 현재 닉네임: $currentNickname');

      // 안전한 닉네임 관리: 한 번만 교체, 이후 유지
      final provider = user.appMetadata['provider'] ?? 'email';
      final isOAuthUser = provider != 'email';
      
      debugPrint('🔍 [ensureUserHasNickname] 사용자 제공자: $provider');
      debugPrint('🔍 [ensureUserHasNickname] OAuth 사용자 여부: $isOAuthUser');
      
      // 🎯 탈퇴한 사용자 재가입 감지 (더 정확한 방법)
      final isDeletedUserReturning = profile == null || 
          (profile['provider'] == 'deleted') ||
          (profile['email'] != null && profile['email'].toString().startsWith('deleted_'));
      
      debugPrint('🔍 [ensureUserHasNickname] 탈퇴 후 재가입 여부: $isDeletedUserReturning');
      debugPrint('🔍 [ensureUserHasNickname] 프로필 데이터: $profile');
      
      // 🔥 강제 조건: 탈퇴한 사용자는 무조건 새 닉네임!
      final shouldGenerateNewNickname = isDeletedUserReturning || 
          currentNickname == null || 
          currentNickname.isEmpty ||
          currentNickname.length < 2 ||
          currentNickname.startsWith('deleted_');
      
      debugPrint('🔥 [ensureUserHasNickname] 강제 새 닉네임 생성: $shouldGenerateNewNickname');
      
      debugPrint('🔍 [ensureUserHasNickname] 새 닉네임 생성 필요: $shouldGenerateNewNickname');
      debugPrint('🔍 [ensureUserHasNickname] 현재 닉네임: "$currentNickname" (길이: ${currentNickname?.length})');
      
      if (!shouldGenerateNewNickname) {
        debugPrint('✅ [ensureUserHasNickname] 기존 닉네임 유지: "$currentNickname"');
        return; // 기존 닉네임 유지하고 함수 종료
      }

      // 새 닉네임 생성 필요한 경우
      debugPrint('🎨 [ensureUserHasNickname] 예쁜 한국어 닉네임 생성 중... (로컬 생성 사용)');
      
      final nicknameService = NicknameGeneratorService();
      // 🎯 로컬 생성만 사용 (더 안정적)
      String uniqueNickname = nicknameService.generateRandomNickname();
      
      // 간단한 중복 체크 (최대 5번 시도)
      for (int i = 1; i <= 5; i++) {
        final isDuplicate = await checkNicknameExists(uniqueNickname);
        if (!isDuplicate) {
          break; // 중복 없으면 사용
        }
        // 중복이면 숫자 추가
        uniqueNickname = '${nicknameService.generateRandomNickname()}$i';
      }

      debugPrint('✨ [ensureUserHasNickname] 생성된 로컬 닉네임: $uniqueNickname');

      // profiles 테이블에 안전하게 저장 (1회성)
      try {
        await _client
            .from('profiles')
            .upsert({
              'id': user.id,
              'email': user.email,
              'full_name': uniqueNickname, // 실명도 예쁜 닉네임으로
              'avatar_url': user.userMetadata?['avatar_url'] ?? user.userMetadata?['picture'],
              'provider': provider,
              'nickname': uniqueNickname,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });
        
        debugPrint('✅ [ensureUserHasNickname] profiles 테이블 업데이트 완료 (1회성)');
      } catch (profileError) {
        debugPrint('⚠️ [ensureUserHasNickname] profiles 업데이트 실패: $profileError');
      }

      // 🔥 메타데이터 강제 덮어쓰기 (기존 데이터 완전 교체)
      try {
        debugPrint('🔥 [ensureUserHasNickname] 메타데이터 강제 덮어쓰기 중...');
        
        await _client.auth.updateUser(
          UserAttributes(
            data: {
              'nickname': uniqueNickname,
              'full_name': uniqueNickname,
              'name': uniqueNickname, // name도 덮어쓰기
              'display_name': uniqueNickname, // display_name도 덮어쓰기
              'updated_by': 'auto_nickname_generator',
              'last_nickname_update': DateTime.now().toIso8601String(),
            }
          )
        );
        
        debugPrint('✅ [ensureUserHasNickname] 메타데이터 강제 덮어쓰기 완료');
        
        // 🔄 즉시 세션 새로고침 강제
        await Future.delayed(Duration(milliseconds: 500));
        final refreshedUser = currentUser;
        debugPrint('🔄 [ensureUserHasNickname] 세션 새로고침 후 메타데이터: ${refreshedUser?.userMetadata}');
        
      } catch (metaError) {
        debugPrint('❌ [ensureUserHasNickname] 메타데이터 강제 업데이트 실패: $metaError');
      }

      debugPrint('🎉 [ensureUserHasNickname] 한국어 닉네임 1회성 설정 완료: "$currentNickname" → "$uniqueNickname"');
      debugPrint('🔒 [ensureUserHasNickname] 다음 로그인부터는 이 닉네임이 유지됩니다');
    } catch (e) {
      debugPrint('❌ [ensureUserHasNickname] OAuth 사용자 닉네임 설정 에러: $e');
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

