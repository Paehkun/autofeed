import 'package:flutter/material.dart';

class FeedTimerPage extends StatelessWidget {
  const FeedTimerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(title: const Text('Timer')),
      body: const Center(child: Text('Timer Screen')),
    );
  }
}
