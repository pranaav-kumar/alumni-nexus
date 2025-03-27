import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SuccessRoadmapPage extends StatefulWidget {
  const SuccessRoadmapPage({super.key});

  @override
  _SuccessRoadmapPageState createState() => _SuccessRoadmapPageState();
}

class _SuccessRoadmapPageState extends State<SuccessRoadmapPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final List<TextEditingController> _milestoneControllers = [];
  final List<String> _milestones = [];

  void _addMilestone() {
    setState(() {
      _milestoneControllers.add(TextEditingController());
      _milestones.add('');
    });
  }

  void _removeMilestone(int index) {
    setState(() {
      _milestoneControllers.removeAt(index);
      _milestones.removeAt(index);
    });
  }

  Future<void> _publishRoadmap() async {
    if (_formKey.currentState!.validate()) {
      // Collect milestones
      _milestones.clear();
      for (var controller in _milestoneControllers) {
        if (controller.text.isNotEmpty) {
          _milestones.add(controller.text);
        }
      }

      // Get current user
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please log in to publish a roadmap')),
        );
        return;
      }

      // Fetch user details
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();

      // Prepare roadmap data
      Map<String, dynamic> roadmapData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'milestones': _milestones,
        'authorId': currentUser.uid,
        'authorName': userDoc['name'],
        'createdAt': FieldValue.serverTimestamp(),
      };

      try {
        // Save to Firestore
        await FirebaseFirestore.instance
            .collection('success_roadmaps')
            .add(roadmapData);

        // Clear form
        _titleController.clear();
        _descriptionController.clear();
        _milestoneControllers.clear();
        _milestones.clear();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Roadmap published successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to publish roadmap: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Success Roadmap')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Roadmap Title',
                hintText: 'e.g., My Journey to Becoming a Software Engineer',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Roadmap Description',
                hintText: 'Briefly describe your career journey',
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            Text('Milestones', style: Theme.of(context).textTheme.titleLarge),
            ..._milestoneControllers.asMap().entries.map((entry) {
              int index = entry.key;
              TextEditingController controller = entry.value;
              return Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: controller,
                      decoration: InputDecoration(
                        labelText: 'Milestone ${index + 1}',
                        hintText: 'e.g., Internship at XYZ Company',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.remove_circle),
                    onPressed: () => _removeMilestone(index),
                  ),
                ],
              );
            }).toList(),
            ElevatedButton(
              onPressed: _addMilestone,
              child: Text('Add Milestone'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _publishRoadmap,
              child: Text('Publish Roadmap'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (var controller in _milestoneControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
