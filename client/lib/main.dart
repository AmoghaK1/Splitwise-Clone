import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'models/AppUser.dart';
import 'services/auth_service.dart';
import 'shared/loading.dart';
import 'screens/wrapper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SplitwiseCloneApp());
}

class SplitwiseCloneApp extends StatelessWidget {
  const SplitwiseCloneApp({super.key});

  Future<FirebaseApp> _initializeFirebase() async {
    return await Firebase.initializeApp();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FirebaseApp>(
      future: _initializeFirebase(),
      builder: (context, snapshot) {
        // Show loading while Firebase initializes
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: Scaffold(
              body: Loading(),
            ),
          );
        }

        // Handle errors
        if (snapshot.hasError) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(child: Text('Error initializing Firebase')),
            ),
          );
        }

        // Firebase is initialized
        return StreamProvider<AppUser?>.value(
          value: AuthService().user,
          initialData: null,
          child: const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Wrapper(),
          ),
        );
      },
    );
  }
}
