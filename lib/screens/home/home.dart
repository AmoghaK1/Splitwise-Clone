import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService _auth = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('SplitEase Home'),
        backgroundColor: Colors.teal,
        actions: [
          TextButton.icon(
            onPressed: () async {
              await _auth.signOut();
            },
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Welcome to SplitEase!\nYour friendly expense tracker.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            color: Colors.teal,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
