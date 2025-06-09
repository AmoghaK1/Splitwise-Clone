import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


import 'package:splitwise_clone/screens/home/account_screen.dart';
import 'package:splitwise_clone/screens/home/activity_screen.dart';
import 'package:splitwise_clone/screens/home/add_group_screen.dart';
import 'package:splitwise_clone/screens/home/friends_screen.dart';
import '../../services/auth_service.dart';


class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final AuthService _auth = AuthService();
  int _selectedIndex = 0;

  // Screens
  static final List<Widget> _screens = <Widget>[
    const GroupsScreen(), 
    const FriendsScreen(),
    const ActivityScreen(),
    const AccountScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],

      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              backgroundColor: Colors.teal,
              onPressed: () {
                // TODO: Navigate to add expense screen
              },
              icon: const Icon(Icons.add),
              label: const Text("Add Expense"),
            )
          : null,

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.teal[800],
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.group), label: "Groups"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Friends"),
          BottomNavigationBarItem(icon: Icon(Icons.access_time), label: "Activity"),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: "Account"),
        ],
      ),
    );
  }
}


class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  List<dynamic> _groups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchGroups();
  }

  Future<void> _fetchGroups() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user!.getIdToken();

      final response = await http.get(
        Uri.parse('http://192.168.1.5:3000/groups/my'),
        headers: {
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> groups = jsonDecode(response.body);
        setState(() {
          _groups = groups;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load groups');
      }
    } catch (e) {
      print('Error fetching groups: $e');
      setState(() {
        _groups = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal[800],
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(
              icon: const Icon(Icons.group_add),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddGroupScreen()),
                );
                _fetchGroups(); // Refresh after returning
              }),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Balance',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.teal[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.teal.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: const [
                        Column(
                          children: [
                            Text('You Owe', style: TextStyle(color: Colors.red)),
                            SizedBox(height: 4),
                            Text('₹0', style: TextStyle(fontSize: 16)),
                          ],
                        ),
                        Column(
                          children: [
                            Text('You Are Owed', style: TextStyle(color: Colors.green)),
                            SizedBox(height: 4),
                            Text('₹0', style: TextStyle(fontSize: 16)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Your Groups',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _groups.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("No groups?"),
                                const SizedBox(height: 6),
                                TextButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => const AddGroupScreen()),
                                    ).then((_) => _fetchGroups());
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text("Create one now!"),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _groups.length,
                            itemBuilder: (context, index) {
                              final group = _groups[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: ListTile(
                                  title: Text(group['name']),
                                  subtitle: Text('${group['members'].length} members'),
                                  trailing: const Icon(Icons.arrow_forward_ios),
                                  onTap: () {
                                    // TODO: Navigate to group detail
                                  },
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