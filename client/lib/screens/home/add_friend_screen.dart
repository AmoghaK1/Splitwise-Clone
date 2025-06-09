import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({super.key});

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  String get currentUserId => _auth.currentUser!.uid;

  Future<void> _searchUsers(String query) async {
    setState(() {
      _isLoading = true;
      _results.clear();
    });

    final snapshot = await _firestore.collection('users')
        .where('search_keywords', arrayContains: query.toLowerCase())
        .get();

    final users = snapshot.docs
        .where((doc) => doc.id != currentUserId)
        .map((doc) => {
              'uid': doc.id,
              'name': doc['name'],
              'email': doc['email'],
            })
        .toList();

    setState(() {
      _results = users;
      _isLoading = false;
    });
  }

  Future<void> _addFriend(String friendUid) async {
    final currentUserRef = _firestore.collection('users').doc(currentUserId);
    final friendUserRef = _firestore.collection('users').doc(friendUid);

    await _firestore.runTransaction((txn) async {
      final currentSnapshot = await txn.get(currentUserRef);
      final friendSnapshot = await txn.get(friendUserRef);

      List currentFriends = currentSnapshot['friends'] ?? [];
      List friendFriends = friendSnapshot['friends'] ?? [];

      if (!currentFriends.contains(friendUid)) {
        currentFriends.add(friendUid);
        txn.update(currentUserRef, {'friends': currentFriends});
      }

      if (!friendFriends.contains(currentUserId)) {
        friendFriends.add(currentUserId);
        txn.update(friendUserRef, {'friends': friendFriends});
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Friend added successfully!")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Friend")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: "Search by name, email or phone",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _searchUsers(_searchController.text.trim()),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : Expanded(
                    child: _results.isEmpty
                        ? const Text("No users found.")
                        : ListView.builder(
                            itemCount: _results.length,
                            itemBuilder: (context, index) {
                              final user = _results[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  child: Text(user['name'][0].toUpperCase()),
                                ),
                                title: Text(user['name']),
                                subtitle: Text(user['email']),
                                trailing: ElevatedButton(
                                  child: const Text("Add Friend"),
                                  onPressed: () => _addFriend(user['uid']),
                                ),
                              );
                            },
                          ),
                  ),
          ],
        ),
      ),
    );
  }
}
