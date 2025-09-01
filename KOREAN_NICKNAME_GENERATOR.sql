-- 🇰🇷 한국어 닉네임 자동 생성 시스템 (API 없이 자체 구현)
-- 귀여운 한국어 조합으로 자동 닉네임 생성

-- =============================================================================
-- 1. 한국어 단어 조합 닉네임 생성 함수
-- =============================================================================

CREATE OR REPLACE FUNCTION generate_korean_nickname(user_id UUID DEFAULT NULL)
RETURNS TEXT AS $$
DECLARE
    -- 형용사 배열
    adjectives TEXT[] := ARRAY[
        '귀여운', '사랑스러운', '멋진', '아름다운', '즐거운', '행복한', '신나는', '밝은',
        '따뜻한', '포근한', '달콤한', '부드러운', '고요한', '평화로운', '활기찬', '생기발랄한',
        '우아한', '세련된', '독특한', '특별한', '소중한', '빛나는', '반짝이는', '신비한',
        '환상적인', '매력적인', '로맨틱한', '상쾌한', '청순한', '완벽한', '꿈같은', '행운의',
        '축복받은', '기쁜', '감사한', '만족한', '든든한', '믿음직한', '친근한', '상냥한',
        '다정한', '순수한', '깨끗한', '맑은', '투명한', '선명한'
    ];
    
    -- 동물 배열
    animals TEXT[] := ARRAY[
        '고양이', '강아지', '토끼', '곰', '여우', '사자', '호랑이', '판다',
        '코알라', '다람쥐', '햄스터', '고슴도치', '펭귄', '돌고래', '고래', '물개',
        '사슴', '늑대', '독수리', '부엉이', '참새', '비둘기', '백조', '기러기',
        '나비', '벌', '개미', '무당벌레', '잠자리', '거북이', '달팽이', '물고기',
        '상어', '문어', '새우', '게', '해파리', '불가사리', '말', '양', '염소', '소',
        '돼지', '닭', '오리', '거위', '원숭이', '코끼리', '기린'
    ];
    
    -- 사물/개념 배열
    objects TEXT[] := ARRAY[
        '별', '달', '태양', '구름', '바다', '산', '강', '꽃', '나무', '잎',
        '책', '연필', '붓', '음표', '멜로디', '하트', '다이아', '크리스탈', '보석', '진주',
        '캔디', '초콜릿', '케이크', '쿠키', '아이스크림', '라떼', '차', '꿀', '설탕', '바닐라',
        '무지개', '눈', '비', '바람', '햇살', '향기', '미소', '웃음', '꿈', '희망',
        '마법', '기적', '천사', '요정', '공주', '왕자', '여왕', '왕', '기사',
        '성', '궁전', '정원', '숲', '섬', '동굴', '다리', '탑', '집', '방'
    ];
    
    -- 색깔 배열
    colors TEXT[] := ARRAY[
        '빨간', '주황', '노란', '초록', '파란', '보라', '분홍', '흰',
        '검은', '회색', '갈색', '금색', '은색', '청록', '라임', '민트',
        '복숭아', '연두', '하늘', '바다', '라벤더', '로즈', '체리', '딸기',
        '레몬', '오렌지', '바나나', '포도', '블루베리', '자두', '수박', '키위'
    ];
    
    -- 감정/상태 배열
    emotions TEXT[] := ARRAY[
        '꿈꾸는', '춤추는', '노래하는', '웃는', '잠자는', '뛰어다니는', '날아다니는', '헤엄치는',
        '생각하는', '공부하는', '읽는', '그리는', '만드는', '요리하는', '여행하는', '모험하는',
        '탐험하는', '발견하는', '찾아가는', '기다리는', '바라는', '소망하는', '응원하는', '격려하는',
        '도와주는', '나누는', '선물하는', '축하하는', '감사하는', '사랑하는', '아껴주는', '보살피는'
    ];
    
    -- 변수들
    pattern_num INTEGER;
    adj_idx INTEGER;
    noun_idx INTEGER; 
    final_nickname TEXT;
    counter INTEGER := 1;
    seed_value BIGINT;
