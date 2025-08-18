import '../models/ebook.dart';
import 'ebook_api.dart';

class EBookRepository {
  EBookRepository({EBookApi? api}) : _api = api ?? SupabaseEBookApi();
  final EBookApi _api;

  Future<List<EBook>> list() {
    return _api.list();
  }

  Future<EBook> create(EBook ebook) {
    return _api.create(ebook);
  }

  Future<EBook> update(EBook ebook) {
    return _api.update(ebook);
  }

  Future<void> delete(String id) {
    return _api.delete(id);
  }

  Future<void> updateProgress({
    required String id,
    required int currentPage,
    required double progress,
    required DateTime lastReadAt,
  }) async {
    try {
      await _api.updateProgress(
        id: id,
        currentPage: currentPage,
        progress: progress,
        lastReadAt: lastReadAt,
      );
    } catch (e) {
      print('❌ Repository updateProgress 에러: $e');
      // 에러 발생해도 조용히 넘어감
    }
  }

  Future<EBook> markAsCompleted(String id) {
    return _api.markAsCompleted(id);
  }
}