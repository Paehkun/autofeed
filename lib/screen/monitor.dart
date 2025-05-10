import 'package:flutter/material.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class Monitor extends StatefulWidget {
  const Monitor({super.key});

  @override
  State<Monitor> createState() => _MonitorState();
}

class _MonitorState extends State<Monitor> {
  List<String> feedingLog = [];

  @override
  void initState() {
    super.initState();

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String todayDate = DateTime.now().toString().split(' ')[0];
      // Reference to feeding log
      DatabaseReference feedRef = FirebaseDatabase.instance
          .ref('users/${user.uid}/feedingLog/success/$todayDate');

      // Listen for feeding log updates
      feedRef.onValue.listen((event) {
        final data = event.snapshot.value;
        if (data is List) {
          // Clean out nulls if any
          List<String> times = data.whereType<String>().toList();
          setState(() {
            feedingLog = times;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: const Text(
              "Monitor",
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.normal,
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
                    //stream: 'http://192.168.0.25/stream', //rumah sewa
                    stream: 'http://192.168.1.8/stream', //rumah
                    //stream: 'http://192.168.119.21/stream', //hotspot
                    isLive: true,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 20.0),
                Container(
                  height: 200,
                  width: 350,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 10,
                        blurRadius: 10,
                        offset: const Offset(3, 5),
                      ),
                    ],
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.0),
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
                      const SizedBox(height: 5),
                      Expanded(
                        child: feedingLog.isEmpty
                            ? const Center(
                                child: Text("No feeding data currently"))
                            : ListView.builder(
                                itemCount: feedingLog.length,
                                itemBuilder: (context, index) {
                                  return ListTile(
                                    leading: const Icon(Icons.timer),
                                    title: Text(
                                        "Success Feeding At: ${feedingLog[index]}"),
                                  );
                                },
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
