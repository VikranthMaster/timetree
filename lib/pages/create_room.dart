import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:circular_countdown_timer/circular_countdown_timer.dart';

class CreateRoom extends StatefulWidget {
  final int roomCode1;
  const CreateRoom({super.key, required this.roomCode1});

  @override
  State<CreateRoom> createState() => _CreateRoomState();
}

class _CreateRoomState extends State<CreateRoom> {
  final CountDownController _controller = CountDownController();
  final TextEditingController _mins = TextEditingController();
  final TextEditingController _sec = TextEditingController();

  int _duration = 0;
  bool _isTimerRunning = false;

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

  Future<bool> _onWillPop() async {
    if (_isTimerRunning) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Can't go back while timer is running")),
      );
      return false;
    } else {
      await removeRoom(widget.roomCode1);
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
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
                      content: Text("Can't leave while timer is running")),
                );
              }
            },
            icon: const Icon(Icons.arrow_back),
          ),
          actions: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.person),
              padding: const EdgeInsets.all(15),
            ),
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
