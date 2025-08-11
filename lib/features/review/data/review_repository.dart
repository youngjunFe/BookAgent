import '../../../core/supabase/supabase_client_provider.dart';
import '../models/review.dart';
import 'review_api.dart';

class ReviewRepository {
  ReviewRepository({ReviewApi? api}) : _api = api ?? SupabaseReviewApi();
  final ReviewApi _api;

  Future<List<Review>> list({ReviewStatus? status}) {
    if (!SupabaseClientProvider.isReady) return Future.value([]);
    return _api.list(status: status?.name);
  }

  Future<Map<ReviewStatus, int>> counts() {
    if (!SupabaseClientProvider.isReady) {
      return Future.value({
        ReviewStatus.draft: 0,
        ReviewStatus.completed: 0,
        ReviewStatus.published: 0,
      });
    }
    return _api.fetchCountsByStatus();
  }

  Future<Review> create(Review r) {
    if (!SupabaseClientProvider.isReady) return Future.value(r);
    return _api.create(r);
  }

  Future<Review> update(Review r) {
    if (!SupabaseClientProvider.isReady) return Future.value(r);
    return _api.update(r);
  }

  Future<void> delete(String id) {
    if (!SupabaseClientProvider.isReady) return Future.value();
    return _api.delete(id);
  }
}



