import 'package:flutter/material.dart' hide SearchBar;
import 'package:secure_notes_app/domain/models/note_model.dart';
import 'package:secure_notes_app/presentation/widgets/notes/empty_notes_state.dart';
import 'package:secure_notes_app/presentation/widgets/notes/empty_search_results.dart';
import 'package:secure_notes_app/presentation/widgets/notes/notes_list.dart';
import 'package:secure_notes_app/presentation/widgets/search_bar.dart';

class NotesBody extends StatelessWidget {
  final List<NoteModel> allNotes;
  final List<NoteModel> filteredNotes;
  final bool isSearching;
  final List<NoteModel> displayNotes;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<NoteModel> onNoteTap;
  final ValueChanged<String> onNoteDelete;

  const NotesBody({
    super.key,
    required this.allNotes,
    required this.filteredNotes,
    required this.isSearching,
    required this.displayNotes,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onNoteTap,
    required this.onNoteDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasNotes = displayNotes.isNotEmpty;

    return Column(
      children: [
        SearchBar(
          controller: searchController,
          onChanged: onSearchChanged,

          onClear: onClearSearch,
        ),
        if (isSearching && filteredNotes.isEmpty)
          const EmptySearchResults()
        else
          Expanded(
            child: hasNotes
                ? NotesList(
                    notes: displayNotes,
                    onNoteTap: onNoteTap,
                    onNoteDelete: onNoteDelete,
                  )
                : const EmptyNotesState(),
          ),
      ],
    );
  }
}