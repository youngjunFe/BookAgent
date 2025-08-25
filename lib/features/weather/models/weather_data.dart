class WeatherData {
  final double temperature;
  final double humidity;
  final String condition; // sunny, cloudy, rainy, etc.
  final String description;
  final DateTime timestamp;

  const WeatherData({
    required this.temperature,
    required this.humidity,
    required this.condition,
    required this.description,
    required this.timestamp,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      temperature: (json['main']['temp'] as num).toDouble(),
      humidity: (json['main']['humidity'] as num).toDouble(),
      condition: json['weather'][0]['main'].toString().toLowerCase(),
      description: json['weather'][0]['description'].toString(),
      timestamp: DateTime.now(),
    );
  }

  // 임시 더미 데이터 (실제 API 연동 전까지)
  factory WeatherData.dummy() {
    return WeatherData(
      temperature: 22.5,
      humidity: 75.0,
      condition: 'clouds',
      description: '흐림',
      timestamp: DateTime.now(),
    );
  }
}

class BookCareMessage {
  final String title;
  final String message;
  final String icon;
  final MessageType type;

  const BookCareMessage({
    required this.title,
    required this.message,
    required this.icon,
    required this.type,
  });
}

enum MessageType {
  warning,
  info,
  tip,
  alert,
}






