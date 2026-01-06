import 'package:flutter/material.dart';
import 'package:secure_notes_app/domain/models/note_model.dart';
import 'package:secure_notes_app/presentation/widgets/note_card.dart';

class NotesList extends StatelessWidget {
  final List<NoteModel> notes;
  final ValueChanged<NoteModel> onNoteTap;
  final ValueChanged<String> onNoteDelete;

  const NotesList({
    super.key,
    required this.notes,
    required this.onNoteTap,
    required this.onNoteDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return NoteCard(
          note: note,
          onTap: () => onNoteTap(note),
          onDelete: () => onNoteDelete(note.id),
        );
      },
    );
  }
}