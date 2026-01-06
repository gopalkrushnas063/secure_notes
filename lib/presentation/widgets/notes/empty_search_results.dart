import 'package:flutter/material.dart';

class EmptySearchResults extends StatelessWidget {
  const EmptySearchResults({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(Icons.search_off, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
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
    );
  }
}