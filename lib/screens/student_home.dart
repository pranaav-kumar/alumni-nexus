import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'forum.dart';
import 'mentor_find.dart';
import 'mentor_connect.dart';
import 'alumni_roadmaps.dart';
import 'ProfilePager.dart'; // Import ProfilePage

class StudentHomePage extends StatefulWidget {
  final String userName;

  const StudentHomePage({super.key, required this.userName});

  @override
  StudentHomePageState createState() => StudentHomePageState();
}

class StudentHomePageState extends State<StudentHomePage> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeContent(onFeatureSelected: _onItemTapped, userName: widget.userName),
      MentorConnectPage(userName: widget.userName),
      const ForumPage(),
      const MentorPage(),
      const AlumniRoadmapsPage(),
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
        title: const Text('Student Dashboard'),
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
            label: 'Mentor Connect',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.forum), label: 'Forum'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Mentors'),
          BottomNavigationBarItem(
            icon: Icon(Icons.track_changes),
            label: 'Alumni Roadmaps',
          ),
        ],
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  final Function(int) onFeatureSelected;
  final String? userName;

  const HomeContent({
    super.key,
    required this.onFeatureSelected,
    this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName != null
                        ? 'Welcome Back, $userName!'
                        : 'Welcome Back!',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Connect with alumni and mentors to boost your career.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Quick Access',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: [
              _buildFeatureCard(
                context,
                'Mentor Connect',
                'Find your mentor',
                Icons.people,
                Colors.blue,
                () {
                  onFeatureSelected(1);
                },
              ),
              _buildFeatureCard(
                context,
                'Forum',
                'Engage in discussions',
                Icons.forum,
                Colors.orange,
                () {
                  onFeatureSelected(2);
                },
              ),
              _buildFeatureCard(
                context,
                'Mentors',
                'Explore mentorship',
                Icons.school,
                Colors.purple,
                () {
                  onFeatureSelected(3);
                },
              ),
              _buildFeatureCard(
                context,
                'Alumni Roadmaps',
                'Career guidance',
                Icons.track_changes,
                Colors.green,
                () {
                  onFeatureSelected(4);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
