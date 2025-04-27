import 'package:flutter/material.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';

class Monitor extends StatelessWidget {
  const Monitor({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: const Text(
              "Monitor Page",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 400,
                  height: 340,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey, width: 4),
                  ),
                  child: const Mjpeg(
                    stream: 'http://192.168.0.25/stream',
                    isLive: true,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 20.0),
                Container(
                  height:
                      200, // Adjusted height to fit schedule and toggle only
                  width: 350,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1), // Shadow color
                        spreadRadius: 10, // Spread of the shadow
                        blurRadius: 10, // How much the shadow is blurred
                        offset:
                            const Offset(3, 5), // Position of the shadow (x, y)
                      ),
                    ],
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 20),
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 20.0), // Add horizontal padding
                        child: Center(
                          child: Text(
                            "Feeding Log",
                            style: TextStyle(
                              fontSize: 15.0,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
