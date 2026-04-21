import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

class NoteEntity extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String content;       // Rich text JSON from flutter_quill
  final String? linkedTaskId; // Optional task attachment
  final DateTime createdAt;
  final DateTime updatedAt;

  const NoteEntity({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    this.linkedTaskId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NoteEntity.create({
    required String userId,
    required String title,
    String content = '',
    String? linkedTaskId,
  }) {
    final now = DateTime.now();
    return NoteEntity(
      id: const Uuid().v4(),
      userId: userId,
      title: title,
      content: content,
      linkedTaskId: linkedTaskId,
      createdAt: now,
      updatedAt: now,
    );
  }

  NoteEntity copyWith({
    String? title,
    String? content,
    String? linkedTaskId,
    DateTime? updatedAt,
  }) {
    return NoteEntity(
      id: id,
      userId: userId,
      title: title ?? this.title,
      content: content ?? this.content,
      linkedTaskId: linkedTaskId ?? this.linkedTaskId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'content': content,
      'linked_task_id': linkedTaskId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory NoteEntity.fromMap(Map<String, dynamic> map) {
    return NoteEntity(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      linkedTaskId: map['linked_task_id'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  @override
  List<Object?> get props => [id, userId, title, content, linkedTaskId];
}
