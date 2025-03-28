import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ForumPage extends StatefulWidget {
  const ForumPage({Key? key}) : super(key: key);

  @override
  _ForumPageState createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Forum')),
      body: Center(child: Text('Forum Page - Discussions')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement create thread functionality
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Create thread functionality coming soon')),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
