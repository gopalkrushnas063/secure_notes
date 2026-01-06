import 'package:flutter/material.dart';
import 'package:secure_notes_app/domain/models/user_model.dart';

class NotesAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int totalNotes;
  final bool isSearching;
  final int searchResultsCount;
  final VoidCallback onLogout;
  final UserModel user;

  const NotesAppBar({
    super.key,
    required this.totalNotes,
    required this.isSearching,
    required this.searchResultsCount,
    required this.onLogout,
    required this.user,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            user.email,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (isSearching)
            Text(
              '$searchResultsCount result${searchResultsCount == 1 ? '' : 's'} found',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            )
          else
            Text(
              '$totalNotes note${totalNotes == 1 ? '' : 's'}',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
        ],
      ),

      actions: [
        SizedBox.shrink(),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'logout') onLogout();
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
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
    );
  }
}
