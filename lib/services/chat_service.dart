import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // PRIVATE: chat id builder
  String _chatId(String uid1, String uid2) {
    final ids = [uid1, uid2]..sort();
    return ids.join('_');
  }

  // ---------------- CREATE / GET CHAT ----------------
  Future<String> getOrCreateChat({
    required String ownerId,
    required String helperId,
    String? requestId,
  }) async {
    final chatId = _chatId(ownerId, helperId);
    final ref = _db.collection('chats').doc(chatId);

    final snap = await ref.get();

    if (!snap.exists) {
      await ref.set({
        'participants': [ownerId, helperId],
        'lastMessage': '',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unreadCount': {ownerId: 0, helperId: 0},
        'createdAt': FieldValue.serverTimestamp(),
        if (requestId != null) 'requestIds': [requestId],
      });
    } else if (requestId != null) {
      await ref.update({
        'requestIds': FieldValue.arrayUnion([requestId]),
      });
    }

    return chatId;
  }

  // ---------------- SEND MESSAGE ----------------
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
  }) async {
    if (text.trim().isEmpty) return;

    final chatRef = _db.collection('chats').doc(chatId);

    await chatRef.collection('messages').add({
      'senderId': senderId,
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    final snap = await chatRef.get();
    final data = snap.data()!;
    final participants = List<String>.from(data['participants']);
    final unread = Map<String, dynamic>.from(data['unreadCount']);

    for (final uid in participants) {
      if (uid != senderId) {
        unread[uid] = (unread[uid] ?? 0) + 1;
      }
    }

    await chatRef.update({
      'lastMessage': text.trim(),
      'lastMessageAt': FieldValue.serverTimestamp(),
      'unreadCount': unread,
    });
  }

  // ---------------- MESSAGE STREAM ----------------
  Stream<QuerySnapshot> messagesStream(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots();
  }

  // ---------------- MARK READ ----------------
  Future<void> markChatRead(String chatId, String uid) async {
    await _db.collection('chats').doc(chatId).update({'unreadCount.$uid': 0});
  }

  // ---------------- CHAT LIST ----------------
  Stream<QuerySnapshot> chatListStream(String uid) {
    return _db
        .collection('chats')
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots();
  }
}
