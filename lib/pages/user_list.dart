import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserList extends StatefulWidget {
  final String code3;
  const UserList({super.key, required this.code3});

  @override
  State<UserList> createState() => _UserListState();
}

class _UserListState extends State<UserList> {
  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserStream(
      String code) async* {
    // Safely fetch room with matching roomCode (int)
    final query = await FirebaseFirestore.instance
        .collection("rooms")
        .where("roomCode",
            isEqualTo: int.tryParse(code)) // if your code3 is a string
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw Exception("Room with code $code not found.");
    } else {
      yield* query.docs.first.reference.snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Joined Users"),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: getUserStream(widget.code3),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(fontSize: 16, color: Colors.red),
              ),
            );
          }

          final roomData = snapshot.data?.data();
          final users =
              (roomData?['users'] as List<dynamic>? ?? []).cast<String>();

          if (users.isEmpty) {
            return const Center(child: Text("No users have joined yet."));
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  "Total Users: ${users.length}",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(users[index]),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
