import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class Register extends StatefulWidget {
  final VoidCallback toggleView;
  const Register({super.key, required this.toggleView});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _auth = AuthService();

  // form fields
  String firstName = '';
  String lastName = '';
  String email = '';
  String phone = '';
  String age = '';
  String password = '';
  String confirmPassword = '';
  String error = '';
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.teal[800],
        elevation: 0.0,
        title: const Text('Register on SplitEase'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.login, color: Colors.white),
            label: const Text('Sign In', style: TextStyle(color: Colors.white)),
            onPressed: widget.toggleView,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'First Name'),
                validator: (val) => val!.isEmpty ? 'Enter your first name' : null,
                onChanged: (val) => setState(() => firstName = val),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Last Name'),
                validator: (val) => val!.isEmpty ? 'Enter your last name' : null,
                onChanged: (val) => setState(() => lastName = val),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (val) => val!.isEmpty ? 'Enter an email' : null,
                onChanged: (val) => setState(() => email = val),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
                validator: (val) => val!.length < 10 ? 'Enter valid phone number' : null,
                onChanged: (val) => setState(() => phone = val),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
                validator: (val) => val!.isEmpty ? 'Enter your age' : null,
                onChanged: (val) => setState(() => age = val),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (val) => val!.length < 6 ? 'Password too short' : null,
                onChanged: (val) => setState(() => password = val),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Confirm Password'),
                obscureText: true,
                validator: (val) => val != password ? 'Passwords do not match' : null,
                onChanged: (val) => setState(() => confirmPassword = val),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() => loading = true);

                    // Create account with Firebase Auth
                    final result = await _auth.registerWithEmailAndPassword(email, password);

                    if (result == null) {
                      setState(() {
                        error = 'Registration failed';
                        loading = false;
                      });
                    } else {
                      // Save additional user info to Firestore or MongoDB
                      await _auth.storeAdditionalUserInfo(
                        uid: result.uid,
                        firstName: firstName,
                        lastName: lastName,
                        phone: phone,
                        age: age,
                        email: email,
                      );
                    }
                  }
                },
                child: const Text('Register'),
              ),
              const SizedBox(height: 12),
              Text(error, style: const TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ),
    );
  }
}
