import 'package:flutter/material.dart';
import 'forum.dart';
import 'mentor_find.dart';
import 'mentor_connect.dart';
import 'alumni_roadmaps.dart'; // Import the new Alumni Roadmaps page

class StudentHomePage extends StatefulWidget {
  const StudentHomePage({super.key});

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
      HomeContent(onFeatureSelected: _onItemTapped),
      const MentorConnectPage(),
      const ForumPage(),
      const MentorPage(),
      const AlumniRoadmapsPage(), // Updated to use the new Alumni Roadmaps page
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
              // Handle profile
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
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

// The rest of the file remains the same as in the previous implementation

class HomeContent extends StatelessWidget {
  const HomeContent({super.key, required this.onFeatureSelected});

  final Function(int) onFeatureSelected;

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
                  const Text(
                    'Welcome Back, Student!',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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

          // Feature Options
          const Text(
            'Quick Access',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Feature Cards
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
                'Find the perfect alumni mentor',
                Icons.connect_without_contact,
                Colors.blue,
                () {
                  // Navigate to Mentor Connect
                  onFeatureSelected(1);
                },
              ),
              _buildFeatureCard(
                context,
                'Forum',
                'Discuss with peers and alumni',
                Icons.forum,
                Colors.orange,
                () {
                  // Navigate to Forum
                  onFeatureSelected(2);
                },
              ),
              _buildFeatureCard(
                context,
                'Mentors',
                'Explore available mentors',
                Icons.school,
                Colors.purple,
                () {
                  // Navigate to Mentors
                  onFeatureSelected(3);
                },
              ),
              _buildFeatureCard(
                context,
                'Alumni Roadmaps',
                'explore career paths',
                Icons.track_changes,
                Colors.green,
                () {
                  onFeatureSelected(4); // Navigate to Events page
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Recent Activities
          const Text(
            'Recent Activities',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildActivityItem(
            'New mentoring program opened',
            'Join now to get industry expertise.',
            '2 hours ago',
          ),
          _buildActivityItem(
            'Alumni John posted in the forum',
            'How to prepare for tech interviews?',
            '1 day ago',
          ),
          _buildActivityItem(
            'Career workshop next week',
            'Register to secure your spot.',
            '2 days ago',
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

  Widget _buildActivityItem(String title, String subtitle, String timeAgo) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Text(
          timeAgo,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        onTap: () {
          // Handle activity tap
        },
      ),
    );
  }
}
