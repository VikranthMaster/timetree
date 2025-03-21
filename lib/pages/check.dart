import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:timetree1/main.dart';
import 'package:timetree1/pages/join_room.dart';
import 'package:timetree1/pages/login_page.dart';
import 'package:timetree1/pages/main_page.dart';

class CheckPage extends StatelessWidget {
  const CheckPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator(); // or splash screen
          }
          if (snapshot.hasData) {
            return Main_Page(); // logged in
          } else {
            return Main(); // not logged in
          }
        },
      ),
    );
  }
}
