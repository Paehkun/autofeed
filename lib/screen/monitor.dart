import 'package:flutter/material.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class Monitor extends StatefulWidget {
  const Monitor({super.key});

  @override
  State<Monitor> createState() => _MonitorState();
}

class _MonitorState extends State<Monitor> {
  List<String> feedingLog = [];
  String streamUrl = "";

  @override
  void initState() {
    super.initState();

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final uid = user.uid;

      // Load the stream URL from Firebase RTDB
      DatabaseReference streamRef =
          FirebaseDatabase.instance.ref('device/$uid/stream_link');
      streamRef.onValue.listen((event) {
        final url = event.snapshot.value;
        if (url != null) {
          setState(() {
            streamUrl = url.toString();
          });
        }
      });

      // Load the feeding log
      final now = DateTime.now().add(const Duration(hours: 8));
      final todayDate = DateFormat('yyyy-MM-dd').format(now);
      DatabaseReference feedRef = FirebaseDatabase.instance
          .ref('users/$uid/feedingLog/success/$todayDate');

      feedRef.onValue.listen((event) {
        final data = event.snapshot.value;
        if (data is List) {
          List<String> times = data.whereType<String>().toList();
          setState(() {
            feedingLog = times;
          });
        }
      });
    }
  }

  void refreshStream() {
    print("Refresh button pressed");

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final uid = user.uid;

      DatabaseReference streamRef =
          FirebaseDatabase.instance.ref('device/$uid/stream_link');

      streamRef.once().then((event) {
        final url = event.snapshot.value;
        print("Fetched stream URL: $url"); // Debug log
        if (url != null) {
          setState(() {
            streamUrl = url.toString();
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No stream URL found')),
          );
        }
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 25),
            Center(
              child: Text(
                "Monitor",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
            ),
            const SizedBox(height: 25),

            // Camera Stream
            Container(
                width: 400,
                height: 340,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.grey.shade400, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 10,
                      blurRadius: 10,
                      offset: const Offset(3, 5),
                    ),
                  ],
                ),
                child: streamUrl.isEmpty
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 10),
                          const Text("Stream not available"),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            onPressed: refreshStream,
                            icon: const Icon(Icons.refresh),
                            label: const Text("Refresh Stream"),
                          ),
                        ],
                      )
                    : Transform.rotate(
                        angle: 3.1416,
                        child: Mjpeg(
                          stream: streamUrl,
                          isLive: true,
                          fit: BoxFit.cover,
                          error: (context, error, stack) => Center(
                            child: Transform.rotate(
                              angle: 3.1416, // Flip the error UI upright
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.error, color: Colors.red),
                                  const SizedBox(height: 10),
                                  const Text("Stream failed to load"),
                                  ElevatedButton.icon(
                                    onPressed: refreshStream,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text("Retry"),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )),

            const SizedBox(height: 25),

            // Feeding Log Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                height: 210,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 10,
                      blurRadius: 10,
                      offset: const Offset(3, 5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Center(
                        child: Text(
                          "Feeding Log",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: feedingLog.isEmpty
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.history,
                                      size: 40, color: Colors.grey),
                                  SizedBox(height: 10),
                                  Text("No feeding data currently",
                                      style: TextStyle(color: Colors.grey)),
                                ],
                              )
                            : ListView.builder(
                                itemCount: feedingLog.length,
                                itemBuilder: (context, index) {
                                  return Container(
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.timer,
                                            size: 20, color: Colors.blue),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            "Success Feeding At: ${feedingLog[index]}",
                                            style:
                                                const TextStyle(fontSize: 14),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
