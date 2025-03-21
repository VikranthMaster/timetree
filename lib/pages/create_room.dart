import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:timetree1/pages/chat.dart';
import 'package:timetree1/pages/user_list.dart';

class CreateRoom extends StatefulWidget {
  final int roomCode1;
  const CreateRoom({super.key, required this.roomCode1});

  @override
  State<CreateRoom> createState() => _CreateRoomState();
}

class _CreateRoomState extends State<CreateRoom> with WidgetsBindingObserver {
  final CountDownController _controller = CountDownController();
  final TextEditingController _mins = TextEditingController();
  final TextEditingController _sec = TextEditingController();

  int _duration = 0;
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

  Future<void> removeRoom(int code) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection("rooms")
        .where('roomCode', isEqualTo: code)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> setActive(int code, bool status) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection("rooms")
        .where("roomCode", isEqualTo: code)
        .get();

    if (snapshot.docs.isNotEmpty) {
      for (var doc in snapshot.docs) {
        await doc.reference.update({
          'isActive': status,
          'startTime': FieldValue.serverTimestamp(),
          'duration': _duration,
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          if (!_isTimerRunning) {
            await removeRoom(widget.roomCode1);
            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Can't leave while timer is running"),
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
                await removeRoom(widget.roomCode1);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Can't leave while timer is running"),
                  ),
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
                        UserList(code3: widget.roomCode1.toString()),
                  ),
                );
              },
              icon: const Icon(Icons.person),
              padding: const EdgeInsets.all(15),
            ),
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        ChatScreen(roomCode: (widget.roomCode1).toString()),
                  ),
                );
              },
              icon: const Icon(Icons.chat),
              tooltip: 'Open chat',
            )
          ],
        ),
        body: Column(
          children: [
            const SizedBox(height: 5),
            Center(
              child: Text(
                "Room Code: ${widget.roomCode1}",
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto',
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_duration > 0)
              CircularCountDownTimer(
                duration: _duration,
                controller: _controller,
                width: MediaQuery.of(context).size.width / 2,
                height: MediaQuery.of(context).size.height / 2.5,
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
                onStart: () {
                  setState(() {
                    _isTimerRunning = true;
                  });
                },
                onComplete: () {
                  setState(() {
                    _isTimerRunning = false;
                  });
                  setActive(widget.roomCode1, false);
                },
                timeFormatterFunction: (defaultFormatterFunction, duration) {
                  String minutes =
                      duration.inMinutes.toString().padLeft(2, '0');
                  String seconds =
                      (duration.inSeconds % 60).toString().padLeft(2, '0');
                  return "$minutes:$seconds";
                },
              ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Enter Time"),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: _mins,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(hintText: "Enter Minutes"),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _sec,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(hintText: "Enter Seconds"),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          int minutes = int.tryParse(_mins.text) ?? 0;
                          int seconds = int.tryParse(_sec.text) ?? 0;
                          setState(() {
                            _duration = (minutes * 60) + seconds;
                          });
                          Navigator.pop(context);
                        },
                        child: const Text("Set"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                    ],
                  ),
                );
              },
              child: const Text("SET TIMER"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                if (_duration > 0) {
                  _controller.start();
                  setActive(widget.roomCode1, true);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Please set a valid time first.")),
                  );
                }
              },
              child: const Text("START"),
            ),
          ],
        ),
      ),
    );
  }
}
