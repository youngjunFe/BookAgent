import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/reading_goal.dart';

class GoalCreationPage extends StatefulWidget {
  const GoalCreationPage({super.key});

  @override
  State<GoalCreationPage> createState() => _GoalCreationPageState();
}

class _GoalCreationPageState extends State<GoalCreationPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _targetController = TextEditingController();

  GoalType _selectedType = GoalType.monthly;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  void _updateDateRange() {
    final now = DateTime.now();
    switch (_selectedType) {
      case GoalType.daily:
        _startDate = now;
        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case GoalType.weekly:
        _startDate = now;
        _endDate = now.add(const Duration(days: 7));
        break;
      case GoalType.monthly:
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(now.year, now.month + 1, 0);
        break;
      case GoalType.yearly:
        _startDate = DateTime(now.year, 1, 1);
        _endDate = DateTime(now.year, 12, 31);
        break;
      case GoalType.streak:
      case GoalType.pages:
      case GoalType.time:
        _startDate = now;
        _endDate = now.add(const Duration(days: 30));
        break;
    }
  }

  String _getDefaultTitle(GoalType type) {
    switch (type) {
      case GoalType.daily:
        return '오늘 책 읽기';
      case GoalType.weekly:
        return '이번 주 독서 목표';
      case GoalType.monthly:
        return '이번 달 독서 목표';
      case GoalType.yearly:
        return '올해 독서 목표';
      case GoalType.streak:
        return '연속 독서 챌린지';
      case GoalType.pages:
        return '페이지 독서 목표';
      case GoalType.time:
        return '시간 독서 목표';
    }
  }

  int _getDefaultTarget(GoalType type) {
    switch (type) {
      case GoalType.daily:
        return 1;
      case GoalType.weekly:
        return 2;
      case GoalType.monthly:
        return 3;
      case GoalType.yearly:
        return 24;
      case GoalType.streak:
        return 7;
      case GoalType.pages:
        return 500;
      case GoalType.time:
        return 300;
    }
  }

  void _createGoal() {
    if (_formKey.currentState!.validate()) {
      final goal = ReadingGoal(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        type: _selectedType,
        targetValue: int.parse(_targetController.text),
        currentValue: 0,
        startDate: _startDate,
        endDate: _endDate,
        isCompleted: false,
        createdAt: DateTime.now(),
      );

      Navigator.of(context).pop(goal);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('새 목표 추가'),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _createGoal,
            child: const Text('저장'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 목표 유형 선택
              Text(
                '목표 유형',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _buildTypeSelector(),

              const SizedBox(height: 24),

              // 목표 제목
              Text(
                '목표 제목',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: _getDefaultTitle(_selectedType),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '목표 제목을 입력해주세요';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // 목표 값
              Text(
                '목표 값',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _targetController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: _getDefaultTarget(_selectedType).toString(),
                  suffixText: _selectedType.unit,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '목표 값을 입력해주세요';
                  }
                  final intValue = int.tryParse(value);
                  if (intValue == null || intValue <= 0) {
                    return '올바른 숫자를 입력해주세요';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // 기간 설정
              Text(
                '목표 기간',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.dividerColor),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '시작일',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          '${_startDate.year}.${_startDate.month.toString().padLeft(2, '0')}.${_startDate.day.toString().padLeft(2, '0')}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '종료일',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          '${_endDate.year}.${_endDate.month.toString().padLeft(2, '0')}.${_endDate.day.toString().padLeft(2, '0')}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 설명
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _getGoalDescription(_selectedType),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // 생성 버튼
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _createGoal,
                  child: const Text('목표 생성'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: GoalType.values.map((type) {
        final isSelected = _selectedType == type;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedType = type;
              _titleController.text = _getDefaultTitle(type);
              _targetController.text = _getDefaultTarget(type).toString();
              _updateDateRange();
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.dividerColor,
                width: 1.5,
              ),
            ),
            child: Text(
              type.displayName,
              style: TextStyle(
                color: isSelected ? AppColors.onPrimary : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getGoalDescription(GoalType type) {
    switch (type) {
      case GoalType.daily:
        return '매일 달성해야 하는 짧은 목표입니다. 꾸준한 독서 습관을 만들어보세요.';
      case GoalType.weekly:
        return '일주일 동안 달성할 목표입니다. 단기간에 집중적으로 독서해보세요.';
      case GoalType.monthly:
        return '한 달 동안 달성할 목표입니다. 가장 인기 있는 목표 유형입니다.';
      case GoalType.yearly:
        return '일 년 동안 달성할 장기 목표입니다. 꾸준한 계획이 필요합니다.';
      case GoalType.streak:
        return '연속으로 독서한 날짜를 기록합니다. 독서 습관 형성에 도움이 됩니다.';
      case GoalType.pages:
        return '읽을 페이지 수를 목표로 합니다. 책의 분량을 기준으로 설정하세요.';
      case GoalType.time:
        return '독서 시간을 목표로 합니다. 바쁜 일상에서 독서 시간 확보에 도움이 됩니다.';
    }
  }
}




