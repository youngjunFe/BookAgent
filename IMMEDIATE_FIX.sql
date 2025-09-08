-- 🔥 즉시 해결 - MCP 연결 안 되니까 확실한 방법으로

-- 1. 현재 문제 상황 확인
SELECT '현재 상황' as 구분;
SELECT 
    (SELECT COUNT(*) FROM auth.users) as "auth테이블사용자수",
    (SELECT COUNT(*) FROM public.profiles) as "profiles테이블사용자수";

-- 2. 누락된 사용자들 확인
SELECT '누락된 사용자들' as 구분;
SELECT u.email, u.id 
FROM auth.users u
LEFT JOIN public.profiles p ON u.id = p.id
WHERE p.id IS NULL;

-- 3. 바로 프로필 생성
INSERT INTO public.profiles (id, email, nickname, full_name, provider, created_at, updated_at)
SELECT 
    u.id,
    u.email,
    'ㅊㅊㅊ독서가' || (1000 + floor(random() * 9000))::TEXT,
    'ㅊㅊㅊ독서가' || (1000 + floor(random() * 9000))::TEXT,
    COALESCE(u.raw_app_meta_data->>'provider', 'email'),
    u.created_at,
    NOW()
FROM auth.users u
LEFT JOIN public.profiles p ON u.id = p.id
WHERE p.id IS NULL;

-- 4. 결과 확인
SELECT '생성 완료' as 구분;
SELECT email, nickname FROM public.profiles ORDER BY created_at DESC LIMIT 5;
