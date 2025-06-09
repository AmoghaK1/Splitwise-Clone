import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:splitwise_clone/shared/loading.dart';
import 'add_friend_screen.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  Future<List<Map<String, dynamic>>> fetchFriends() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final friendIds = userDoc.data()?['friends'] ?? [];

    if (friendIds.isEmpty) return [];

    // Fetch each friend's info using their UID
    final List<Map<String, dynamic>> friendData = [];

    for (String friendId in friendIds) {
      final friendDoc = await FirebaseFirestore.instance.collection('users').doc(friendId).get();
      if (friendDoc.exists) {
        final data = friendDoc.data()!;
        friendData.add({
          'name': data['name'],
          'email': data['email'],
          'uid': friendId,
          'amount': 0, // Placeholder for personal expense, update as needed
        });
      }
    }

    return friendData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Friends"),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddFriendScreen()),
              );
            },
          )
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchFriends(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: Loading());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Feeling alone? Add some friends!",
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddFriendScreen()),
                      );
                    },
                    child: const Text("Add Friend"),
                  )
                ],
              ),
            );
          }

          final friends = snapshot.data!;
          return ListView.builder(
            itemCount: friends.length,
            itemBuilder: (context, index) {
              final friend = friends[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(friend['name'][0].toUpperCase()),
                ),
                title: Text(friend['name']),
                subtitle: Text('You owe: ₹${friend['amount']}'),
                onTap: () {
                  // Optional: Navigate to detail page
                },
              );
            },
          );
        },
      ),
    );
  }
}
