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

  String email = '';
  String password = '';
  String displayName = '';
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
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Display Name'),
                validator: (val) => val!.isEmpty ? 'Enter a name' : null,
                onChanged: (val) => setState(() => displayName = val),
              ),
              const SizedBox(height: 20),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (val) => val!.isEmpty ? 'Enter an email' : null,
                onChanged: (val) => setState(() => email = val),
              ),
              const SizedBox(height: 20),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (val) => val!.length < 6 ? 'Password too short' : null,
                onChanged: (val) => setState(() => password = val),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() => loading = true);
                    var result = await _auth.registerWithEmailAndPassword(
                      email, password, displayName,
                    );
                    if (result == null) {
                      setState(() {
                        error = 'Registration failed';
                        loading = false;
                      });
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
