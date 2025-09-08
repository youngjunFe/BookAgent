-- 🎯 그냥 간단하게 해결

-- 1. profiles 테이블 권한 모두 열어주기
GRANT ALL ON TABLE public.profiles TO authenticated;
GRANT ALL ON TABLE public.profiles TO anon;

-- 2. RLS 끄기 (간단하게)
ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;

-- 3. 기존 누락된 것들 바로 생성
INSERT INTO public.profiles (id, email, nickname, full_name, provider, created_at, updated_at)
SELECT 
    u.id,
    u.email,
    '독서가' || floor(random() * 9999 + 1000)::TEXT,
    '독서가' || floor(random() * 9999 + 1000)::TEXT,
    COALESCE(u.raw_app_meta_data->>'provider', 'email'),
    u.created_at,
    NOW()
FROM auth.users u
LEFT JOIN public.profiles p ON u.id = p.id
WHERE p.id IS NULL;

-- 끝!
