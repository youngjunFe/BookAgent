import 'dart:math';

class NicknameGeneratorService {
  static final NicknameGeneratorService _instance = NicknameGeneratorService._internal();
  factory NicknameGeneratorService() => _instance;
  NicknameGeneratorService._internal();
  
  final Random _random = Random();
  
  // 형용사 리스트 (예쁜 한국어)
  final List<String> _adjectives = [
    '귀여운', '사랑스러운', '멋진', '아름다운', '즐거운', '행복한', '신나는', '밝은',
    '따뜻한', '포근한', '달콤한', '부드러운', '고요한', '평화로운', '활기찬', '생기발랄한',
    '우아한', '고급스러운', '세련된', '독특한', '특별한', '소중한', '빛나는', '반짝이는',
    '신비한', '환상적인', '매력적인', '로맨틱한', '상쾌한', '청순한', '우수한', '완벽한',
    '꿈같은', '행운의', '축복받은', '기쁜', '감사한', '만족한', '든든한', '믿음직한',
    '친근한', '상냥한', '다정한', '순수한', '깨끗한', '맑은', '투명한', '선명한'
  ];
  
  // 동물 리스트
  final List<String> _animals = [
    '고양이', '강아지', '토끼', '곰', '여우', '사자', '호랑이', '판다',
    '코알라', '다람쥐', '햄스터', '고슴도치', '펭귄', '돌고래', '고래', '물개',
    '사슴', '늑대', '독수리', '부엉이', '참새', '비둘기', '백조', '기러기',
    '나비', '벌', '개미', '무당벌레', '잠자리', '거북이', '달팽이', '물고기',
    '상어', '문어', '새우', '게', '해파리', '불가사리', '말', '양', '염소', '소',
    '돼지', '닭', '오리', '거위', '칠면조', '원숭이', '코끼리', '기린'
  ];
  
  // 사물/개념 리스트
  final List<String> _objects = [
    '별', '달', '태양', '구름', '바다', '산', '강', '꽃', '나무', '잎',
    '책', '연필', '붓', '음표', '멜로디', '하트', '다이아', '크리스탈', '보석', '진주',
    '캔디', '초콜릿', '케이크', '쿠키', '아이스크림', '라떼', '차', '꿀', '설탕', '바닐라',
    '무지개', '눈', '비', '바람', '햇살', '향기', '미소', '웃음', '꿈', '희망',
    '마법', '기적', '천사', '요정', '공주', '왕자', '여왕', '왕', '기사', '마녀',
    '성', '궁전', '정원', '숲', '섬', '동굴', '다리', '탑', '집', '방'
  ];
  
  // 색깔 리스트
  final List<String> _colors = [
    '빨간', '주황', '노란', '초록', '파란', '보라', '분홍', '흰',
    '검은', '회색', '갈색', '금색', '은색', '청록', '라임', '민트',
    '복숭아', '연두', '하늘', '바다', '라벤더', '로즈', '체리', '딸기',
    '레몬', '오렌지', '바나나', '포도', '블루베리', '자두', '수박', '키위'
  ];
  
  // 감정/상태 리스트
  final List<String> _emotions = [
    '꿈꾸는', '춤추는', '노래하는', '웃는', '잠자는', '뛰어다니는', '날아다니는', '헤엄치는',
    '생각하는', '공부하는', '읽는', '그리는', '만드는', '요리하는', '여행하는', '모험하는',
    '탐험하는', '발견하는', '찾아가는', '기다리는', '바라는', '소망하는', '응원하는', '격려하는',
    '도와주는', '나누는', '선물하는', '축하하는', '감사하는', '사랑하는', '아껴주는', '보살피는'
  ];
  
