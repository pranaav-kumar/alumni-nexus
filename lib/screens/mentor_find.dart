import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MentorPage extends StatefulWidget {
  const MentorPage({super.key});

  @override
  State<MentorPage> createState() => _MentorPageState();
}

class _MentorPageState extends State<MentorPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> alumni = [];
  bool _isLoading = true;
  Map<String, bool> connectionRequestSent = {};

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
      print('🔍 Starting database structure inspection...');

      // Check users collection
      QuerySnapshot allUsersSnapshot =
          await _firestore.collection('users').get();
      print('\n📚 Database Overview:');
      print(
        'Total documents in users collection: ${allUsersSnapshot.docs.length}',
      );

      if (allUsersSnapshot.docs.isEmpty) {
        print('⚠️ WARNING: No users found in the database!');
      } else {
        print('\n📄 Document Structure for each user:');
        for (var doc in allUsersSnapshot.docs) {
          print('\n👤 User ID: ${doc.id}');
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          print('Fields found in document:');
          data.forEach((key, value) {
            print('  - $key: $value');
          });
        }
      }

      // Try to get alumni
      print('\n🎓 Checking for alumni...');
      QuerySnapshot alumniSnapshot =
          await _firestore
              .collection('users')
              .where('role', isEqualTo: 'alumni')
              .get();

      print(
        'Alumni query results: ${alumniSnapshot.docs.length} documents found',
      );

      List<Map<String, dynamic>> alumniList = [];

      for (var doc in alumniSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        alumniList.add({
          'id': doc.id,
          'name': data['name'] ?? 'No name',
          'expertise': data['expertise'] ?? 'Not specified',
          'industry': data['industry'] ?? 'Not specified',
          'profilePicture': data['profilePicture'] ?? '',
          'graduationYear': data['graduation_year'] ?? '',
        });
      }

      setState(() {
        alumni = alumniList;
        connectionRequestSent = {};
        _isLoading = false;
      });

      if (alumniList.isEmpty) {
        print('\n❌ No alumni found. Please check that:');
        print('1. Users exist in the database');
        print('2. Users have a "role" field');
        print('3. The "role" field is set to exactly "alumni" (lowercase)');
      }
    } catch (e, stackTrace) {
      print('\n🚨 Error in _fetchAlumni:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Error: Could not read database structure. Check debug console for details.',
          ),
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _sendConnectionRequest(String alumniId) async {
    try {
      String currentUserId = _auth.currentUser!.uid;

      // First check if request already exists
      QuerySnapshot existingRequest =
          await _firestore
              .collection('connection_requests')
              .where('student_id', isEqualTo: currentUserId)
              .where('alumni_id', isEqualTo: alumniId)
              .get();

      if (existingRequest.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have already sent a request to this alumni'),
          ),
        );
        return;
      }

      // Create connection request
      await _firestore.collection('connection_requests').add({
        'student_id': currentUserId,
        'alumni_id': alumniId,
        'status': 'pending',
        'message': '',
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Update local state
      setState(() {
        connectionRequestSent[alumniId] = true;
      });

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
        title: const Text('Alumni'),
        backgroundColor: Colors.blue[800],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : alumni.isEmpty
              ? const Center(child: Text('No alumni available at the moment'))
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Available Alumni',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: alumni.length,
                        itemBuilder: (context, index) {
                          final alumniMember = alumni[index];
                          final bool requestSent =
                              connectionRequestSent[alumniMember['id']] ??
                              false;

                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundImage:
                                        alumniMember['profilePicture']
                                                .isNotEmpty
                                            ? NetworkImage(
                                              alumniMember['profilePicture'],
                                            )
                                            : null,
                                    child:
                                        alumniMember['profilePicture'].isEmpty
                                            ? Text(
                                              alumniMember['name'][0]
                                                  .toUpperCase(),
                                            )
                                            : null,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          alumniMember['name'],
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Expertise: ${alumniMember['expertise']}',
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        Text(
                                          'Industry: ${alumniMember['industry']}',
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed:
                                        requestSent
                                            ? null
                                            : () => _sendConnectionRequest(
                                              alumniMember['id'],
                                            ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      disabledBackgroundColor: Colors.grey,
                                    ),
                                    child: Text(
                                      requestSent ? 'Request Sent' : 'Connect',
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
