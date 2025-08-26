import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../models/ebook.dart';
import '../data/ebook_repository.dart';

class AddBookPage extends StatefulWidget {
  const AddBookPage({super.key});

  @override
  State<AddBookPage> createState() => _AddBookPageState();
}

class _AddBookPageState extends State<AddBookPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _contentController = TextEditingController();
  final _chaptersController = TextEditingController();
  
  bool _isLoading = false;
  String? _coverUrl;
  final _repo = EBookRepository();

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _contentController.dispose();
    _chaptersController.dispose();
    super.dispose();
  }

  Future<void> _saveBook() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 챕터 파싱
      final chapters = _chaptersController.text
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();

      // 페이지 수 계산 (간단한 방식: 단어 수 기준)
      final words = _contentController.text.split(' ');
      final totalPages = (words.length / 300).ceil(); // 한 페이지당 약 300단어

      final newBook = EBook(
        id: const Uuid().v4(),
        userId: '', // API에서 자동으로 현재 사용자 ID로 설정됨
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        content: _contentController.text.trim(),
        coverImageUrl: _coverUrl,
        addedAt: DateTime.now(),
        totalPages: totalPages,
        currentPage: 0,
        progress: 0.0,
        chapters: chapters,
      );

      // Supabase 저장
      await _repo.create(newBook);

      if (mounted) {
        Navigator.of(context).pop(newBook);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('책이 성공적으로 추가되었습니다!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('책 추가 중 오류가 발생했습니다: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('새 책 추가'),
        backgroundColor: AppColors.background,
        elevation: 1,
        shadowColor: AppColors.dividerColor,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveBook,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    '저장',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 안내 문구
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.info.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.info,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '책 추가 안내',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.info,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '텍스트 파일이나 직접 입력으로 책을 추가할 수 있습니다.\n모든 필드를 정확히 입력해주세요.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.info,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 책 제목
              _buildSection(
                title: '책 제목',
                icon: Icons.title,
                child: TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    hintText: '책의 제목을 입력하세요',
                    border: InputBorder.none,
                  ),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '책 제목을 입력해주세요';
                    }
                    return null;
                  },
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 저자
              _buildSection(
                title: '저자',
                icon: Icons.person,
                child: TextFormField(
                  controller: _authorController,
                  decoration: const InputDecoration(
                    hintText: '저자명을 입력하세요',
                    border: InputBorder.none,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '저자명을 입력해주세요';
                    }
                    return null;
                  },
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 챕터 (선택사항)
              _buildSection(
                title: '목차 (선택사항)',
                icon: Icons.list,
                child: TextFormField(
                  controller: _chaptersController,
                  decoration: const InputDecoration(
                    hintText: '각 장을 줄바꿈으로 구분하여 입력하세요\n예:\n1장: 시작\n2장: 중간\n3장: 끝',
                    border: InputBorder.none,
                  ),
                  maxLines: 5,
                  minLines: 3,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 책 내용
              _buildSection(
                title: '책 내용',
                icon: Icons.article,
                child: TextFormField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    hintText: '책의 전체 내용을 입력하세요...\n\n긴 텍스트를 복사해서 붙여넣기 할 수 있습니다.',
                    border: InputBorder.none,
                  ),
                  maxLines: null,
                  minLines: 10,
                  keyboardType: TextInputType.multiline,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '책 내용을 입력해주세요';
                    }
                    if (value.trim().length < 100) {
                      return '책 내용이 너무 짧습니다 (최소 100자)';
                    }
                    return null;
                  },
                ),
              ),
              
              const SizedBox(height: 32),
              
              // 저장 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveBook,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.onPrimary),
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isLoading ? '저장 중...' : '책 추가'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 파일 업로드 버튼 (추후 구현)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _pickAndUploadCover,
                  icon: const Icon(Icons.image_outlined),
                  label: Text(_coverUrl == null ? '표지 이미지 업로드' : '표지 변경하기'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadCover() async {
    try {
      final res = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
      if (res == null || res.files.isEmpty) return;
      final file = res.files.first;
      final bytes = file.bytes;
      if (bytes == null) return;

      setState(() => _isLoading = true);

      // 안전한 파일명 생성 (한글, 특수문자 제거)
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = file.extension?.toLowerCase() ?? 'png';
      final filename = 'cover_${timestamp}.${extension}';
      final storage = Supabase.instance.client.storage.from('book-covers');
      final contentType = file.extension != null && file.extension!.isNotEmpty
          ? 'image/${file.extension!.toLowerCase()}'
          : 'image/png';
      await storage.uploadBinary(
        filename,
        bytes,
        fileOptions: FileOptions(
          contentType: contentType, 
          upsert: true,
          cacheControl: '3600'
        ),
      );
      final publicUrl = storage.getPublicUrl(filename);

      setState(() {
        _coverUrl = publicUrl;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('표지 이미지가 업로드되었습니다.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('업로드 실패: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.dividerColor,
              width: 1,
            ),
          ),
          child: child,
        ),
      ],
    );
  }
}

