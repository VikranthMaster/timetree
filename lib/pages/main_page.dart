import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timetree1/main.dart';
import 'package:timetree1/pages/join_room.dart';
import 'dart:math';
import 'create_room.dart';
import 'package:lottie/lottie.dart';

class Main_Page extends StatefulWidget {
  const Main_Page({super.key});

  @override
  State<Main_Page> createState() => _Main_PageState();
}

class _Main_PageState extends State<Main_Page> {
  final _roomCode = TextEditingController();
  late String _username = "";

  @override
  void initState() {
    super.initState();
    loadUsername();
  }

  @override
  void dispose() {
    _roomCode.dispose();
    super.dispose();
  }

  void loadUsername() async {
    String? username = await getUsername();
    if (username != null) {
      setState(() {
        _username = username;
      });
    }
  }

  Future<String?> getUsername() async {
    final user = await FirebaseFirestore.instance
        .collection("users")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();
    if (user.exists) {
      return user.data()?['username'];
    } else {
      print("Error: No such user.");
      return null;
    }
  }

  Future addRoom(int roomId) async {
    await FirebaseFirestore.instance.collection("rooms").add({
      'roomCode': roomId,
      'startTime': FieldValue.serverTimestamp(),
      'isActive': false,
      'duration': null,
      'users': [],
    });
  }

  Future appendUserByCode(int roomCode) async {
    final user = await FirebaseFirestore.instance
        .collection("users")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();
    String username = user.data()?['username'];
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection("rooms")
        .where("roomCode", isEqualTo: roomCode)
        .get();
    for (var doc in snapshot.docs) {
      await doc.reference.update({
        'users': FieldValue.arrayUnion([username]),
      });
    }
  }

  int generateDigit() {
    final random = Random();
    return 1000 + random.nextInt(9000);
  }

  Future<bool> getRoomByCode(int code) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection("rooms")
        .where('roomCode', isEqualTo: code)
        .where('isActive', isEqualTo: false)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Transform.translate(
            offset: const Offset(0, -60),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 100),
                Text(
                  "Hello, $_username!",
                  style: GoogleFonts.poppins(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF4A5568),
                  ),
                ),
                const SizedBox(height: 90),
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
                      await addRoom(roomId);
                      await appendUserByCode(roomId);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CreateRoom(roomCode1: roomId),
                        ),
                      );
                    } catch (e) {
                      print("Error creating room: $e");
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
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(hintText: "Room ID"),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () async {
                              if (_roomCode.text.isEmpty) return;

                              final code = int.tryParse(_roomCode.text);
                              if (code == null) return;

                              Navigator.pop(context);

                              bool exists = await getRoomByCode(code);
                              if (exists) {
                                await appendUserByCode(code);
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => JoinRoom(roomCode2: code),
                                  ),
                                );
                              } else {
                                showDialog(
                                  context: context,
                                  builder: (_) => const AlertDialog(
                                    title: Text("Invalid Room ID"),
                                    content:
                                        Text("Please enter a valid room ID."),
                                  ),
                                );
                              }
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
          ),
          Positioned(
            top: 123,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const Main()),
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
