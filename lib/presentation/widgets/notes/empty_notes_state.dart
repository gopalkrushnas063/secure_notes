import 'package:flutter/material.dart';

class EmptyNotesState extends StatelessWidget {
  const EmptyNotesState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.note_add, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          Text(
            'No notes yet',
            style: TextStyle(fontSize: 20, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 10),
          Text(
            'Create your first note by tapping +',
            style: TextStyle(color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}