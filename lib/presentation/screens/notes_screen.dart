// lib/presentation/screens/notes_screen.dart
import 'dart:async';

import 'package:flutter/material.dart' hide SearchBar;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:secure_notes_app/domain/models/note_model.dart';
import 'package:secure_notes_app/presentation/screens/auth_screen.dart';
import 'package:secure_notes_app/presentation/widgets/note_card.dart';
import 'package:secure_notes_app/presentation/widgets/search_bar.dart';
import 'package:secure_notes_app/providers/providers.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  final _searchController = TextEditingController();
  StreamSubscription<List<NoteModel>>? _notesSubscription;
  List<NoteModel> _notes = [];

  @override
  void initState() {
    super.initState();
    // Initialize the stream listener immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupNotesListener();
    });
  }

  @override
  void dispose() {
    _notesSubscription?.cancel();
    _notesSubscription = null;
    _searchController.dispose();
    super.dispose();
  }

  void _setupNotesListener() {
    // Cancel any existing subscription
    _notesSubscription?.cancel();

    // Get notes stream from Service (not ViewModel)
    final notesStream = ref.read(notesServiceProvider).getNotesStream();

    // Listen to notes stream and update local state
    _notesSubscription = notesStream.listen(
      (notes) {
        setState(() {
          _notes = notes;
        });
        // Apply current search filter
        _applySearchFilter(_searchController.text);
      },
      onError: (error) {
        print('Notes stream error: $error');
      },
    );
  }

  void _applySearchFilter(String query) {
    if (query.isEmpty) {
      ref.read(notesViewModelProvider.notifier).updateNotesList(_notes);
    } else {
      final filtered = _notes.where((note) {
        return note.title.toLowerCase().contains(query.toLowerCase());
      }).toList();
      ref.read(notesViewModelProvider.notifier).updateNotesList(filtered);
    }
  }

  void _showNoteDialog({NoteModel? note}) {
    final user = ref.read(authViewModelProvider.select((state) => state.user));
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to create notes'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final titleController = TextEditingController(text: note?.title ?? '');
    final contentController = TextEditingController(text: note?.content ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(note == null ? 'Create Note' : 'Edit Note'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(
                    labelText: 'Content',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty &&
                    contentController.text.isNotEmpty) {
                  try {
                    if (note == null) {
                      await ref
                          .read(notesViewModelProvider.notifier)
                          .createNote(
                            title: titleController.text,
                            content: contentController.text,
                          );
                    } else {
                      await ref
                          .read(notesViewModelProvider.notifier)
                          .updateNote(
                            id: note.id,
                            title: titleController.text,
                            content: contentController.text,
                          );
                    }
                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteNote(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Note'),
          content: const Text('Are you sure you want to delete this note?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await ref.read(notesViewModelProvider.notifier).deleteNote(id);

        // Remove from local list immediately for better UX
        setState(() {
          _notes = _notes.where((note) => note.id != id).toList();
          _applySearchFilter(_searchController.text);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final notesState = ref.watch(notesViewModelProvider);
    final user = ref.watch(authViewModelProvider.select((state) => state.user));
    final authState = ref.watch(authViewModelProvider);

    // If not authenticated, show loading (MyApp should navigate away)
    if (!authState.isAuthenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('My Notes (${user?.email ?? 'User'})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              try {
                // Clear the notes stream before logging out
                _notesSubscription?.cancel();
                _notesSubscription = null;
                setState(() {
                  _notes = [];
                });

                await ref.read(authViewModelProvider.notifier).signOut();

                // Navigate to auth screen
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const AuthScreen()),
                  (route) => false,
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          SearchBar(
            controller: _searchController,
            onChanged: (query) {
              _applySearchFilter(query);
            },
            onClear: () {
              _searchController.clear();
              _applySearchFilter('');
            },
          ),
          Expanded(
            child: notesState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : notesState.filteredNotes.isEmpty
                ? const Center(
                    child: Text(
                      'No notes found',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: notesState.filteredNotes.length,
                    itemBuilder: (context, index) {
                      final note = notesState.filteredNotes[index];
                      return NoteCard(
                        note: note,
                        onTap: () => _showNoteDialog(note: note),
                        onDelete: () => _deleteNote(note.id),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNoteDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
