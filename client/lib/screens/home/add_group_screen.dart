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
  String? _groupImagePath; // Placeholder for now

  final List<String> _groupTypes = ['Trip', 'Friends', 'Home', 'Other'];

  void _submitGroup() async {
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

      final response = await http.post(
        Uri.parse('http://192.168.1.5:3000/groups/add'), // replace with your local IP for testing
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'name': name,
          'type': _selectedGroupType!.toLowerCase(), // backend expects lowercase
          'photoUrl': '', // add image support later
          'members': [user.uid], // for now only one member
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group image
            Center(
              child: GestureDetector(
                onTap: () {
                  // TODO: Add image picker logic
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Image picker not implemented')),
                  );
                },
                child: CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.teal[100],
                  backgroundImage: _groupImagePath != null ? AssetImage(_groupImagePath!) : null,
                  child: _groupImagePath == null
                      ? const Icon(Icons.camera_alt, size: 32, color: Colors.black54)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Group name
            const Text("Group Name", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _groupNameController,
              decoration: InputDecoration(
                hintText: "Enter group name",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),

            // Group type
            const Text("Group Type", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

            // Done Button
            Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _submitGroup,
                icon: const Icon(Icons.done),
                label: const Text("Done", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