BEGIN
    -- 사용자 ID 기반 시드 생성 (없으면 현재 시간 사용)
    IF user_id IS NOT NULL THEN
        seed_value := ('x' || lpad(substring(user_id::text, 1, 8), 8, '0'))::bit(32)::bigint;
    ELSE
        seed_value := EXTRACT(EPOCH FROM NOW())::bigint;
    END IF;
    
    -- 의사 랜덤 패턴 선택 (1-5)
    pattern_num := (seed_value % 5) + 1;
    
    CASE pattern_num
        WHEN 1 THEN
            -- 형용사 + 동물
            adj_idx := (seed_value % array_length(adjectives, 1)) + 1;
            noun_idx := ((seed_value / 100) % array_length(animals, 1)) + 1;
            final_nickname := adjectives[adj_idx] || animals[noun_idx];
            
        WHEN 2 THEN
            -- 색깔 + 사물
            adj_idx := (seed_value % array_length(colors, 1)) + 1;
            noun_idx := ((seed_value / 100) % array_length(objects, 1)) + 1;
            final_nickname := colors[adj_idx] || objects[noun_idx];
            
        WHEN 3 THEN
            -- 감정 + 동물
            adj_idx := (seed_value % array_length(emotions, 1)) + 1;
            noun_idx := ((seed_value / 100) % array_length(animals, 1)) + 1;
            final_nickname := emotions[adj_idx] || animals[noun_idx];
            
        WHEN 4 THEN
            -- 형용사 + 사물
            adj_idx := (seed_value % array_length(adjectives, 1)) + 1;
            noun_idx := ((seed_value / 100) % array_length(objects, 1)) + 1;
            final_nickname := adjectives[adj_idx] || objects[noun_idx];
            
        ELSE
            -- 색깔 + 동물
            adj_idx := (seed_value % array_length(colors, 1)) + 1;
            noun_idx := ((seed_value / 100) % array_length(animals, 1)) + 1;
            final_nickname := colors[adj_idx] || animals[noun_idx];
    END CASE;
    
    -- 중복 체크하며 고유 닉네임 생성
    WHILE EXISTS (SELECT 1 FROM public.profiles WHERE nickname = final_nickname) LOOP
        -- 카운터를 추가하여 고유성 보장
        final_nickname := CASE pattern_num
            WHEN 1 THEN adjectives[adj_idx] || animals[noun_idx] || counter::TEXT
            WHEN 2 THEN colors[adj_idx] || objects[noun_idx] || counter::TEXT
            WHEN 3 THEN emotions[adj_idx] || animals[noun_idx] || counter::TEXT
            WHEN 4 THEN adjectives[adj_idx] || objects[noun_idx] || counter::TEXT
            ELSE colors[adj_idx] || animals[noun_idx] || counter::TEXT
        END;
        
        counter := counter + 1;
        
        -- 무한 루프 방지
        IF counter > 999 THEN
            final_nickname := '독서가' || (seed_value % 9999 + 1)::TEXT;
            EXIT;
        END IF;
    END LOOP;
    
    RETURN final_nickname;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- 2. 기존 사용자들을 profiles 테이블에 추가 (한국어 닉네임 사용)
-- =============================================================================

-- auth.users에 있지만 profiles에 없는 사용자들을 찾아서 추가
INSERT INTO public.profiles (id, email, full_name, provider, nickname, created_at, updated_at)
SELECT 
    u.id,
    u.email,
    COALESCE(u.raw_user_meta_data->>'full_name', u.raw_user_meta_data->>'name', 
             CASE WHEN u.email IS NOT NULL THEN split_part(u.email, '@', 1) 
                  ELSE '사용자' END) as full_name,
    COALESCE(u.raw_app_meta_data->>'provider', 'email') as provider,
    -- 🇰🇷 한국어 닉네임 자동 생성!
    generate_korean_nickname(u.id) as nickname,
    u.created_at,
    u.updated_at
FROM auth.users u
WHERE u.id NOT IN (SELECT id FROM public.profiles WHERE id IS NOT NULL)
ON CONFLICT (id) DO NOTHING;

-- =============================================================================
-- 3. 기존 영어/단조로운 닉네임들을 한국어로 교체 (선택사항)
-- =============================================================================

-- 기존 사용자 중 단조로운 닉네임을 가진 사용자들을 한국어 닉네임으로 업데이트
UPDATE public.profiles 
SET nickname = generate_korean_nickname(id),
    updated_at = NOW()
WHERE nickname IS NULL 
   OR nickname = '' 
   OR nickname LIKE '독서가%'
   OR nickname LIKE '%user%'
   OR nickname LIKE '%User%'
   OR nickname LIKE '카카오유저%'
   OR nickname LIKE '구글유저%'
   OR nickname LIKE '애플유저%';

-- =============================================================================
-- 4. 중복 닉네임 정리 (한국어 닉네임으로)
-- =============================================================================

DO $$
DECLARE
    duplicate_record RECORD;
    new_nickname TEXT;
BEGIN
    FOR duplicate_record IN
        SELECT nickname, array_agg(id ORDER BY created_at) as user_ids
        FROM public.profiles 
        WHERE nickname IS NOT NULL
        GROUP BY nickname 
        HAVING COUNT(*) > 1
    LOOP
        -- 첫 번째 사용자는 그대로 두고, 나머지는 새 한국어 닉네임 생성
        FOR i IN 2..array_length(duplicate_record.user_ids, 1)
        LOOP
            new_nickname := generate_korean_nickname(duplicate_record.user_ids[i]);
            
            UPDATE public.profiles 
            SET nickname = new_nickname, updated_at = NOW()
            WHERE id = duplicate_record.user_ids[i];
            
            RAISE NOTICE '🇰🇷 중복 해결: % -> % (ID: %)', 
                         duplicate_record.nickname, new_nickname, duplicate_record.user_ids[i];
        END LOOP;
    END LOOP;
