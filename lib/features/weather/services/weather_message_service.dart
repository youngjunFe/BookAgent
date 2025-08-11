import '../models/weather_data.dart';

class WeatherMessageService {
  static BookCareMessage generateMessage(WeatherData weather) {
    // 습도 기반 메시지
    if (weather.humidity >= 80) {
      return const BookCareMessage(
        title: '높은 습도 주의!',
        message: '오늘 습도가 80%예요.\n책이 울 수 있어요. 책장을 점검해 주세요!',
        icon: '💧',
        type: MessageType.warning,
      );
    }
    
    if (weather.humidity >= 70) {
      return const BookCareMessage(
        title: '습도가 높아요',
        message: '습도가 높은 날이에요.\n책장에 제습제를 두는 건 어떨까요?',
        icon: '🌫️',
        type: MessageType.tip,
      );
    }
    
    if (weather.humidity <= 30) {
      return const BookCareMessage(
        title: '건조한 날씨',
        message: '공기가 매우 건조해요.\n책 페이지가 바스락거릴 수 있어요!',
        icon: '🏜️',
        type: MessageType.info,
      );
    }
    
    // 온도 기반 메시지
    if (weather.temperature >= 30) {
      return const BookCareMessage(
        title: '더운 날씨',
        message: '오늘은 더워요!\n시원한 곳에서 독서하는 건 어떨까요?',
        icon: '☀️',
        type: MessageType.tip,
      );
    }
    
    if (weather.temperature <= 5) {
      return const BookCareMessage(
        title: '추운 날씨',
        message: '날씨가 추워요.\n따뜻한 차 한 잔과 함께 독서 어떠세요?',
        icon: '❄️',
        type: MessageType.tip,
      );
    }
    
    // 날씨 조건 기반 메시지
    switch (weather.condition) {
      case 'rain':
        return const BookCareMessage(
          title: '비오는 날',
          message: '비소리와 함께하는 독서,\n완벽한 분위기네요!',
          icon: '🌧️',
          type: MessageType.info,
        );
      
      case 'snow':
        return const BookCareMessage(
          title: '눈오는 날',
          message: '눈 내리는 창가에서\n책 읽기 딱 좋은 날이에요!',
          icon: '❄️',
          type: MessageType.info,
        );
      
      case 'clear':
        return const BookCareMessage(
          title: '맑은 날씨',
          message: '햇살 좋은 날이에요.\n야외에서 독서는 어떨까요?',
          icon: '☀️',
          type: MessageType.tip,
        );
      
      case 'clouds':
        return const BookCareMessage(
          title: '구름 낀 날',
          message: '차분한 날씨네요.\n집중력이 높아지는 독서 시간!',
          icon: '☁️',
          type: MessageType.info,
        );
      
      default:
        return const BookCareMessage(
          title: '독서하기 좋은 날',
          message: '오늘도 좋은 책과 함께\n멋진 하루 보내세요!',
          icon: '📚',
          type: MessageType.info,
        );
    }
  }
  
  // 계절별 추가 메시지
  static BookCareMessage getSeasonalMessage() {
    final month = DateTime.now().month;
    
    if (month >= 6 && month <= 8) {
      // 여름
      return const BookCareMessage(
        title: '여름 독서 팁',
        message: '장마철엔 책이 눅눅해질 수 있어요.\n통풍이 잘 되는 곳에 보관하세요!',
        icon: '🌞',
        type: MessageType.tip,
      );
    } else if (month >= 9 && month <= 11) {
      // 가을
      return const BookCareMessage(
        title: '독서의 계절',
        message: '선선한 가을, 독서하기 최고의 계절이에요!\n새로운 책과 만나보세요.',
        icon: '🍂',
        type: MessageType.info,
      );
    } else if (month >= 12 || month <= 2) {
      // 겨울
      return const BookCareMessage(
        title: '겨울 독서',
        message: '추운 겨울, 따뜻한 실내에서\n마음을 따뜻하게 해줄 책은 어떠세요?',
        icon: '❄️',
        type: MessageType.tip,
      );
    } else {
      // 봄
      return const BookCareMessage(
        title: '봄맞이 독서',
        message: '새로운 시작의 계절!\n새로운 장르에 도전해보세요.',
        icon: '🌸',
        type: MessageType.info,
      );
    }
  }
  
  // 시간대별 메시지
  static BookCareMessage getTimeBasedMessage() {
    final hour = DateTime.now().hour;
    
    if (hour >= 6 && hour < 12) {
      return const BookCareMessage(
        title: '좋은 아침!',
        message: '상쾌한 아침 공기와 함께\n새로운 지식을 흡수해보세요!',
        icon: '🌅',
        type: MessageType.info,
      );
    } else if (hour >= 12 && hour < 18) {
      return const BookCareMessage(
        title: '오후 독서',
        message: '점심 후 잠깐의 독서 시간,\n머리를 맑게 해줄 거예요!',
        icon: '☀️',
        type: MessageType.tip,
      );
    } else if (hour >= 18 && hour < 22) {
      return const BookCareMessage(
        title: '저녁 독서',
        message: '하루를 마무리하는 독서,\n마음의 평화를 찾아보세요.',
        icon: '🌆',
        type: MessageType.info,
      );
    } else {
      return const BookCareMessage(
        title: '밤늦은 독서',
        message: '조용한 밤, 깊이 있는 사색과 함께\n특별한 독서 시간을 가져보세요.',
        icon: '🌙',
        type: MessageType.info,
      );
    }
  }
}


