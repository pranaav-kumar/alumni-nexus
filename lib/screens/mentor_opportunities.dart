import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';

class MentorOpportunities extends StatefulWidget {
  const MentorOpportunities({super.key});

  @override
  State<MentorOpportunities> createState() => _MentorOpportunitiesState();
}

class _MentorOpportunitiesState extends State<MentorOpportunities> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> connectionRequests = [];
  List<Map<String, dynamic>> connectedStudents = [];

  @override
  void initState() {
    super.initState();
    _fetchConnectionRequests();
    _fetchConnectedStudents();
  }

  Future<void> _fetchConnectionRequests() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String currentUserId = _auth.currentUser!.uid;

      // Get all connection requests where this alumni is the recipient
      QuerySnapshot requestsSnapshot =
          await _firestore
              .collection('connection_requests')
              .where('alumni_id', isEqualTo: currentUserId)
              .get();

      List<Map<String, dynamic>> requestsList = [];

      for (var doc in requestsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Get student details
        DocumentSnapshot studentDoc =
            await _firestore.collection('users').doc(data['student_id']).get();

        Map<String, dynamic> studentData =
            studentDoc.data() as Map<String, dynamic>;

        requestsList.add({
          'request_id': doc.id,
          'student_id': data['student_id'],
          'student_name': studentData['name'] ?? 'Unknown Student',
          'status': data['status'],
          'created_at': data['created_at'],
          'message': data['message'] ?? '',
        });
      }

      setState(() {
        connectionRequests = requestsList;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching connection requests: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading requests: $e')));
    }
  }

  Future<void> _fetchConnectedStudents() async {
    try {
      String currentUserId = _auth.currentUser!.uid;

      // Get all accepted connection requests
      QuerySnapshot requestsSnapshot =
          await _firestore
              .collection('connection_requests')
              .where('alumni_id', isEqualTo: currentUserId)
              .where('status', isEqualTo: 'accepted')
              .get();

      List<Map<String, dynamic>> studentsList = [];

      for (var doc in requestsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Get student details
        DocumentSnapshot studentDoc =
            await _firestore.collection('users').doc(data['student_id']).get();

        Map<String, dynamic> studentData =
            studentDoc.data() as Map<String, dynamic>;

        // Get last message if exists
        String chatId = _getChatId(currentUserId, data['student_id']);
        DocumentSnapshot chatDoc =
            await _firestore.collection('chats').doc(chatId).get();

        Map<String, dynamic>? chatData =
            chatDoc.data() as Map<String, dynamic>?;

        studentsList.add({
          'student_id': data['student_id'],
          'student_name': studentData['name'] ?? 'Unknown Student',
          'last_message': chatData?['last_message'] ?? 'No messages yet',
          'last_message_time': chatData?['last_message_time'],
        });
      }

      setState(() {
        connectedStudents = studentsList;
      });
    } catch (e) {
      print('Error fetching connected students: $e');
    }
  }

  Future<void> _handleRequest(String requestId, String status) async {
    try {
      await _firestore.collection('connection_requests').doc(requestId).update({
        'status': status,
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Refresh both lists
      _fetchConnectionRequests();
      _fetchConnectedStudents();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Request ${status == 'accepted' ? 'accepted' : 'rejected'} successfully',
          ),
          backgroundColor: status == 'accepted' ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating request: $e')));
    }
  }

  String _getChatId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mentor Dashboard'),
          backgroundColor: Colors.blue[800],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Connection Requests'),
              Tab(text: 'Connected Students'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Connection Requests Tab
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : connectionRequests.isEmpty
                ? const Center(
                  child: Text(
                    'No pending connection requests',
                    style: TextStyle(fontSize: 16),
                  ),
                )
                : ListView.builder(
                  itemCount: connectionRequests.length,
                  itemBuilder: (context, index) {
                    final request = connectionRequests[index];
                    final bool isPending = request['status'] == 'pending';

                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  request['student_name'],
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isPending
                                            ? Colors.orange
                                            : request['status'] == 'accepted'
                                            ? Colors.green
                                            : Colors.red,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    request['status'].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (request['message'].isNotEmpty) ...[
                              Text(
                                'Message: ${request['message']}',
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                              const SizedBox(height: 8),
                            ],
                            if (isPending) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed:
                                        () => _handleRequest(
                                          request['request_id'],
                                          'rejected',
                                        ),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                    child: const Text('Reject'),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed:
                                        () => _handleRequest(
                                          request['request_id'],
                                          'accepted',
                                        ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                    ),
                                    child: const Text('Accept'),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),

            // Connected Students Tab
            connectedStudents.isEmpty
                ? const Center(
                  child: Text(
                    'No connected students yet',
                    style: TextStyle(fontSize: 16),
                  ),
                )
                : ListView.builder(
                  itemCount: connectedStudents.length,
                  itemBuilder: (context, index) {
                    final student = connectedStudents[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(student['student_name'][0].toUpperCase()),
                        ),
                        title: Text(student['student_name']),
                        subtitle: Text(
                          student['last_message'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing:
                            student['last_message_time'] != null
                                ? Text(
                                  _formatTimestamp(
                                    student['last_message_time'],
                                  ),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                )
                                : null,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => ChatScreen(
                                    otherUserId: student['student_id'],
                                    otherUserName: student['student_name'],
                                    userType: 'alumni',
                                  ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
          ],
        ),
      ),
    );
  }
}
