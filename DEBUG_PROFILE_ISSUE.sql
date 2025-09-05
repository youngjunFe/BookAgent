-- 🔍 프로필 생성 문제 정확한 진단
-- Flutter 앱에서 왜 프로필이 생성/업데이트되지 않는지 확인

-- =============================================================================
-- 1. 현재 profiles 테이블 구조 확인
-- =============================================================================

SELECT '📋 ========== profiles 테이블 구조 ==========' as 테이블구조;

SELECT 
    column_name as "컬럼명",
    data_type as "타입",
    is_nullable as "NULL허용",
    column_default as "기본값",
    character_maximum_length as "최대길이"
FROM information_schema.columns 
WHERE table_name = 'profiles' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- =============================================================================
-- 2. RLS 정책들 확인 (중요!)
-- =============================================================================

SELECT '🔒 ========== profiles RLS 정책들 ==========' as RLS정책;

SELECT 
    policyname as "정책명",
    cmd as "명령타입",
    permissive as "허용타입",
    roles as "적용역할",
    qual as "조건"
FROM pg_policies 
WHERE tablename = 'profiles' 
AND schemaname = 'public';

-- =============================================================================
-- 3. 현재 데이터 상황
-- =============================================================================

DO $$
DECLARE
    auth_count INT;
    profile_count INT;
    missing_count INT;
BEGIN
    SELECT COUNT(*) INTO auth_count FROM auth.users;
    SELECT COUNT(*) INTO profile_count FROM public.profiles;
    missing_count := auth_count - profile_count;
    
    RAISE NOTICE '📊 현재 데이터: auth.users = %, profiles = %, 누락 = %', auth_count, profile_count, missing_count;
END $$;

-- =============================================================================
-- 4. 최근 사용자들 상세 확인
-- =============================================================================

SELECT '👥 ========== 최근 사용자 상세 현황 ==========' as 사용자현황;

SELECT 
    u.email as "이메일",
    u.created_at as "가입일시",
    u.raw_app_meta_data->>'provider' as "제공자",
    p.nickname as "닉네임",
    p.created_at as "프로필생성일시",
    CASE 
        WHEN p.id IS NULL THEN '❌ 프로필없음'
        WHEN p.nickname IS NULL THEN '⚠️ 닉네임없음'
        ELSE '✅ 정상'
    END as "상태"
FROM auth.users u
LEFT JOIN public.profiles p ON u.id = p.id
ORDER BY u.created_at DESC
LIMIT 10;

-- =============================================================================
-- 5. 간단한 테스트 INSERT (권한 확인)
-- =============================================================================

-- 임시 테스트용 프로필 삽입 시도
DO $$
DECLARE
    test_result TEXT;
BEGIN
    BEGIN
        -- 테스트 프로필 생성 시도
        INSERT INTO public.profiles (
            id,
            email, 
            nickname,
            full_name,
            created_at,
            updated_at
        ) VALUES (
            gen_random_uuid(), -- 임시 UUID
            'test@example.com',
            '테스트닉네임' || floor(random() * 1000)::TEXT,
            '테스트사용자',
            NOW(),
            NOW()
        );
        
        test_result := '✅ INSERT 성공 - 권한 문제 없음';
        
        -- 테스트 데이터 즉시 삭제
        DELETE FROM public.profiles WHERE email = 'test@example.com';
        
    EXCEPTION WHEN OTHERS THEN
        test_result := '❌ INSERT 실패: ' || SQLERRM;
    END;
    
    RAISE NOTICE '🧪 테스트 결과: %', test_result;
END $$;

-- =============================================================================
-- 6. 현재 사용자 세션 권한 확인
-- =============================================================================

SELECT '🔑 ========== 현재 세션 권한 ==========' as 세션권한;

SELECT 
    current_user as "현재사용자",
    session_user as "세션사용자", 
    current_setting('role') as "현재역할";

-- 현재 사용자가 profiles 테이블에 접근 가능한지 확인
SELECT 
    has_table_privilege('public.profiles', 'INSERT') as "INSERT권한",
    has_table_privilege('public.profiles', 'UPDATE') as "UPDATE권한",
    has_table_privilege('public.profiles', 'SELECT') as "SELECT권한";

-- =============================================================================
-- 7. 강제로 누락된 프로필 수동 생성 (권한 문제 우회)
-- =============================================================================

DO $$
DECLARE
    missing_user RECORD;
    user_nick TEXT;
    created_count INT := 0;
BEGIN
    RAISE NOTICE '🛠️ 강제로 누락된 프로필들을 생성합니다...';
    
    -- service_role 권한으로 강제 생성
    FOR missing_user IN
        SELECT u.id, u.email, u.created_at, u.raw_app_meta_data
        FROM auth.users u
        LEFT JOIN public.profiles p ON u.id = p.id
        WHERE p.id IS NULL
        ORDER BY u.created_at DESC
    LOOP
        user_nick := '독서가' || (floor(random() * 9999) + 1000)::TEXT;
        
        -- 중복 체크
        WHILE EXISTS (SELECT 1 FROM public.profiles WHERE nickname = user_nick) LOOP
            user_nick := '독서가' || (floor(random() * 9999) + 1000)::TEXT;
        END LOOP;
        
        -- 강제 삽입
        BEGIN
            INSERT INTO public.profiles (
                id, email, nickname, full_name, provider, created_at, updated_at
            ) VALUES (
                missing_user.id,
                missing_user.email,
                user_nick,
                user_nick,
                COALESCE(missing_user.raw_app_meta_data->>'provider', 'email'),
                missing_user.created_at,
                NOW()
            );
            
            created_count := created_count + 1;
            RAISE NOTICE '✅ 강제 프로필 생성: % -> %', missing_user.email, user_nick;
            
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '❌ 강제 생성도 실패: % (에러: %)', missing_user.email, SQLERRM;
        END;
    END LOOP;
    
    RAISE NOTICE '🎉 강제로 % 개 프로필 생성 완료', created_count;
END $$;

SELECT '🔍 이제 다시 재가입 테스트해보세요!' as 안내메시지;
