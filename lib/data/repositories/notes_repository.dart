// lib/data/repositories/notes_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:secure_notes_app/domain/models/note_model.dart';

class NotesRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Always use the current user's ID to ensure security
  String? _currentUserId;

  // Set the current user ID - should be called after authentication
  void setCurrentUserId(String userId) {
    _currentUserId = userId;
  }

  // Clear current user ID on logout
  void clearCurrentUserId() {
    _currentUserId = null;
  }

  // Get the notes collection reference with user_id filter
  Query get _notesQuery {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }
    return _firestore
        .collection('notes')
        .where('user_id', isEqualTo: _currentUserId);
  }

  Stream<List<NoteModel>> getNotesStream() {
    if (_currentUserId == null) {
      // Return an empty stream when no user is logged in
      return Stream.value([]);
    }

    try {
      return _notesQuery.snapshots().map((snapshot) {
        final notes = snapshot.docs.map((doc) {
          return NoteModel.fromFirestore(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
        }).toList();

        // Client-side sorting by updated_at in descending order
        notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

        return notes;
      });
    } catch (e) {
      // Return empty stream on any error
      return Stream.value([]);
    }
  }

  Future<NoteModel> createNote({
    required String title,
    required String content,
  }) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final now = DateTime.now();
    final docRef = await _firestore.collection('notes').add({
      'title': title,
      'content': content,
      'created_at': Timestamp.fromDate(now),
      'updated_at': Timestamp.fromDate(now),
      'user_id': _currentUserId!, // Always set the current user's ID
    });

    return NoteModel(
      id: docRef.id,
      title: title,
      content: content,
      createdAt: now,
      updatedAt: now,
      userId: _currentUserId!,
    );
  }

  Future<void> updateNote({
    required String id,
    required String title,
    required String content,
  }) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    // First verify the note belongs to the current user
    final noteDoc = await _firestore.collection('notes').doc(id).get();
    if (!noteDoc.exists) {
      throw Exception('Note not found');
    }

    final noteData = noteDoc.data();
    if (noteData == null || noteData['user_id'] != _currentUserId) {
      throw Exception('You do not have permission to update this note');
    }

    await _firestore.collection('notes').doc(id).update({
      'title': title,
      'content': content,
      'updated_at': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> deleteNote(String id) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    // First verify the note belongs to the current user
    final noteDoc = await _firestore.collection('notes').doc(id).get();
    if (!noteDoc.exists) {
      throw Exception('Note not found');
    }

    final noteData = noteDoc.data();
    if (noteData == null || noteData['user_id'] != _currentUserId) {
      throw Exception('You do not have permission to delete this note');
    }

    await _firestore.collection('notes').doc(id).delete();
  }

  Future<List<NoteModel>> searchNotes(String query) async {
    if (_currentUserId == null) {
      return [];
    }

    try {
      final snapshot = await _notesQuery.get();
      final allNotes = snapshot.docs.map((doc) {
        return NoteModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();

      // Client-side sorting
      allNotes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      if (query.isEmpty) {
        return allNotes;
      }

      return allNotes.where((note) {
        return note.title.toLowerCase().contains(query.toLowerCase());
      }).toList();
    } catch (e) {
      // Return empty list on permission error
      print('Search error: $e');
      return [];
    }
  }
}