END $$;

-- =============================================================================
-- 5. 안전한 제약조건 설정
-- =============================================================================

-- 기존 제약조건들 정리
DO $$
BEGIN
    -- 각종 제약조건 제거
    IF EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE table_name = 'profiles' AND constraint_name = 'profiles_nickname_unique') THEN
        ALTER TABLE public.profiles DROP CONSTRAINT profiles_nickname_unique;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE table_name = 'profiles' AND constraint_name = 'unique_nickname') THEN
        ALTER TABLE public.profiles DROP CONSTRAINT unique_nickname;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE table_name = 'profiles' AND constraint_name = 'nickname_must_be_unique') THEN
        ALTER TABLE public.profiles DROP CONSTRAINT nickname_must_be_unique;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE table_name = 'profiles' AND constraint_name = 'safe_nickname_unique') THEN
        ALTER TABLE public.profiles DROP CONSTRAINT safe_nickname_unique;
    END IF;
    
    -- 각종 인덱스 제거
    DROP INDEX IF EXISTS idx_profiles_nickname_unique;
    DROP INDEX IF EXISTS nickname_unique_idx;
    DROP INDEX IF EXISTS safe_nickname_idx;
    DROP INDEX IF EXISTS idx_profiles_nickname;
END $$;

-- 새로운 UNIQUE 제약조건
ALTER TABLE public.profiles 
ADD CONSTRAINT korean_nickname_unique UNIQUE (nickname);

-- 성능 인덱스
CREATE UNIQUE INDEX korean_nickname_idx 
ON public.profiles(nickname) 
WHERE nickname IS NOT NULL;

-- =============================================================================
-- 6. 향후 신규 사용자를 위한 한국어 닉네임 트리거
-- =============================================================================

-- 기존 트리거 제거
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- 한국어 닉네임 자동 생성 트리거 함수
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    generated_nickname TEXT;
BEGIN
    -- 🇰🇷 한국어 닉네임 자동 생성
    generated_nickname := generate_korean_nickname(NEW.id);
    
    -- 프로필 생성
    INSERT INTO public.profiles (id, email, full_name, avatar_url, provider, nickname)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', 
                CASE WHEN NEW.email IS NOT NULL THEN split_part(NEW.email, '@', 1) 
                     ELSE '사용자' END),
        COALESCE(NEW.raw_user_meta_data->>'avatar_url', NEW.raw_user_meta_data->>'picture'),
        COALESCE(NEW.raw_app_meta_data->>'provider', 'email'),
        generated_nickname
    );
    
    RAISE NOTICE '🇰🇷 새 사용자 한국어 닉네임: % (닉네임: %)', NEW.email, generated_nickname;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 트리거 생성
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =============================================================================
-- 7. 결과 확인 및 샘플 닉네임 생성
-- =============================================================================

-- 생성 가능한 샘플 닉네임들 보여주기
DO $$
DECLARE
    sample_count INT := 10;
    i INT := 1;
    sample_nickname TEXT;
BEGIN
    RAISE NOTICE '🇰🇷========================================🇰🇷';
    RAISE NOTICE '✅ 한국어 닉네임 생성 시스템 완료!';
    RAISE NOTICE '🎯 생성 가능한 닉네임 예시:';
    
    WHILE i <= sample_count LOOP
        -- 임시로 다른 시드값 사용해서 다양한 닉네임 생성
        SELECT generate_korean_nickname(gen_random_uuid()) INTO sample_nickname;
        RAISE NOTICE '  %: %', i, sample_nickname;
        i := i + 1;
    END LOOP;
    
    RAISE NOTICE '🇰🇷========================================🇰🇷';
END $$;

-- 최종 상태 확인
DO $$
DECLARE
    total_users INT;
    total_profiles INT;
    unique_nicknames INT;
    duplicate_count INT;
BEGIN
    SELECT COUNT(*) INTO total_users FROM auth.users;
    SELECT COUNT(*) INTO total_profiles FROM public.profiles;
    SELECT COUNT(DISTINCT nickname) INTO unique_nicknames FROM public.profiles;
    
    SELECT COUNT(*) INTO duplicate_count 
    FROM (SELECT nickname FROM public.profiles GROUP BY nickname HAVING COUNT(*) > 1) duplicates;
    
    RAISE NOTICE '📊 최종 결과:';
    RAISE NOTICE '  - 인증 사용자: % 명', total_users;
    RAISE NOTICE '  - 프로필 사용자: % 명', total_profiles;
    RAISE NOTICE '  - 고유 닉네임: % 개', unique_nicknames;
    RAISE NOTICE '  - 중복 닉네임: % 개', duplicate_count;
    
    IF total_users = total_profiles AND duplicate_count = 0 THEN
        RAISE NOTICE '🎉 완벽! 모든 사용자가 예쁜 한국어 닉네임을 보유!';
    END IF;
END $$;
