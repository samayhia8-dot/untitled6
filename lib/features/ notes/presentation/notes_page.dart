import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../ cubit/notes_cubit.dart';
import '../ cubit/notes_state.dart';
import '../ model/note_model.dart';


class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  Future<void> _addNote() async {
    if (!_formKey.currentState!.validate()) return;

    await context.read<NotesCubit>().addNote(
      title: _titleController.text,
      description: _descriptionController.text,
    );

    if (!mounted) return;

    if (context.read<NotesCubit>().state.status !=
        NotesStatus.failure) {
      _titleController.clear();
      _descriptionController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  Future<void> _editNote(NoteModel note) async {
    final titleController =
    TextEditingController(text: note.title);

    final descriptionController =
    TextEditingController(text: note.description);

    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        bool isSaving = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Note'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Title is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                    if (!formKey.currentState!.validate()) {
                      return;
                    }

                    setDialogState(() {
                      isSaving = true;
                    });

                    await this.context
                        .read<NotesCubit>()
                        .updateNote(
                      id: note.id,
                      title: titleController.text,
                      description:
                      descriptionController.text,
                    );

                    if (!dialogContext.mounted) return;

                    Navigator.pop(dialogContext);
                  },
                  child: isSaving
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    descriptionController.dispose();
  }

  Future<void> _deleteNote(NoteModel note) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Note?'),
          content: Text(
            'Are you sure you want to delete "${note.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true || !mounted) return;

    await context.read<NotesCubit>().deleteNote(note.id);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NotesCubit, NotesState>(
      listenWhen: (previous, current) =>
      previous.errorMessage != current.errorMessage ||
          previous.successMessage != current.successMessage,
      listener: (context, state) {
        if (state.errorMessage != null) {
          _showMessage(state.errorMessage!);
        } else if (state.successMessage != null) {
          _showMessage(state.successMessage!);
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('My Notes'),
            centerTitle: true,
          ),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _titleController,
                              decoration: const InputDecoration(
                                labelText: 'Title *',
                                hintText: 'Enter note title',
                                prefixIcon: Icon(Icons.title),
                              ),
                              validator: (value) {
                                if (value == null ||
                                    value.trim().isEmpty) {
                                  return 'Title is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _descriptionController,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                labelText: 'Description',
                                hintText: 'Enter description',
                                prefixIcon: Icon(Icons.notes),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed:
                                state.status == NotesStatus.loading
                                    ? null
                                    : _addNote,
                                icon: const Icon(Icons.add),
                                label: const Text('Add Note'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (state.status == NotesStatus.loading)
                  const LinearProgressIndicator(),
                Expanded(
                  child: _buildNotesList(state),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotesList(NotesState state) {
    if (state.status == NotesStatus.initial ||
        (state.status == NotesStatus.loading &&
            state.notes.isEmpty)) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.status == NotesStatus.failure &&
        state.notes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48),
              const SizedBox(height: 12),
              Text(
                state.errorMessage ?? 'Could not load notes.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed:
                context.read<NotesCubit>().listenToNotes,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.notes.isEmpty) {
      return const Center(
        child: Text('No notes yet. Add your first note!'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: state.notes.length,
      separatorBuilder: (_, __) =>
      const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final note = state.notes[index];

        return Card(
          child: ListTile(
            leading: Checkbox(
              value: note.isDone,
              onChanged: (value) {
                if (value != null) {
                  context.read<NotesCubit>().toggleNote(
                    note,
                    value,
                  );
                }
              },
            ),
            title: Text(
              note.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                decoration: note.isDone
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
            subtitle: Text(
              '${note.description}\nID: ${note.id}',
            ),
            isThreeLine: true,

            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.edit,
                    color: Colors.blue,
                  ),
                  tooltip: 'Edit',
                  onPressed: () => _editNote(note),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete,
                    color: Colors.red,
                  ),
                  tooltip: 'Delete',
                  onPressed: () => _deleteNote(note),
                ),
              ],
            ),

          ),
        );
      },
    );
  }
}