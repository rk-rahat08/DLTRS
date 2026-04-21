import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/note_entity.dart';

class NoteRepository {
  final SupabaseClient _supabase;

  NoteRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  String get _notesTable => 'notes';

  Future<NoteEntity> createNote(NoteEntity note) async {
    try {
      await _supabase.from(_notesTable).insert(note.toMap());
      return note;
    } on PostgrestException catch (e) {
      throw Exception(_mapTableError(e));
    }
  }

  Future<NoteEntity> updateNote(NoteEntity note) async {
    final updated = note.copyWith(updatedAt: DateTime.now());
    try {
      await _supabase
          .from(_notesTable)
          .update(updated.toMap())
          .eq('id', note.id);
      return updated;
    } on PostgrestException catch (e) {
      throw Exception(_mapTableError(e));
    }
  }

  Future<void> deleteNote(String noteId) async {
    try {
      await _supabase.from(_notesTable).delete().eq('id', noteId);
    } on PostgrestException catch (e) {
      throw Exception(_mapTableError(e));
    }
  }

  Stream<List<NoteEntity>> getNotesStream(String userId) {
    return _supabase
        .from(_notesTable)
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('updated_at', ascending: false)
        .map((data) => data.map((map) => NoteEntity.fromMap(map)).toList());
  }

  Future<List<NoteEntity>> getNotesForTask(String taskId) async {
    try {
      final data = await _supabase
          .from(_notesTable)
          .select()
          .eq('linked_task_id', taskId);

      return (data as List).map((d) => NoteEntity.fromMap(d)).toList();
    } on PostgrestException catch (e) {
      throw Exception(_mapTableError(e));
    }
  }

  String _mapTableError(PostgrestException error) {
    final message = error.message.toLowerCase();
    if (message.contains('relation') && message.contains('does not exist')) {
      return 'Supabase table "notes" is missing. Create the notes table before using notes.';
    }
    if (message.contains('row-level security') ||
        message.contains('permission denied')) {
      return 'Supabase blocked access to "notes". Add authenticated select/insert/update/delete policies.';
    }
    return error.message;
  }
}
