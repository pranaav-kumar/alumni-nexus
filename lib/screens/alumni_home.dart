import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:new_one/screens/student_home.dart';
import 'alumniforum.dart';
import 'student_connections.dart';
import 'success_roadmap.dart';
import 'ProfilePager.dart'; // Import Profile Page

class AlumniHomePage extends StatefulWidget {
  const AlumniHomePage({super.key});

  @override
  AlumniHomePageState createState() => AlumniHomePageState();
}

class AlumniHomePageState extends State<AlumniHomePage> {
  String? userName;
  int _selectedIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    // Fetch current user's display name
    userName = FirebaseAuth.instance.currentUser?.displayName ?? "Alumni";

    _pages = [
      HomeContent(onFeatureSelected: _onItemTapped, userName: userName),
      StudentConnectionsPage(userName: userName),
      const ForumPage(),
      const SuccessRoadmapPage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alumni Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Handle notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              // Get current user's ID
              String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

              if (currentUserId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfilePage(userId: currentUserId),
                  ),
                );
              } else {
                // Handle case where no user is logged in
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please log in to view profile'),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Connections',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.forum), label: 'Forum'),
          BottomNavigationBarItem(
            icon: Icon(Icons.track_changes),
            label: 'Success Roadmap',
          ),
        ],
      ),
    );
  }
}
