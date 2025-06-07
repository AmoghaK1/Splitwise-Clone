import 'package:flutter/material.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> friends = [
      {'name': 'John', 'owes': 50, 'owed': 100},
      {'name': 'Emily', 'owes': 0, 'owed': 30},
      {'name': 'Mark', 'owes': 20, 'owed': 0},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        backgroundColor: Colors.teal[800],
      ),
      body: ListView.builder(
        itemCount: friends.length,
        itemBuilder: (context, index) {
          final friend = friends[index];
          final String name = friend['name'] as String;
          final int owes = friend['owes'] as int;
          final int owed = friend['owed'] as int;

          return ListTile(
            leading: CircleAvatar(child: Text(name[0])),
            title: Text(name),
            subtitle: Text(
              'You owe: ₹$owes | Owed: ₹$owed',
              style: const TextStyle(fontSize: 14),
            ),
          );
        },
      ),
    );
  }
}
