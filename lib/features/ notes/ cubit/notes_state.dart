import '../ model/note_model.dart';


enum NotesStatus {
  initial,
  loading,
  success,
  failure,
}

class NotesState {
  final NotesStatus status;
  final List<NoteModel> notes;
  final String? errorMessage;
  final String? successMessage;

  const NotesState({
    this.status = NotesStatus.initial,
    this.notes = const [],
    this.errorMessage,
    this.successMessage,
  });

  NotesState copyWith({
    NotesStatus? status,
    List<NoteModel>? notes,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return NotesState(
      status: status ?? this.status,
      notes: notes ?? this.notes,
      errorMessage:
      clearError ? null : errorMessage ?? this.errorMessage,
      successMessage: clearSuccess
          ? null
          : successMessage ?? this.successMessage,
    );
  }
}