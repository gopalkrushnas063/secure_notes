// lib/presentation/view_models/notes_view_model.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:secure_notes_app/data/services/notes_service.dart';
import 'package:secure_notes_app/domain/models/note_model.dart';
import 'package:secure_notes_app/providers/providers.dart';

// Define NotesState class first
class NotesState {
  final List<NoteModel> notes;
  final List<NoteModel> filteredNotes;
  final bool isLoading;
  final String? error;

  const NotesState({
    required this.notes,
    required this.filteredNotes,
    this.isLoading = false,
    this.error,
  });

  factory NotesState.initial() {
    return const NotesState(
      notes: [],
      filteredNotes: [],
      isLoading: false,
      error: null,
    );
  }

  NotesState copyWith({
    List<NoteModel>? notes,
    List<NoteModel>? filteredNotes,
    bool? isLoading,
    String? error,
  }) {
    return NotesState(
      notes: notes ?? this.notes,
      filteredNotes: filteredNotes ?? this.filteredNotes,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Then define the ViewModel
class NotesViewModel extends StateNotifier<NotesState> {
  final NotesService _notesService;

  NotesViewModel(this._notesService) : super(NotesState.initial());

  Stream<List<NoteModel>> getNotesStream() {
    return _notesService.getNotesStream();
  }

  // New method to update notes list from stream
  void updateNotesList(List<NoteModel> notes) {
    state = state.copyWith(
      notes: notes,
      filteredNotes: notes,
    );
  }

  Future<void> createNote({
    required String title,
    required String content,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      await _notesService.createNote(title: title, content: content);
      // Don't update state here - let the stream update it
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> updateNote({
    required String id,
    required String title,
    required String content,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      await _notesService.updateNote(id: id, title: title, content: content);
      // Don't update state here - let the stream update it
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> deleteNote(String id) async {
    state = state.copyWith(isLoading: true);
    try {
      await _notesService.deleteNote(id);
      // Don't update state here - let the stream update it
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  void searchNotes(String query) {
    if (query.isEmpty) {
      state = state.copyWith(filteredNotes: state.notes);
    } else {
      final filtered = state.notes.where((note) {
        return note.title.toLowerCase().contains(query.toLowerCase());
      }).toList();
      state = state.copyWith(filteredNotes: filtered);
    }
  }

  void resetState() {
    state = NotesState.initial();
  }

  void clearSearch() {
    state = state.copyWith(filteredNotes: state.notes);
  }

  // Add this method to sort notes client-side
  void sortNotesByDate({bool descending = true}) {
    final sortedNotes = List<NoteModel>.from(state.notes);
    sortedNotes.sort(
      (a, b) => descending
          ? b.updatedAt.compareTo(a.updatedAt)
          : a.updatedAt.compareTo(b.updatedAt),
    );

    state = state.copyWith(notes: sortedNotes, filteredNotes: sortedNotes);
  }
}

// Provider definition
final notesViewModelProvider =
    StateNotifierProvider<NotesViewModel, NotesState>(
      (ref) => NotesViewModel(ref.read(notesServiceProvider)),
    );