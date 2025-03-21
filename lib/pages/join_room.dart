import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:timetree1/pages/chat.dart';
import 'package:timetree1/pages/user_list.dart';

class JoinRoom extends StatefulWidget {
  final int roomCode2;
  const JoinRoom({super.key, required this.roomCode2});

  @override
  State<JoinRoom> createState() => _JoinRoomState();
}

class _JoinRoomState extends State<JoinRoom> with WidgetsBindingObserver {
  final CountDownController _controller = CountDownController();
  int syncedDuration = 0;
  bool timerStarted = false;
  bool _isTimerRunning = false;
  bool _wasPausedManually = false;
  bool _isFirstResume = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && _isTimerRunning) {
      _wasPausedManually = true;
    } else if (state == AppLifecycleState.resumed) {
      if (!_isFirstResume && _wasPausedManually && _isTimerRunning) {
        // Only show this if the app was paused, not freshly started
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("You returned to the app while the timer is running"),
          ),
        );
      }
      _wasPausedManually = false;
      _isFirstResume = false; // now treat future resumes as true resumes
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          if (!_isTimerRunning) {
            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Can't leave while the Timer is running"),
              ),
            );
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Room'),
          centerTitle: true,
          leading: IconButton(
            onPressed: () async {
              if (!_isTimerRunning) {
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Can't leave while timer is running")),
                );
              }
            },
            icon: const Icon(Icons.arrow_back),
          ),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        UserList(code3: (widget.roomCode2).toString()),
                  ),
                );
              },
              icon: const Icon(Icons.person),
              padding: const EdgeInsets.all(15),
            ),
            IconButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) =>
                        ChatScreen(roomCode: (widget.roomCode2).toString())));
              },
              icon: const Icon(Icons.chat),
              tooltip: 'Open chat',
            )
          ],
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("rooms")
              .where("roomCode", isEqualTo: widget.roomCode2)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            var roomData =
                snapshot.data!.docs.first.data() as Map<String, dynamic>;
            bool isActive = roomData['isActive'] ?? false;
            int duration = roomData['duration'] ?? 0;
            Timestamp? startTimeStamp = roomData['startTime'];

            if (isActive && startTimeStamp != null && duration > 0) {
              DateTime startTime = startTimeStamp.toDate();
              int elapsed = DateTime.now().difference(startTime).inSeconds;
              int timeLeft = duration - elapsed;

              if (timeLeft < 0) timeLeft = 0;

              if (!timerStarted || syncedDuration != timeLeft) {
                Future.delayed(Duration.zero, () {
                  setState(() {
                    syncedDuration = timeLeft;
                    timerStarted = true;
                    _isTimerRunning = true;
                  });
                  _controller.restart(duration: timeLeft);
                });
              }
            }

            return Column(
              children: [
                const SizedBox(height: 5),
                Center(
                  child: Text(
                    "Room Code: ${widget.roomCode2}",
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: CircularCountDownTimer(
                    duration: duration,
                    controller: _controller,
                    width: MediaQuery.of(context).size.width / 2,
                    height: MediaQuery.of(context).size.height / 2,
                    ringColor: Colors.grey[300]!,
                    fillColor: Colors.green[600]!,
                    strokeWidth: 20.0,
                    strokeCap: StrokeCap.round,
                    textStyle: const TextStyle(
                      fontSize: 33.0,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textFormat: CountdownTextFormat.MM_SS,
                    isReverse: true,
                    isTimerTextShown: true,
                    autoStart: false,
                    onComplete: () {
                      setState(() {
                        timerStarted = false;
                        _isTimerRunning = false;
                      });
                    },
                    timeFormatterFunction:
                        (defaultFormatterFunction, duration) {
                      String minutes =
                          duration.inMinutes.toString().padLeft(2, '0');
                      String seconds =
                          (duration.inSeconds % 60).toString().padLeft(2, '0');
                      return "$minutes:$seconds";
                    },
                  ),
                ),
                if (!isActive)
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Text("Waiting for timer to start..."),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
