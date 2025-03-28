import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ForumPage extends StatefulWidget {
  const ForumPage({Key? key}) : super(key: key);

  @override
  _ForumPageState createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  bool _isUploading = false;
  String? _errorMessage;

  Future<void> _sendMessage({String? imageUrl}) async {
    // Reset error message
    setState(() {
      _errorMessage = null;
    });

    // Trim and check if message is empty or no image
    String messageText = _messageController.text.trim();
    if (messageText.isEmpty && imageUrl == null) return;

    // Get current user details
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please log in to send messages')));
      return;
    }

    try {
      // Fetch user document with more robust error handling
      DocumentSnapshot? userDoc;
      try {
        userDoc =
            await _firestore.collection('users').doc(currentUser.uid).get();
      } catch (e) {
        print('Error fetching user document: $e');
        userDoc = null;
      }

      // Get user data with comprehensive fallback
      Map<String, dynamic> userData =
          userDoc?.data() as Map<String, dynamic>? ?? {};

      // Use email as fallback if name is not available
      String userName =
          userData['name'] ?? userData['email'] ?? 'Anonymous User';

      // Safely get user type with multiple fallbacks
      String userType = _getUserType(userData, currentUser);

      // Prepare message data
      await _firestore.collection('forum_messages').add({
        'text': messageText,
        'imageUrl': imageUrl,
        'senderId': currentUser.uid,
        'senderName': userName,
        'senderType': userType, // Always include this field
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Clear text field
      _messageController.clear();
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Improved method to safely determine user type
  String _getUserType(Map<String, dynamic> userData, User user) {
    // Check multiple possible fields for user type
    if (userData.containsKey('userType')) return userData['userType'];
    if (userData.containsKey('role')) return userData['role'];

    // Check email domain as a fallback
    String email = user.email ?? '';
    if (email.contains('@student.')) return 'Student';
    if (email.contains('@alumni.')) return 'Alumni';

    // Ultimate fallback
    return 'User';
  }

  Future<void> _pickImage() async {
    setState(() {
      _isUploading = true;
    });

    try {
      // Pick an image from gallery
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        // Upload image to Firebase Storage
        File imageFile = File(pickedFile.path);
        String fileName =
            'forum_images/${DateTime.now().millisecondsSinceEpoch}.png';

        // Upload to Firebase Storage
        UploadTask uploadTask = _storage.ref(fileName).putFile(imageFile);
        TaskSnapshot taskSnapshot = await uploadTask;

        // Get download URL
        String imageUrl = await taskSnapshot.ref.getDownloadURL();

        // Send message with image
        await _sendMessage(imageUrl: imageUrl);
      }
    } catch (e) {
      print('Image upload error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload image'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                placeholder:
                    (context, url) =>
                        Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => Icon(Icons.error),
                fit: BoxFit.contain,
              ),
            ),
          ),
    );
  }

  void _showAchievementsDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Achievements'),
            content: StreamBuilder<QuerySnapshot>(
              stream:
                  _firestore
                      .collection('user_achievements')
                      .where('userId', isEqualTo: _auth.currentUser?.uid)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Text('No achievements yet.');
                }

                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children:
                        snapshot.data!.docs.map((achievement) {
                          // Safely extract data with null checks
                          Map<String, dynamic> data =
                              achievement.data() as Map<String, dynamic>;

                          return ListTile(
                            leading: Icon(Icons.stars, color: Colors.amber),
                            title: Text(data['title'] ?? 'Unnamed Achievement'),
                            subtitle: Text(
                              data['description'] ?? 'No description',
                            ),
                          );
                        }).toList(),
                  ),
                );
              },
            ),
          ),
    );
  }

  Widget _buildMessageBubble(QueryDocumentSnapshot message) {
    // Determine if the message is from the current user
    bool isCurrentUser = message['senderId'] == _auth.currentUser?.uid;

    // Add null checks for message fields
    String senderName = message['senderName'] ?? 'Unknown Sender';
    String senderType = message['senderType'] ?? 'User';
    String messageText = message['text'] ?? '';

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
                  '$senderName ($senderType)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                // Message Text
                if (messageText.isNotEmpty)
                  Text(messageText, style: TextStyle(fontSize: 16)),

                // Image Display
                if (message['imageUrl'] != null)
                  Container(
                    margin: EdgeInsets.only(top: 8),
                    child: GestureDetector(
                      onTap: () => _showImageDialog(message['imageUrl']),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: message['imageUrl'],
                          placeholder:
                              (context, url) =>
                                  Center(child: CircularProgressIndicator()),
                          errorWidget:
                              (context, url, error) => Icon(Icons.error),
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),

                // Timestamp
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

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(8),
      color: Colors.white,
      child: Row(
        children: [
          // Image Upload Button
          IconButton(
            icon:
                _isUploading
                    ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(),
                    )
                    : Icon(Icons.image, color: Colors.blue),
            onPressed: _isUploading ? null : _pickImage,
          ),

          // Text Input
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
              onSubmitted: (_) => _sendMessage(),
            ),
          ),

          // Send Button
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Community Forum'),
        actions: [
          IconButton(
            icon: Icon(Icons.stars),
            onPressed: _showAchievementsDialog,
          ),
        ],
      ),
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

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    DateTime dateTime = timestamp.toDate();
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }
}
