import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:splitwise_clone/screens/home/add_friend_screen.dart';

class AddGroupMembersScreen extends StatefulWidget {
  final String groupId;

  const AddGroupMembersScreen({super.key, required this.groupId});

  @override
  State<AddGroupMembersScreen> createState() => _AddGroupMembersScreenState();
}

class _AddGroupMembersScreenState extends State<AddGroupMembersScreen> {
  List<Map<String, dynamic>> _friends = [];
  Set<String> _selectedFriendIds = {};
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchFriends();
  }

  Future<void> _fetchFriends() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists && userDoc.data()?['friends'] != null) {
        final List<dynamic> rawFriendIds = userDoc.data()!['friends'];
        final friendIds = rawFriendIds.map((id) => id.toString().replaceAll("'", "")).toList();

        final friends = await Future.wait(
          friendIds.map((friendId) async {
            final friendDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(friendId)
                .get();
            return {
              '_id': friendId,
              'name': friendDoc.data()?['name'] ?? 'No Name',
              'email': friendDoc.data()?['email'] ?? 'No Email',
            };
          }),
        );

        setState(() {
          _friends = friends.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        setState(() {
          _friends = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching friends: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to load friends: ${e.toString()}"),
          duration: const Duration(seconds: 4),
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addMembersToGroup() async {
    print("Add to Group button pressed. Selected friend IDs: ");
    print(_selectedFriendIds);
    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final idToken = await user.getIdToken();
      final uri = Uri.parse('http://192.168.1.5:3000/groups/${widget.groupId}/members');
      print("Making request to: ");
      print(uri.toString());      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'memberIds': _selectedFriendIds.toList(),
          'userId': user.uid,
        }),
      ).timeout(const Duration(seconds: 10));

      print("Response status code: ${response.statusCode}");
      print("Response headers: ${response.headers}");
      print("Response body: ${response.body}");

      // Check if response is HTML (error page)
      if (response.headers['content-type']?.contains('text/html') ?? false) {
        throw Exception('Server returned an HTML error page. Check backend logs.');
      }

      dynamic responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (e) {
        print("Failed to parse JSON response: $e");
        print("Raw response body: ${response.body}");
        throw Exception('Invalid JSON response from server: ${e.toString()}');
      }
      
      if (response.statusCode == 200) {
        Navigator.pop(context, responseData['addedMembers']);
      } else {
        // Handle specific error cases
        String errorMsg;
        if (response.statusCode == 400) {
          if (responseData['message']?.contains('already in the group') == true) {
            errorMsg = 'Selected friends are already members of this group';
          } else {
            errorMsg = responseData['message'] ?? 'Invalid request';
          }
        } else if (response.statusCode == 404) {
          errorMsg = 'Group not found';
        } else {
          errorMsg = responseData['message'] ?? 
                     responseData['error'] ?? 
                     'Failed to add members (Status ${response.statusCode})';
        }
        throw Exception(errorMsg);
      }
    } on http.ClientException catch (e) {
      print('Network error: ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: ${e.message}'),
          duration: const Duration(seconds: 4),
        ),
      );
    } on TimeoutException {
      print('Request timed out. Server might be down.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request timed out. Server might be down.'),
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      print('Failed to add members: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add members: ${e.toString()}'),
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Members"),
        backgroundColor: Colors.teal[800],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_friends.isEmpty)
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "You don't have any friends yet.",
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Can't find someone? Try adding them as a friend first!",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  if (_friends.isNotEmpty) ...[
                    const Text(
                      "Select friends to add to the group:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _friends.length,
                        itemBuilder: (context, index) {
                          final friend = _friends[index];
                          final isSelected = _selectedFriendIds.contains(friend['_id']);

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: CheckboxListTile(
                              value: isSelected,
                              onChanged: (selected) {
                                setState(() {
                                  if (selected == true) {
                                    _selectedFriendIds.add(friend['_id']);
                                  } else {
                                    _selectedFriendIds.remove(friend['_id']);
                                  }
                                });
                              },
                              title: Text(
                                friend['name'],
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              subtitle: Text(friend['email']),
                              secondary: const Icon(Icons.person),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: _isSubmitting
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.group_add),
                        label: Text(
                          _isSubmitting ? "Adding..." : "Add to Group",
                          style: const TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal[800],
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _isSubmitting || _selectedFriendIds.isEmpty
                            ? null
                            : _addMembersToGroup,
                      ),
                    ),
                  ],
                  SizedBox(height: 30,),
                  ElevatedButton(onPressed: () {
                    Navigator.push(
                     context,
                   MaterialPageRoute(builder: (_) => const AddFriendScreen()),
                   );
                  }, 
                  child: const Text("Add friends"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal[800],
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  ),
                ],
              ),
            ),
    );
  }
}