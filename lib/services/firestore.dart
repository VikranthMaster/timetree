import 'package:cloud_firestore/cloud_firestore.dart';

class RoomService {
  final _firestore = FirebaseFirestore.instance;

  // 🔹 Create a new room (no roomName)
  Future<String> createRoom() async {
    DocumentReference roomRef = await _firestore.collection('rooms').add({
      'isActive': false,
      'startTime': null,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return roomRef.id;
  }

  // 🔹 Add member to a room
  Future<void> addMemberToRoom({
    required String roomId,
    required String userId,
    required String name,
  }) async {
    final memberRef = _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('members')
        .doc(userId);

    await memberRef.set({
      'name': name,
      'joinedAt': FieldValue.serverTimestamp(),
    });
  }

  // 🔹 Start a focus session
  Future<void> startFocusSession(String roomId) async {
    await _firestore.collection('rooms').doc(roomId).update({
      'isActive': true,
      'startTime': FieldValue.serverTimestamp(),
    });
  }

  // 🔹 Stop a focus session
  Future<void> stopFocusSession(String roomId) async {
    await _firestore.collection('rooms').doc(roomId).update({
      'isActive': false,
      'startTime': null,
    });
  }

  // 🔹 Get all members in a room (stream)
  Stream<List<Map<String, dynamic>>> getRoomMembers(String roomId) {
    return _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('members')
        .orderBy('joinedAt')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // 🔹 Listen to room updates
  Stream<DocumentSnapshot> getRoomStream(String roomId) {
    return _firestore.collection('rooms').doc(roomId).snapshots();
  }
}
