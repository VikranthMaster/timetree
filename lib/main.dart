import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timetree1/pages/join_room.dart';
import 'dart:math';
import 'firebase_options.dart';
import 'pages/create_room.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TimeTree',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          surface: const Color(0xFFD4E6C3),
        ),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _roomCode = TextEditingController();

  Future addRoom(int roomId) async {
    await FirebaseFirestore.instance.collection("rooms").add({
      'roomCode': roomId,
      'startTime': FieldValue.serverTimestamp(),
      'isActive': false,
      'duration': null,
    });
  }

  void dispose() {
    _roomCode.dispose();
    super.dispose();
  }

  int generateDigit() {
    final random = Random();
    return 1000 + random.nextInt(9000);
  }

  //document IDs
  List<String> docIds = [];

  //get docIDs
  Future getDocId() async {
    await FirebaseFirestore.instance.collection("rooms").get().then(
          (snapshot) => snapshot.docs.forEach((element) {
            print(element.reference);
            docIds.add(element.reference.id);
          }),
        );
  }

  Future getRoomByCode(int code) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection("rooms")
        .where('roomCode', isEqualTo: code)
        .where('isActive', isEqualTo: false)
        .get();
    if (snapshot.docs.isNotEmpty) {
      return 1;
    } else {
      return 0;
    }
  }

  @override
  void initState() {
    getDocId();
    super.initState();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 250),
          Center(
            child: Lottie.asset(
              'lotties/plant.json',
              width: 300,
              height: 300,
            ),
          ),
          Center(
            child: Text(
              'TimeTree',
              style: GoogleFonts.poppins(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF4A5568),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              final roomId = generateDigit();
              try {
                addRoom(roomId);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CreateRoom(
                      roomCode1: roomId,
                    ),
                  ),
                );
              } catch (e) {
                print("Error");
              }
            },
            child: const Text("CREATE ROOM"),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Enter Room ID"),
                  content: TextField(
                    controller: _roomCode,
                    decoration: const InputDecoration(hintText: "Room ID"),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        final code = int.parse(_roomCode.text);
                        getRoomByCode(code).then((value) {
                          if (value == 1) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => JoinRoom(
                                  roomCode2: code,
                                ),
                              ),
                            );
                          } else {
                            showDialog(
                              context: context,
                              builder: (_) => const AlertDialog(
                                title: Text("Invalid Room ID"),
                                content: Text("Please enter a valid room ID."),
                              ),
                            );
                          }
                        });
                        Navigator.pop(context);
                      },
                      child: const Text("JOIN"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("CANCEL"),
                    ),
                  ],
                ),
              );
            },
            child: const Text("JOIN ROOM"),
          ),
        ],
      ),
    );
  }
}
