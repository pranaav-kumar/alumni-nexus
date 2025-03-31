import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';

class MentorConnectPage extends StatefulWidget {
  const MentorConnectPage({super.key});

  @override
  State<MentorConnectPage> createState() => _MentorConnectPageState();
}

class _MentorConnectPageState extends State<MentorConnectPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> alumniList = [];

  @override
  void initState() {
    super.initState();
    _fetchAlumni();
  }

  Future<void> _fetchAlumni() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get all users with role 'alumni'
      QuerySnapshot alumniSnapshot =
          await _firestore
              .collection('users')
              .where('role', isEqualTo: 'alumni')
              .get();

      List<Map<String, dynamic>> alumniData = [];

      for (var doc in alumniSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Check if there's an existing connection request
        String currentUserId = _auth.currentUser!.uid;
        QuerySnapshot requestSnapshot =
            await _firestore
                .collection('connection_requests')
                .where('student_id', isEqualTo: currentUserId)
                .where('alumni_id', isEqualTo: doc.id)
                .get();

        String status = 'not_connected';
        String requestId = '';

        if (requestSnapshot.docs.isNotEmpty) {
          status = requestSnapshot.docs.first['status'];
          requestId = requestSnapshot.docs.first.id;
        }

        alumniData.add({
          'id': doc.id,
          'name': data['name'] ?? 'Unknown Alumni',
          'expertise': data['expertise'] ?? 'Not specified',
          'industry': data['industry'] ?? 'Not specified',
          'status': status,
          'request_id': requestId,
        });
      }

      setState(() {
        alumniList = alumniData;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching alumni: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading alumni: $e')));
    }
  }

  Future<void> _sendConnectionRequest(String alumniId) async {
    try {
      String currentUserId = _auth.currentUser!.uid;

      // Create connection request
      await _firestore.collection('connection_requests').add({
        'student_id': currentUserId,
        'alumni_id': alumniId,
        'status': 'pending',
        'message': '',
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Refresh the list
      _fetchAlumni();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Connection request sent!')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sending request: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect with Alumni'),
        backgroundColor: Colors.blue[800],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : alumniList.isEmpty
              ? const Center(
                child: Text(
                  'No alumni available at the moment',
                  style: TextStyle(fontSize: 16),
                ),
              )
              : ListView.builder(
                itemCount: alumniList.length,
                itemBuilder: (context, index) {
                  final alumni = alumniList[index];
                  final bool isPending = alumni['status'] == 'pending';
                  final bool isAccepted = alumni['status'] == 'accepted';

                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(alumni['name'][0].toUpperCase()),
                      ),
                      title: Text(alumni['name']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Expertise: ${alumni['expertise']}'),
                          Text('Industry: ${alumni['industry']}'),
                        ],
                      ),
                      trailing:
                          isPending
                              ? const Text(
                                'Request Pending',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                              : isAccepted
                              ? ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => ChatScreen(
                                            otherUserId: alumni['id'],
                                            otherUserName: alumni['name'],
                                            userType: 'student',
                                          ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                child: const Text('Chat'),
                              )
                              : ElevatedButton(
                                onPressed:
                                    () => _sendConnectionRequest(alumni['id']),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                ),
                                child: const Text('Connect'),
                              ),
                    ),
                  );
                },
              ),
    );
  }
}
