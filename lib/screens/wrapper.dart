import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/AppUser.dart';
import '../screens/authenticate/authenticate.dart';
import '../screens/home/home.dart'; 

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AppUser?>(context);

    // If user is not signed in, go to Authenticate screen
    if (user == null) {
      return const Authenticate();
    }

    // If signed in, go to Home screen (can expand to load group data later)
    return const Home();
  }
}
