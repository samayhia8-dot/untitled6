import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../ model/note_model.dart';
import '../data/notes_repository.dart';

import 'notes_state.dart';

class NotesCubit extends Cubit<NotesState> {
  NotesCubit(this._repository) : super(const NotesState());

  final NotesRepository _repository;

  StreamSubscription<List<NoteModel>>? _subscription;

  void listenToNotes() {
    emit(state.copyWith(
      status: NotesStatus.loading,
      clearError: true,
      clearSuccess: true,
    ));

    _subscription?.cancel();

    _subscription = _repository.getNotes().listen(
          (notes) {
        emit(state.copyWith(
          status: NotesStatus.success,
          notes: notes,
          clearError: true,
        ));
      },
      onError: (Object error) {
        emit(state.copyWith(
          status: NotesStatus.failure,
          errorMessage: _errorText(error),
          clearSuccess: true,
        ));
      },
    );
  }

  Future<void> addNote({
    required String title,
    required String description,
  }) async {
    if (title.trim().isEmpty) {
      emit(state.copyWith(
        status: NotesStatus.failure,
        errorMessage: 'Title cannot be empty.',
        clearSuccess: true,
      ));
      return;
    }

    emit(state.copyWith(
      status: NotesStatus.loading,
      clearError: true,
      clearSuccess: true,
    ));

    try {
      await _repository.addNote(
        title: title,
        description: description,
      );

      emit(state.copyWith(
        status: NotesStatus.success,
        successMessage: 'Note added successfully.',
        clearError: true,
      ));
    } catch (error) {
      emit(state.copyWith(
        status: NotesStatus.failure,
        errorMessage: _errorText(error),
      ));
    }
  }

  Future<void> updateNote({
    required String id,
    required String title,
    required String description,
  }) async {
    if (title.trim().isEmpty) {
      emit(state.copyWith(
        status: NotesStatus.failure,
        errorMessage: 'Title cannot be empty.',
        clearSuccess: true,
      ));
      return;
    }

    emit(state.copyWith(
      status: NotesStatus.loading,
      clearError: true,
      clearSuccess: true,
    ));

    try {
      await _repository.updateNote(
        id: id,
        title: title,
        description: description,
      );

      emit(state.copyWith(
        status: NotesStatus.success,
        successMessage: 'Note updated successfully.',
        clearError: true,
      ));
    } catch (error) {
      emit(state.copyWith(
        status: NotesStatus.failure,
        errorMessage: _errorText(error),
      ));
    }
  }

  Future<void> toggleNote(
      NoteModel note,
      bool isDone,
      ) async {
    try {
      await _repository.updateIsDone(
        id: note.id,
        isDone: isDone,
      );
    } catch (error) {
      emit(state.copyWith(
        status: NotesStatus.failure,
        errorMessage: _errorText(error),
        clearSuccess: true,
      ));
    }
  }

  Future<void> deleteNote(String id) async {
    emit(state.copyWith(
      status: NotesStatus.loading,
      clearError: true,
      clearSuccess: true,
    ));

    try {
      await _repository.deleteNote(id);

      emit(state.copyWith(
        status: NotesStatus.success,
        successMessage: 'Note deleted successfully.',
        clearError: true,
      ));
    } catch (error) {
      emit(state.copyWith(
        status: NotesStatus.failure,
        errorMessage: _errorText(error),
      ));
    }
  }

  String _errorText(Object error) {
    if (error is ArgumentError) {
      return error.message?.toString() ?? 'Invalid input.';
    }

    final text = error.toString();

    if (text.contains('permission-denied')) {
      return 'Permission denied. Check Firestore rules.';
    }

    if (text.contains('unavailable')) {
      return 'Firestore is unavailable. Check your connection.';
    }

    return 'Something went wrong. Please try again.';
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}