import 'package:flutter/material.dart';
import '../../../core/services/nickname_generator_service.dart';
import '../../../core/constants/app_colors.dart';

// 닉네임 API 테스트 페이지 (임시)
class NicknameTestPage extends StatefulWidget {
  const NicknameTestPage({super.key});

  @override
  State<NicknameTestPage> createState() => _NicknameTestPageState();
}

class _NicknameTestPageState extends State<NicknameTestPage> {
  String? _apiNickname;
  String? _localNickname;
  bool _isLoadingAPI = false;
  bool _isLoadingLocal = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('닉네임 생성 테스트'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // API 테스트 섹션
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.cloud, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        '외부 API 테스트',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'URL: https://www.rivestsoft.com/nickname/getRandomNickname.ajax',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[600],
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoadingAPI ? null : _testAPICall,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoadingAPI
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('API 닉네임 생성 테스트'),
                    ),
                  ),
                  if (_apiNickname != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green[700], size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'API 결과: $_apiNickname',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.green[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // 로컬 테스트 섹션
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.phone_android, color: Colors.orange[700]),
                      const SizedBox(width: 8),
                      Text(
                        '로컬 생성 테스트',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '백업용 한국어 조합',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoadingLocal ? null : _testLocalGeneration,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[700],
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoadingLocal
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('로컬 닉네임 생성 테스트'),
                    ),
                  ),
                  if (_localNickname != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green[700], size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '로컬 결과: $_localNickname',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.green[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // 에러 표시
            if (_error != null) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.error, color: Colors.red[700], size: 16),
                        const SizedBox(width: 8),
                        Text(
                          '에러 발생',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red[600],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const Spacer(),
            
            // 뒤로가기 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('뒤로가기'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testAPICall() async {
    setState(() {
      _isLoadingAPI = true;
      _error = null;
      _apiNickname = null;
    });

    try {
      final nicknameService = NicknameGeneratorService();
      final result = await nicknameService.generateNicknameFromAPI();
      
      setState(() {
        _apiNickname = result;
        if (result == null) {
          _error = 'API가 null을 반환했습니다';
        }
      });
    } catch (e) {
      setState(() {
        _error = 'API 테스트 실패: $e';
      });
    } finally {
      setState(() {
        _isLoadingAPI = false;
      });
    }
  }

  Future<void> _testLocalGeneration() async {
    setState(() {
      _isLoadingLocal = true;
      _localNickname = null;
    });

    try {
      final nicknameService = NicknameGeneratorService();
      final result = nicknameService.generateRandomNickname();
      
      setState(() {
        _localNickname = result;
      });
    } catch (e) {
      setState(() {
        _error = '로컬 생성 실패: $e';
      });
    } finally {
      setState(() {
        _isLoadingLocal = false;
      });
    }
  }
}
