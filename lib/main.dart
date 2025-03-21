import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timetree1/pages/join_room.dart';
import 'dart:math';
import 'firebase_options.dart';
import 'pages/create_room.dart';
import 'pages/login_page.dart';
import 'pages/register_room.dart';
import 'pages/check.dart';

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
      home: const CheckPage(),
    );
  }
}

class Main extends StatefulWidget {
  const Main({super.key});

  @override
  State<Main> createState() => _MainState();
}

class _MainState extends State<Main> {
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
      appBar: AppBar(
        title: Text("FIRST PAGE"),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Transform.translate(
        offset: const Offset(0, -135),
        child: Column(
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
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => LoginPage(),
                  ),
                );
              },
              child: const Text("LOGIN"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => RegisterPage(),
                  ),
                );
              },
              child: const Text("REGISTER"),
            ),
          ],
        ),
      ),
    );
  }
}
