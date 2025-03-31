import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';

class StudentConnectionsPage extends StatefulWidget {
  const StudentConnectionsPage({super.key});

  @override
  State<StudentConnectionsPage> createState() => _StudentConnectionsPageState();
}

class _StudentConnectionsPageState extends State<StudentConnectionsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> studentList = [];

  @override
  void initState() {
    super.initState();
    _fetchConnectedStudents();
  }

  Future<void> _fetchConnectedStudents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String currentUserId = _auth.currentUser!.uid;

      // Get all accepted connection requests for this alumni
      QuerySnapshot connectionsSnapshot =
          await _firestore
              .collection('connection_requests')
              .where('alumni_id', isEqualTo: currentUserId)
              .where('status', isEqualTo: 'accepted')
              .get();

      List<Map<String, dynamic>> studentData = [];

      for (var doc in connectionsSnapshot.docs) {
        // Get student details
        DocumentSnapshot studentDoc =
            await _firestore.collection('users').doc(doc['student_id']).get();

        Map<String, dynamic> studentInfo =
            studentDoc.data() as Map<String, dynamic>;

        // Get last message if any
        String chatId = _getChatId(currentUserId, doc['student_id']);
        DocumentSnapshot chatDoc =
            await _firestore.collection('chats').doc(chatId).get();

        String lastMessage = '';
        Timestamp? lastMessageTime;
        if (chatDoc.exists) {
          lastMessage = chatDoc['last_message'] ?? '';
          lastMessageTime = chatDoc['last_message_time'];
        }

        studentData.add({
          'id': doc['student_id'],
          'name': studentInfo['name'] ?? 'Unknown Student',
          'course': studentInfo['course'] ?? 'Not specified',
          'year': studentInfo['year'] ?? 'Not specified',
          'last_message': lastMessage,
          'last_message_time': lastMessageTime,
        });
      }

      setState(() {
        studentList = studentData;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching students: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading students: $e')));
    }
  }

  String _getChatId(String alumniId, String studentId) {
    // Create a consistent chat ID by sorting the IDs
    List<String> ids = [alumniId, studentId]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    DateTime date = timestamp.toDate();
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connected Students'),
        backgroundColor: Colors.blue[800],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : studentList.isEmpty
              ? const Center(
                child: Text(
                  'No connected students yet',
                  style: TextStyle(fontSize: 16),
                ),
              )
              : ListView.builder(
                itemCount: studentList.length,
                itemBuilder: (context, index) {
                  final student = studentList[index];
                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(student['name'][0].toUpperCase()),
                      ),
                      title: Text(student['name']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Course: ${student['course']}'),
                          Text('Year: ${student['year']}'),
                          if (student['last_message'].isNotEmpty)
                            Text(
                              'Last message: ${student['last_message']}',
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (student['last_message_time'] != null)
                            Text(
                              _formatTimestamp(student['last_message_time']),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          const SizedBox(height: 4),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => ChatScreen(
                                        otherUserId: student['id'],
                                        otherUserName: student['name'],
                                        userType: 'alumni',
                                      ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            child: const Text('Chat'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
