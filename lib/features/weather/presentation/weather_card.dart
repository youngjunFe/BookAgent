import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/weather_data.dart';
import '../services/weather_message_service.dart';

class WeatherCard extends StatefulWidget {
  const WeatherCard({super.key});

  @override
  State<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<WeatherCard> {
  WeatherData? _weatherData;
  BookCareMessage? _currentMessage;
  int _messageIndex = 0;
  
  @override
  void initState() {
    super.initState();
    _loadWeatherData();
  }

  void _loadWeatherData() {
    // 현재는 더미 데이터 사용 (향후 실제 API 연동)
    _weatherData = WeatherData.dummy();
    _updateMessage();
  }

  void _updateMessage() {
    if (_weatherData == null) return;
    
    final messages = [
      WeatherMessageService.generateMessage(_weatherData!),
      WeatherMessageService.getSeasonalMessage(),
      WeatherMessageService.getTimeBasedMessage(),
    ];
    
    setState(() {
      _currentMessage = messages[_messageIndex % messages.length];
    });
  }

  void _nextMessage() {
    _messageIndex = (_messageIndex + 1) % 3;
    _updateMessage();
  }

  Color _getMessageColor(MessageType type) {
    switch (type) {
      case MessageType.warning:
        return Colors.orange;
      case MessageType.alert:
        return Colors.red;
      case MessageType.tip:
        return AppColors.primary;
      case MessageType.info:
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_weatherData == null || _currentMessage == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: _getMessageColor(_currentMessage!.type).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getMessageColor(_currentMessage!.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _currentMessage!.icon,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentMessage!.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.thermostat,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        Text(
                          ' ${_weatherData!.temperature.toStringAsFixed(1)}°C',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.water_drop,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        Text(
                          ' ${_weatherData!.humidity.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // 메시지 변경 버튼
              GestureDetector(
                onTap: _nextMessage,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.refresh,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // 메시지 내용
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getMessageColor(_currentMessage!.type).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _currentMessage!.message,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // 업데이트 시간
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 12,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_weatherData!.timestamp.hour.toString().padLeft(2, '0')}:${_weatherData!.timestamp.minute.toString().padLeft(2, '0')} 업데이트',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getMessageColor(_currentMessage!.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getMessageTypeText(_currentMessage!.type),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: _getMessageColor(_currentMessage!.type),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getMessageTypeText(MessageType type) {
    switch (type) {
      case MessageType.warning:
        return '주의';
      case MessageType.alert:
        return '경고';
      case MessageType.tip:
        return '팁';
      case MessageType.info:
      default:
        return '정보';
    }
  }
}







