import 'package:flutter/material.dart';

class Monitor extends StatelessWidget {
  const Monitor({super.key});

  @override
  Widget build(BuildContext context) {
    Title(
      color: Colors.black,
      child: const Text(
        "monitor page",
        style: TextStyle(color: Colors.black),
      ),
    );
    return const Placeholder();
  }
}
