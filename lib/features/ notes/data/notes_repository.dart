import 'package:cloud_firestore/cloud_firestore.dart';

import '../ model/note_model.dart';


class NotesRepository {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _notes =>
      _firestore.collection('notes');

  Stream<List<NoteModel>> getNotes() {
    return _notes
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map((doc) => NoteModel.fromDocument(doc))
          .toList(),
    );
  }

  Future<void> addNote({
    required String title,
    required String description,
  }) async {
    final cleanTitle = title.trim();

    if (cleanTitle.isEmpty) {
      throw ArgumentError('Title cannot be empty.');
    }

    final note = NoteModel(
      id: '',
      title: cleanTitle,
      description: description.trim(),
      isDone: false,
    );

    await _notes.add({
      ...note.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateNote({
    required String id,
    required String title,
    required String description,
  }) async {
    final cleanTitle = title.trim();

    if (cleanTitle.isEmpty) {
      throw ArgumentError('Title cannot be empty.');
    }

    await _notes.doc(id).update({
      'title': cleanTitle,
      'description': description.trim(),
    });
  }

  Future<void> updateIsDone({
    required String id,
    required bool isDone,
  }) async {
    await _notes.doc(id).update({
      'isDone': isDone,
    });
  }

  Future<void> deleteNote(String id) async {
    await _notes.doc(id).delete();
  }
}