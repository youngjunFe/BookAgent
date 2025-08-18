import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../models/ebook.dart';
import '../data/ebook_repository.dart';

class EditBookPage extends StatefulWidget {
  final EBook book;

  const EditBookPage({
    super.key,
    required this.book,
  });

  @override
  State<EditBookPage> createState() => _EditBookPageState();
}

class _EditBookPageState extends State<EditBookPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _contentController = TextEditingController();
  final _repo = EBookRepository();
  
  bool _isLoading = false;
  String? _coverImageUrl;
  bool _isUploadingCover = false;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.book.title;
    _authorController.text = widget.book.author;
    _contentController.text = widget.book.content;
    _coverImageUrl = widget.book.coverImageUrl;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadCover() async {
    setState(() {
      _isUploadingCover = true;
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null) {
        final file = result.files.first;
        final bytes = file.bytes;
        
        if (bytes == null) {
          throw Exception('파일을 읽을 수 없습니다.');
        }

        // 안전한 파일명 생성 (한글 및 특수문자 제거)
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final extension = file.extension?.toLowerCase() ?? 'png';
        final filename = 'cover_${timestamp}.${extension}';

        final storage = Supabase.instance.client.storage.from('book-covers');

        // 파일 업로드
        await storage.uploadBinary(
          filename,
          bytes,
          fileOptions: FileOptions(
            contentType: _getContentType(extension),
            upsert: true,
            cacheControl: '3600',
          ),
        );

        // 공개 URL 가져오기
        final publicUrl = storage.getPublicUrl(filename);
        
        setState(() {
          _coverImageUrl = publicUrl;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('표지 이미지가 업로드되었습니다.'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('이미지 업로드 실패: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isUploadingCover = false;
      });
    }
  }

  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/png';
    }
  }

  Future<void> _updateBook() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedBook = widget.book.copyWith(
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        content: _contentController.text.trim(),
        coverImageUrl: _coverImageUrl,
      );

      await _repo.update(updatedBook);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('책 정보가 수정되었습니다.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(updatedBook); // 수정된 책 정보 반환
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('수정 실패: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('책 편집'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.onPrimary),
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _updateBook,
              child: const Text(
                '저장',
                style: TextStyle(
                  color: AppColors.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 표지 이미지 섹션
              const Text(
                '표지 이미지',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.dividerColor),
                ),
                child: _buildCoverPreview(),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isUploadingCover ? null : _pickAndUploadCover,
                  icon: _isUploadingCover
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.image),
                  label: Text(_isUploadingCover ? '업로드 중...' : '표지 변경'),
                ),
              ),
              
              const SizedBox(height: 24),

              // 책 제목
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '책 제목',
                  hintText: '책 제목을 입력하세요',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '책 제목을 입력해주세요';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // 저자
              TextFormField(
                controller: _authorController,
                decoration: const InputDecoration(
                  labelText: '저자',
                  hintText: '저자명을 입력하세요',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '저자명을 입력해주세요';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // 내용
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: '내용',
                  hintText: '책의 내용을 입력하세요',
                  border: OutlineInputBorder(),
                ),
                maxLines: 10,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '책의 내용을 입력해주세요';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // 저장 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateBook,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.onPrimary),
                          ),
                        )
                      : const Text(
                          '수정 완료',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverPreview() {
    if (_coverImageUrl != null && _coverImageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          _coverImageUrl!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultCover();
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        ),
      );
    }
    return _buildDefaultCover();
  }

  Widget _buildDefaultCover() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: 48,
            color: Colors.grey,
          ),
          SizedBox(height: 8),
          Text(
            '표지 이미지를 선택하세요',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

