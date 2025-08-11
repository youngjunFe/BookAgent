import 'package:supabase_flutter/supabase_flutter.dart';
import '../../ebook/models/ebook.dart';
import '../../../core/supabase/supabase_client_provider.dart';

abstract class EbookApi {
  Future<List<EBook>> list();
  Future<EBook> create(EBook data);
  Future<EBook> getById(String id);
  Future<EBook> update(String id, EBook data);
  Future<void> delete(String id);
}

class SupabaseEbookApi implements EbookApi {
  SupabaseClient get _client => SupabaseClientProvider.client;
  final String _table = 'ebooks';

  @override
  Future<List<EBook>> list() async {
    final response = await _client.from(_table).select().order('added_at', ascending: false);
    return (response as List<dynamic>).map((e) => _fromRow(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<EBook> create(EBook data) async {
    final inserted = await _client.from(_table).insert(_toRow(data)).select().single();
    return _fromRow(inserted as Map<String, dynamic>);
  }

  @override
  Future<EBook> getById(String id) async {
    final row = await _client.from(_table).select().eq('id', id).single();
    return _fromRow(row as Map<String, dynamic>);
  }

  @override
  Future<EBook> update(String id, EBook data) async {
    final updated = await _client.from(_table).update(_toRow(data)).eq('id', id).select().single();
    return _fromRow(updated as Map<String, dynamic>);
  }

  @override
  Future<void> delete(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }

  Map<String, dynamic> _toRow(EBook e) {
    return {
      'id': e.id,
      'title': e.title,
      'author': e.author,
      'content': e.content,
      'cover_url': e.coverImageUrl,
      'added_at': e.addedAt.toIso8601String(),
      'last_read_at': e.lastReadAt?.toIso8601String(),
      'total_pages': e.totalPages,
      'current_page': e.currentPage,
      'progress': e.progress,
      'chapters': e.chapters,
    };
  }

  EBook _fromRow(Map<String, dynamic> row) {
    return EBook(
      id: row['id'] as String,
      title: row['title'] as String,
      author: row['author'] as String,
      content: row['content'] as String,
      coverImageUrl: row['cover_url'] as String?,
      addedAt: DateTime.parse(row['added_at'] as String),
      lastReadAt: row['last_read_at'] != null ? DateTime.parse(row['last_read_at'] as String) : null,
      totalPages: row['total_pages'] as int,
      currentPage: (row['current_page'] as num?)?.toInt() ?? 0,
      progress: (row['progress'] as num?)?.toDouble() ?? 0,
      chapters: (row['chapters'] as List?)?.map<String>((e) => e.toString()).toList() ?? const [],
    );
  }
}


