// lib/data/services/notes_service.dart
import 'package:secure_notes_app/data/repositories/notes_repository.dart';
import 'package:secure_notes_app/domain/models/note_model.dart';

class NotesService {
  final NotesRepository _notesRepository;

  NotesService(this._notesRepository);

  // This must be called when user logs in
  void setCurrentUser(String userId) {
    _notesRepository.setCurrentUserId(userId);
  }

  // This must be called when user logs out
  void clearCurrentUser() {
    _notesRepository.clearCurrentUserId();
  }

  Stream<List<NoteModel>> getNotesStream() {
    return _notesRepository.getNotesStream();
  }

  Future<NoteModel> createNote({
    required String title,
    required String content,
  }) async {
    return _notesRepository.createNote(title: title, content: content);
  }

  Future<void> updateNote({
    required String id,
    required String title,
    required String content,
  }) async {
    return _notesRepository.updateNote(id: id, title: title, content: content);
  }

  Future<void> deleteNote(String id) async {
    return _notesRepository.deleteNote(id);
  }

  Future<List<NoteModel>> searchNotes(String query) async {
    return _notesRepository.searchNotes(query);
  }
}
