import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../../core/services/service_locator.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../data/repositories/note_repository.dart';
import '../../domain/entities/note_entity.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});
  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _repo = getIt<NoteRepository>();
  List<NoteEntity> _notes = [];
  bool _loading = true;
  StreamSubscription<List<NoteEntity>>? _notesSub;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final user = context.read<AuthCubit>().state.user;
    if (user == null) return;
    await _notesSub?.cancel();
    _notesSub = _repo.getNotesStream(user.id).listen((notes) {
      if (mounted) {
        setState(() {
          _notes = notes;
          _loading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _notesSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('Notes')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notes.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.note_add_rounded, size: 64,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                  const SizedBox(height: 16),
                  Text('No notes yet', style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                  const SizedBox(height: 12),
                  TextButton.icon(onPressed: () async {
                    await context.push('/note-editor');
                    if (!mounted) return;
                    _loadNotes();
                  },
                    icon: const Icon(Icons.add), label: const Text('Create Note')),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: _notes.length,
                  itemBuilder: (_, i) {
                    final note = _notes[i];
                    return StaggeredItem(index: i, child: GlassCard(
                      onTap: () async {
                        await context.push('/note-editor?id=${note.id}');
                        if (!mounted) return;
                        _loadNotes();
                      },
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(child: Text(note.title, style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 1, overflow: TextOverflow.ellipsis)),
                          if (note.linkedTaskId != null)
                            Icon(Icons.link, size: 16, color: AppColors.info),
                        ]),
                        if (note.content.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(note.content, maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall),
                        ],
                        const SizedBox(height: 8),
                        Text(DateFormat('MMM d, h:mm a').format(note.updatedAt),
                          style: Theme.of(context).textTheme.labelSmall),
                      ]),
                    ));
                  }),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/note-editor');
          if (!mounted) return;
          _loadNotes();
        },
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
