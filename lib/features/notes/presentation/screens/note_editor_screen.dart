import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/service_locator.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../data/repositories/note_repository.dart';
import '../../domain/entities/note_entity.dart';

class NoteEditorScreen extends StatefulWidget {
  final String? noteId;
  const NoteEditorScreen({super.key, this.noteId});
  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final _repo = getIt<NoteRepository>();
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  bool _isNew = true;
  NoteEntity? _note;

  @override
  void initState() {
    super.initState();
    if (widget.noteId != null) _loadNote();
  }

  Future<void> _loadNote() async {
    // For existing notes loaded via stream in list, we get by ID
    final user = context.read<AuthCubit>().state.user;
    if (user == null) return;
    _repo.getNotesStream(user.id).first.then((notes) {
      final note = notes.where((n) => n.id == widget.noteId).firstOrNull;
      if (note != null && mounted) {
        setState(() {
          _note = note; _isNew = false;
          _titleCtrl.text = note.title;
          _contentCtrl.text = note.content;
        });
      }
    });
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title'), behavior: SnackBarBehavior.floating));
      return;
    }
    final user = context.read<AuthCubit>().state.user;
    if (user == null) return;

    try {
      if (_isNew) {
        final note = NoteEntity.create(
          userId: user.id,
          title: _titleCtrl.text.trim(),
          content: _contentCtrl.text,
        );
        await _repo.createNote(note);
      } else if (_note != null) {
        await _repo.updateNote(
          _note!.copyWith(
            title: _titleCtrl.text.trim(),
            content: _contentCtrl.text,
          ),
        );
      }
      if (mounted) context.pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _delete() async {
    if (_note == null) return;
    final confirmed = await showDialog<bool>(context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error))),
        ]));
    if (confirmed == true) {
      try {
        await _repo.deleteNote(_note!.id);
        if (mounted) context.pop(true);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'New Note' : 'Edit Note'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: () => context.pop()),
        actions: [
          if (!_isNew) IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.error), onPressed: _delete),
          IconButton(icon: const Icon(Icons.check_rounded), onPressed: _save),
        ],
      ),
      body: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
        TextField(controller: _titleCtrl,
          style: Theme.of(context).textTheme.headlineSmall,
          decoration: const InputDecoration(hintText: 'Note title...', border: InputBorder.none,
            enabledBorder: InputBorder.none, focusedBorder: InputBorder.none)),
        const Divider(),
        Expanded(child: TextField(controller: _contentCtrl,
          maxLines: null, expands: true, textAlignVertical: TextAlignVertical.top,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: const InputDecoration(hintText: 'Start writing...', border: InputBorder.none,
            enabledBorder: InputBorder.none, focusedBorder: InputBorder.none))),
      ])),
    );
  }
}
