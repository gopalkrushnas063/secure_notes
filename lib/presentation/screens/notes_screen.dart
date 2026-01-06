// lib/presentation/screens/notes_screen.dart
import 'dart:async';

import 'package:flutter/material.dart' hide SearchBar;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:secure_notes_app/domain/models/note_model.dart';
import 'package:secure_notes_app/presentation/screens/auth_screen.dart';
import 'package:secure_notes_app/presentation/widgets/note_card.dart';
import 'package:secure_notes_app/presentation/widgets/notes/delete_confirmation_dialog.dart';
import 'package:secure_notes_app/presentation/widgets/notes/loading_screen.dart';
import 'package:secure_notes_app/presentation/widgets/notes/note_dialog.dart';
import 'package:secure_notes_app/presentation/widgets/notes/notes_app_bar.dart';
import 'package:secure_notes_app/presentation/widgets/notes/notes_body.dart';
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
  List<NoteModel> _allNotes = [];
  List<NoteModel> _filteredNotes = [];
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
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _setupNotesListener() {
    _notesSubscription?.cancel();

    final notesStream = ref.read(notesServiceProvider).getNotesStream();

    _notesSubscription = notesStream.listen((notes) {
      if (mounted) {
        setState(() {
          _allNotes = notes;
          _applySearchFilter(_searchController.text);
        });
      }
    }, onError: (error) => print('Notes stream error: $error'));
  }

  void _applySearchFilter(String query) {
    _searchDebounce?.cancel();

    if (query.isEmpty) {
      setState(() {
        _filteredNotes = List.from(_allNotes);
        _isSearching = false;
      });
      return;
    }

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

  Future<void> _handleLogout() async {
    try {
      _notesSubscription?.cancel();
      setState(() {
        _allNotes = [];
        _filteredNotes = [];
      });

      await ref.read(authViewModelProvider.notifier).signOut();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthScreen()),
        (route) => false,
      );
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final user = authState.user;

    if (!authState.isAuthenticated) {
      return const LoadingScreen();
    }

    final displayNotes = _isSearching ? _filteredNotes : _allNotes;
    final totalNotes = _allNotes.length;
    final searchResultsCount = _filteredNotes.length;

    return Scaffold(
      appBar: NotesAppBar(
        user: user!,
        totalNotes: totalNotes,
        isSearching: _isSearching,
        searchResultsCount: searchResultsCount,
        onLogout: () => _showLogoutDialog(),
      ),
      body: NotesBody(
        allNotes: _allNotes,
        filteredNotes: _filteredNotes,
        isSearching: _isSearching,
        displayNotes: displayNotes,
        searchController: _searchController,
        onSearchChanged: _applySearchFilter,
        onClearSearch: _clearSearch,
        onNoteTap: (note) => _showNoteDialog(note: note),
        onNoteDelete: (id) => _deleteNote(id),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNoteDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  // =============== DIALOG METHODS ===============

  void _showNoteDialog({NoteModel? note}) {
    final user = ref.read(authViewModelProvider.select((state) => state.user));
    if (user == null) {
      _showSnackBar('You must be logged in to create notes', Colors.red);
      return;
    }

    showDialog(
      context: context,
      builder: (context) =>
          NoteDialog(note: note, onCreate: _createNote, onUpdate: _updateNote),
    );
  }

  Future<void> _createNote(String title, String content) async {
    try {
      await ref
          .read(notesServiceProvider)
          .createNote(title: title, content: content);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', Colors.red);
    }
  }

  Future<void> _updateNote(String id, String title, String content) async {
    try {
      await ref
          .read(notesServiceProvider)
          .updateNote(id: id, title: title, content: content);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', Colors.red);
    }
  }

  Future<void> _deleteNote(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => DeleteConfirmationDialog(
        title: 'Delete Note',
        content: 'Are you sure you want to delete this note?',
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(notesServiceProvider).deleteNote(id);

      setState(() {
        _allNotes = _allNotes.where((note) => note.id != id).toList();
        _applySearchFilter(_searchController.text);
      });

      _showSnackBar('Note deleted successfully', Colors.green);
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', Colors.red);
    }
  }

  void _showLogoutDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => DeleteConfirmationDialog(
        title: 'Logout',
        content: 'Are you sure you want to logout?',
        confirmText: 'Logout',
      ),
    );

    if (confirmed == true) {
      await _handleLogout();
    }
  }
}

// =============== REUSABLE WIDGETS ===============

