  /// 랜덤 닉네임 생성 (여러 패턴)
  String generateRandomNickname() {
    final patterns = [
      () => '${_adjectives[_random.nextInt(_adjectives.length)]}${_animals[_random.nextInt(_animals.length)]}',
      () => '${_colors[_random.nextInt(_colors.length)]}${_objects[_random.nextInt(_objects.length)]}',
      () => '${_emotions[_random.nextInt(_emotions.length)]}${_animals[_random.nextInt(_animals.length)]}',
      () => '${_adjectives[_random.nextInt(_adjectives.length)]}${_objects[_random.nextInt(_objects.length)]}',
      () => '${_colors[_random.nextInt(_colors.length)]}${_animals[_random.nextInt(_animals.length)]}',
    ];
    
    final selectedPattern = patterns[_random.nextInt(patterns.length)];
    return selectedPattern();
  }
  
  /// 여러 개의 닉네임 후보 생성
  List<String> generateNicknameOptions({int count = 5}) {
    final Set<String> nicknames = {};
    
    while (nicknames.length < count) {
      final nickname = generateRandomNickname();
      nicknames.add(nickname);
    }
    
    return nicknames.toList();
  }
  
  /// 닉네임 중복 체크와 함께 유니크한 닉네임 생성
  Future<String> generateUniqueNickname({
    required Future<bool> Function(String nickname) checkDuplicate,
    int maxAttempts = 10,
  }) async {
    for (int i = 0; i < maxAttempts; i++) {
      String nickname = generateRandomNickname();
      
      // 중복 체크
      bool isDuplicate = await checkDuplicate(nickname);
      
      if (!isDuplicate) {
        return nickname;
      }
      
      // 중복이면 숫자 추가
      if (i >= maxAttempts ~/ 2) {
        int number = _random.nextInt(9999) + 1;
        nickname = '$nickname$number';
        
        isDuplicate = await checkDuplicate(nickname);
        if (!isDuplicate) {
          return nickname;
        }
      }
    }
    
    // 최후의 수단: 타임스탬프 추가
    final timestamp = DateTime.now().millisecondsSinceEpoch % 10000;
    return '${generateRandomNickname()}$timestamp';
  }
  
  /// 특정 키워드 기반 닉네임 생성
  String generateNicknameWithKeyword(String keyword) {
    final patterns = [
      () => '${_adjectives[_random.nextInt(_adjectives.length)]}$keyword',
      () => '$keyword${_animals[_random.nextInt(_animals.length)]}',
      () => '${_colors[_random.nextInt(_colors.length)]}$keyword',
      () => '$keyword${_objects[_random.nextInt(_objects.length)]}',
    ];
    
    final selectedPattern = patterns[_random.nextInt(patterns.length)];
    return selectedPattern();
  }
  
  /// 닉네임 유효성 검사
  bool isValidNickname(String nickname) {
    // 2-20자 길이
    if (nickname.length < 2 || nickname.length > 20) {
      return false;
    }
    
    // 특수문자 제한 (한글, 영문, 숫자만 허용)
    final validPattern = RegExp(r'^[가-힣a-zA-Z0-9]+$');
    if (!validPattern.hasMatch(nickname)) {
      return false;
    }
    
    return true;
  }
  
  /// 부적절한 단어 필터링
  bool containsInappropriateContent(String nickname) {
    final inappropriateWords = [
      '바보', '멍청', '병신', '개새', '시발', '좆', '년', '놈',
      // 더 많은 필터링 단어들을 추가할 수 있음
    ];
    
    final lowerNickname = nickname.toLowerCase();
    
    return inappropriateWords.any((word) => 
        lowerNickname.contains(word.toLowerCase())
    );
  }
  
  /// 안전한 닉네임 생성 (유효성 검사 + 필터링 포함)
  String generateSafeNickname() {
    String nickname;
    int attempts = 0;
    const maxAttempts = 50;
    
    do {
      nickname = generateRandomNickname();
      attempts++;
      
      if (attempts > maxAttempts) {
        // 최후의 수단
        nickname = '독자${_random.nextInt(9999) + 1}';
        break;
      }
    } while (!isValidNickname(nickname) || containsInappropriateContent(nickname));
    
    return nickname;
  }
}
