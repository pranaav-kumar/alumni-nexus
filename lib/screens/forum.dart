import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class ForumPage extends StatefulWidget {
  const ForumPage({super.key});

  @override
  _ForumPageState createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FocusNode _messageFocusNode = FocusNode();

  Future<void> _sendMessage() async {
    // Trim and check if message is empty
    String messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    // Get current user details
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please log in to send messages')));
      return;
    }

    try {
      // Print debug information
      print('Current User UID: ${currentUser.uid}');
      print('Attempting to fetch user document');

      // Fetch user document to get name and user type
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get()
          .timeout(
            Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('User document fetch timed out');
            },
          );

      // Check if user document exists
      if (!userDoc.exists) {
        throw Exception('User document not found');
      }

      // Get user data with fallback
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      // Use email as fallback if name is not available
      String userName =
          userData['name'] ?? userData['email'] ?? 'Anonymous User';
      String userType = userData['userType'] ?? 'User';

      // Print user document data for debugging
      print('User Document Data: $userData');

      // Prepare message data
      await _firestore.collection('forum_messages').add({
        'text': messageText,
        'senderId': currentUser.uid,
        'senderName': userName,
        'senderType': userType,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Clear text field and refocus
      _messageController.clear();
      _messageFocusNode.requestFocus();

      print('Message sent successfully');
    } catch (e) {
      // More detailed error handling
      print('Error sending message: $e');

      String errorMessage = 'Failed to send message. ';
      if (e is FirebaseException) {
        errorMessage += 'Firebase Error: ${e.message}';
      } else if (e is TimeoutException) {
        errorMessage += 'Connection timed out. Please check your internet.';
      } else {
        errorMessage += 'An unexpected error occurred.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Community Forum'), centerTitle: true),
      body: Column(
        children: [
          // Messages Stream
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  _firestore
                      .collection('forum_messages')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet. Start the conversation!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var message = snapshot.data!.docs[index];
                    return _buildMessageBubble(message);
                  },
                );
              },
            ),
          ),

          // Message Input Area
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(QueryDocumentSnapshot message) {
    // Determine if the message is from the current user
    bool isCurrentUser = message['senderId'] == _auth.currentUser?.uid;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCurrentUser ? Colors.blue[100] : Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sender Name and Type
                Text(
                  '${message['senderName']} (${message['senderType']})',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                // Message Text
                Text(message['text'], style: TextStyle(fontSize: 16)),
                // Optional: Add timestamp
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    _formatTimestamp(message['timestamp']),
                    style: TextStyle(fontSize: 10, color: Colors.black54),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    DateTime dateTime = timestamp.toDate();
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(8),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _messageFocusNode,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _sendMessage(), // Allow sending on enter
            ),
          ),
          SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.blue,
            child: IconButton(
              icon: Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }
}
