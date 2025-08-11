import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_client_provider.dart';
import '../models/review.dart';

abstract class ReviewApi {
  Future<List<Review>> list({String? status});
  Future<Review> create(Review review);
  Future<Review> update(Review review);
  Future<void> delete(String id);
  Future<Map<ReviewStatus, int>> fetchCountsByStatus();
}

class SupabaseReviewApi implements ReviewApi {
  SupabaseClient get _client => SupabaseClientProvider.client;
  final String _table = 'reviews';

  @override
  Future<List<Review>> list({String? status}) async {
    final rows = await _client.from(_table).select().order('created_at', ascending: false);
    final all = (rows as List).map((e) => _fromRow(e as Map<String, dynamic>)).toList();
    if (status == null) return all;
    return all.where((r) => r.status.name == status).toList();
  }

  @override
  Future<Review> create(Review review) async {
    final inserted = await _client.from(_table).insert(_toInsertRow(review)).select().single();
    return _fromRow(inserted as Map<String, dynamic>);
  }

  @override
  Future<Review> update(Review review) async {
    final updated = await _client
        .from(_table)
        .update(_toRow(review))
        .eq('id', review.id)
        .select()
        .single();
    return _fromRow(updated as Map<String, dynamic>);
  }

  @override
  Future<void> delete(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }

  @override
  Future<Map<ReviewStatus, int>> fetchCountsByStatus() async {
    final listAll = await list();
    return {
      for (final s in ReviewStatus.values)
        s: listAll.where((r) => r.status == s).length,
    };
  }

  Map<String, dynamic> _toRow(Review r) {
    return {
      'id': r.id,
      'title': r.title,
      'content': r.content,
      'book_title': r.bookTitle,
      'book_author': r.bookAuthor,
      'book_cover': r.bookCover,
      'status': r.status.name,
      'created_at': r.createdAt.toIso8601String(),
      'updated_at': r.updatedAt.toIso8601String(),
      'background_image': r.backgroundImage,
      'tags': r.tags,
      'mood': r.mood,
      'quotes': r.quotes,
      'chat_history': r.chatHistory,
    };
  }

  Map<String, dynamic> _toInsertRow(Review r) {
    // 웹/로컬에서 생성한 임시 id(타임스탬프 등)는 무시하고 DB에서 uuid 생성
    final row = _toRow(r);
    row.remove('id');
    return row;
  }

  Review _fromRow(Map<String, dynamic> row) {
    return Review(
      id: row['id'] as String,
      title: row['title'] as String,
      content: row['content'] as String,
      bookTitle: row['book_title'] as String,
      bookAuthor: row['book_author'] as String?,
      bookCover: row['book_cover'] as String?,
      status: ReviewStatus.values.firstWhere(
        (e) => e.name == (row['status'] as String),
        orElse: () => ReviewStatus.draft,
      ),
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
      backgroundImage: row['background_image'] as String?,
      tags: (row['tags'] as List?)?.map<String>((e) => e.toString()).toList() ?? const [],
      mood: row['mood'] as String?,
      quotes: (row['quotes'] as List?)?.map<String>((e) => e.toString()).toList() ?? const [],
      chatHistory: row['chat_history'] as String?,
    );
  }
}


