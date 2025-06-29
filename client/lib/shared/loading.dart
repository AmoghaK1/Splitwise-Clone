import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class Loading extends StatelessWidget {
  const Loading({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.lightGreen.shade100,
      child: Center(
        child: SpinKitWave(
          color: Colors.teal,
          size:60.0,
        ),
      ),
    );
  }
}