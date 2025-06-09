import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';

class AddGroupScreen extends StatefulWidget {
  const AddGroupScreen({super.key});

  @override
  State<AddGroupScreen> createState() => _AddGroupScreenState();
}

class _AddGroupScreenState extends State<AddGroupScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  String? _selectedGroupType;
  String? _groupImagePath;

  final List<String> _groupTypes = ['Trip', 'Friends', 'Home', 'Other'];
  List<Map<String, dynamic>> _friends = [];
  Set<String> _selectedFriendUIDs = {};
  bool _isLoading = true;
  bool _showGroupDetails = false;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final List<dynamic> friendsUIDs = userDoc.data()?['friends'] ?? [];

    List<Map<String, dynamic>> fetchedFriends = [];
    for (String uid in friendsUIDs) {
      final friendDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = friendDoc.data();
      if (data != null) {
        fetchedFriends.add({
          'uid': uid,
          'name': data['name'] ?? 'Unnamed',
          'email': data['email'] ?? '',
        });
      }
    }

    setState(() {
      _friends = fetchedFriends;
      _isLoading = false;
    });
  }

  void _goToGroupDetails() {
    if (_selectedFriendUIDs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one friend')),
      );
      return;
    }
    setState(() {
      _showGroupDetails = true;
    });
  }

  Future<void> _submitGroup() async {
    final name = _groupNameController.text.trim();
    if (name.isEmpty || _selectedGroupType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields')),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user!.getIdToken();

      final members = [..._selectedFriendUIDs, user.uid];

      final response = await http.post(
        Uri.parse('http://192.168.1.5:3000/groups/add'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'name': name,
          'type': _selectedGroupType!.toLowerCase(),
          'photoUrl': '', // add image support later
          'members': members,
          'createdBy': user.uid,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group created successfully')),
        );
        Navigator.pop(context);
      } else {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${error["message"]}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Group"),
        backgroundColor: Colors.teal[800],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_showGroupDetails
              ? _buildFriendSelectionView()
              : _buildGroupDetailsView(),
    );
  }

  Widget _buildFriendSelectionView() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text("Select Friends to Add to Group",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ..._friends.map((friend) {
          return CheckboxListTile(
            title: Text(friend['name']),
            subtitle: Text(friend['email']),
            value: _selectedFriendUIDs.contains(friend['uid']),
            onChanged: (bool? selected) {
              setState(() {
                if (selected == true) {
                  _selectedFriendUIDs.add(friend['uid']);
                } else {
                  _selectedFriendUIDs.remove(friend['uid']);
                }
              });
            },
          );
        }).toList(),
        const SizedBox(height: 20),
        Center(
          child: ElevatedButton.icon(
            onPressed: _goToGroupDetails,
            icon: const Icon(Icons.arrow_forward),
            label: const Text("Next"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupDetailsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Image picker not implemented')),
              );
            },
            child: CircleAvatar(
              radius: 45,
              backgroundColor: Colors.teal[100],
              backgroundImage: _groupImagePath != null
                  ? AssetImage(_groupImagePath!)
                  : null,
              child: _groupImagePath == null
                  ? const Icon(Icons.camera_alt, size: 32)
                  : null,
            ),
          ),
          const SizedBox(height: 20),
          const Align(
              alignment: Alignment.centerLeft,
              child: Text("Group Name",
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold))),
          const SizedBox(height: 8),
          TextField(
            controller: _groupNameController,
            decoration: InputDecoration(
              hintText: "Enter group name",
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 20),
          const Align(
              alignment: Alignment.centerLeft,
              child: Text("Group Type",
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold))),
          const SizedBox(height: 8),
          Column(
            children: _groupTypes.map((type) {
              return RadioListTile<String>(
                title: Text(type),
                value: type,
                groupValue: _selectedGroupType,
                onChanged: (value) {
                  setState(() {
                    _selectedGroupType = value;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 30),
          Center(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _submitGroup,
              icon: const Icon(Icons.done),
              label: const Text("Create Group", style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
