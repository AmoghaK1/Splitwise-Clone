import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/AppUser.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Convert Firebase user to custom AppUser
  AppUser? _userFromFirebaseUser(User? user) {
    if (user == null) return null;

    return AppUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? 'New User',
      photoURL: user.photoURL,
    );
  }

  // Stream to track auth state changes
  Stream<AppUser?> get user {
    return _auth.authStateChanges().map(_userFromFirebaseUser);
  }

// Sign in with email and password
  Future<AppUser?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _userFromFirebaseUser(result.user);
    } catch (e) {
      print('Error in signInWithEmailAndPassword: $e');
      return null;
    }
  }

  // Register with email and password
  Future<AppUser?> registerWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        // Optionally update display name
        await user.reload(); // Refresh user data
        user = _auth.currentUser;
        return _userFromFirebaseUser(user);
      }

      return null;
    } catch (e) {
      print('Error in registerWithEmailAndPassword: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  //store additional info about user while registering
  Future<void> storeAdditionalUserInfo({
    required String uid,
    required String firstName,
    required String lastName,
    required String phone,
    required String age,
    required String email,
  }) async {
    // Example: Save to Firestore
    final userCollection = FirebaseFirestore.instance.collection('users');
    await userCollection.doc(uid).set({
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'age': age,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

}
