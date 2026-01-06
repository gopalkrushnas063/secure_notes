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
  List<NoteModel> _allNotes = []; // Store all notes here
  List<NoteModel> _filteredNotes = []; // Store filtered notes here
  bool _isSearching = false;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _setupNotesListener();
  }

  @override
  void dispose() {
    _notesSubscription?.cancel();
    _notesSubscription = null;
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _setupNotesListener() {
    // Cancel any existing subscription
    _notesSubscription?.cancel();

    // Get notes stream from Service
    final notesStream = ref.read(notesServiceProvider).getNotesStream();

    // Listen to notes stream and update local state
    _notesSubscription = notesStream.listen(
      (notes) {
        if (mounted) {
          setState(() {
            _allNotes = notes;
            // Apply current search filter when new notes arrive
            _applySearchFilter(_searchController.text);
          });
        }
      },
      onError: (error) {
        print('Notes stream error: $error');
      },
    );
  }

  void _applySearchFilter(String query) {
    // Cancel previous debounce timer
    _searchDebounce?.cancel();

    if (query.isEmpty) {
      setState(() {
        _filteredNotes = List.from(_allNotes);
        _isSearching = false;
      });
      return;
    }

    // Debounce search to avoid rebuilding on every keystroke
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      final lowerQuery = query.toLowerCase();
      final filtered = _allNotes.where((note) {
        return note.title.toLowerCase().contains(lowerQuery) ||
            note.content.toLowerCase().contains(lowerQuery);
      }).toList();

      if (mounted) {
        setState(() {
          _filteredNotes = filtered;
          _isSearching = true;
        });
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _filteredNotes = List.from(_allNotes);
      _isSearching = false;
    });
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
                          .read(notesServiceProvider)
                          .createNote(
                            title: titleController.text,
                            content: contentController.text,
                          );
                    } else {
                      await ref
                          .read(notesServiceProvider)
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
        await ref.read(notesServiceProvider).deleteNote(id);

        // Remove from local list immediately for better UX
        setState(() {
          _allNotes = _allNotes.where((note) => note.id != id).toList();
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
    final user = ref.watch(authViewModelProvider.select((state) => state.user));
    final authState = ref.watch(authViewModelProvider);

    // If not authenticated, show loading (MyApp should navigate away)
    if (!authState.isAuthenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final displayNotes = _isSearching ? _filteredNotes : _allNotes;
    final hasNotes = displayNotes.isNotEmpty;
    final totalNotes = _allNotes.length;
    final searchResultsCount = _filteredNotes.length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'My Notes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (_isSearching)
              Text(
                '$searchResultsCount result${searchResultsCount == 1 ? '' : 's'} found',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              )
            else
              Text(
                '$totalNotes note${totalNotes == 1 ? '' : 's'}',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
          ],
        ),
        actions: [
          // IconButton(
          //   icon: Icon(_isSearching ? Icons.clear : Icons.search),
          //   onPressed: () {
          //     if (_isSearching) {
          //       _clearSearch();
          //     } else {
          //       // Optionally focus on search
          //       // You could add a search bar in app bar if needed
          //     }
          //   },
          // ),
          SizedBox.shrink(),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _showLogoutDialog();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 10),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
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
              _clearSearch();
            },
          ),
          if (_isSearching && _filteredNotes.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.search_off, size: 60, color: Colors.grey.shade300),
                  SizedBox(height: 16),
                  Text(
                    'No notes found',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                  Text(
                    'Try different search terms',
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: hasNotes
                  ? ListView.builder(
                      itemCount: displayNotes.length,
                      itemBuilder: (context, index) {
                        final note = displayNotes[index];
                        return NoteCard(
                          note: note,
                          onTap: () => _showNoteDialog(note: note),
                          onDelete: () => _deleteNote(note.id),
                        );
                      },
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.note_add,
                            size: 80,
                            color: Colors.grey.shade300,
                          ),
                          SizedBox(height: 20),
                          Text(
                            'No notes yet',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Create your first note by tapping +',
                            style: TextStyle(color: Colors.grey.shade400),
                          ),
                        ],
                      ),
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

  void _showLogoutDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Logout'),
          content: Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        // Clear the notes stream before logging out
        _notesSubscription?.cancel();
        _notesSubscription = null;
        setState(() {
          _allNotes = [];
          _filteredNotes = [];
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
    }
  }
}
