-- 🔥 직접적인 해결책 - 더 이상 복잡하게 하지 말고 바로 해결

-- 1. 현재 상황 빠르게 확인
SELECT 
    (SELECT COUNT(*) FROM auth.users) as auth_users,
    (SELECT COUNT(*) FROM public.profiles) as profiles;

-- 2. 누락된 사용자들 즉시 확인
SELECT 'auth.users에 있지만 profiles에 없는 사용자들' as 제목;
SELECT u.email, u.id, u.created_at
FROM auth.users u
LEFT JOIN public.profiles p ON u.id = p.id
WHERE p.id IS NULL
ORDER BY u.created_at DESC;

-- 3. 바로 수동으로 프로필 생성
DO $$
DECLARE
    missing_user RECORD;
    new_nickname TEXT;
    created_count INT := 0;
BEGIN
    FOR missing_user IN
        SELECT u.id, u.email, u.created_at, u.raw_app_meta_data
        FROM auth.users u
        LEFT JOIN public.profiles p ON u.id = p.id
        WHERE p.id IS NULL
    LOOP
        new_nickname := '독서가' || floor(random() * 9999 + 1000)::TEXT;
        
        -- 중복 방지
        WHILE EXISTS (SELECT 1 FROM public.profiles WHERE nickname = new_nickname) LOOP
            new_nickname := '독서가' || floor(random() * 9999 + 1000)::TEXT;
        END LOOP;
        
        -- 직접 삽입
        INSERT INTO public.profiles (
            id, email, nickname, full_name, provider, created_at, updated_at
        ) VALUES (
            missing_user.id,
            missing_user.email,
            new_nickname,
            new_nickname,
            COALESCE(missing_user.raw_app_meta_data->>'provider', 'email'),
            missing_user.created_at,
            NOW()
        );
        
        created_count := created_count + 1;
        RAISE NOTICE '✅ 프로필 생성: % -> %', missing_user.email, new_nickname;
    END LOOP;
    
    RAISE NOTICE '🎉 총 % 개 프로필 생성 완료!', created_count;
END $$;

-- 4. 최종 결과 확인
SELECT 
    '최종 결과' as 구분,
    (SELECT COUNT(*) FROM auth.users) as "전체사용자",
    (SELECT COUNT(*) FROM public.profiles) as "프로필보유자",
    (SELECT COUNT(*) FROM auth.users) - (SELECT COUNT(*) FROM public.profiles) as "누락된프로필";

-- 5. 최근 프로필들 확인
SELECT '생성된 프로필들' as 제목;
SELECT email, nickname, created_at 
FROM public.profiles 
ORDER BY created_at DESC 
LIMIT 5;
