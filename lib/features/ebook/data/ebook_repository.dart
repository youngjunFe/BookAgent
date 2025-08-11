import '../models/ebook.dart';
import 'ebook_api.dart';
import '../../../core/supabase/supabase_client_provider.dart';

class EbookRepository {
  EbookRepository({EbookApi? api}) : _api = api ?? SupabaseEbookApi();
  final EbookApi _api;

  Future<List<EBook>> fetchEbooks() {
    if (!SupabaseClientProvider.isReady) {
      return Future.value(EBook.sampleBooks);
    }
    return _api.list();
  }

  Future<EBook> addEbook(EBook ebook) {
    if (!SupabaseClientProvider.isReady) {
      return Future.value(ebook);
    }
    return _api.create(ebook);
  }

  Future<EBook> getEbook(String id) {
    if (!SupabaseClientProvider.isReady) {
      return Future.error(StateError('Supabase is not initialized'));
    }
    return _api.getById(id);
  }

  Future<EBook> updateEbook(EBook ebook) {
    if (!SupabaseClientProvider.isReady) {
      return Future.value(ebook);
    }
    return _api.update(ebook.id, ebook);
  }

  Future<void> deleteEbook(String id) {
    if (!SupabaseClientProvider.isReady) {
      return Future.value();
    }
    return _api.delete(id);
  }
}


