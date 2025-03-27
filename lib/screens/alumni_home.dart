import 'package:flutter/material.dart';
import 'alumniforum.dart';
import 'student_connections.dart';
import 'success_roadmap.dart';

class AlumniHomePage extends StatefulWidget {
  const AlumniHomePage({super.key});

  @override
  AlumniHomePageState createState() => AlumniHomePageState();
}

class AlumniHomePageState extends State<AlumniHomePage> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeContent(onFeatureSelected: _onItemTapped),
      const StudentConnectionsPage(),
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
            label: 'Connections',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.forum), label: 'Forum'),
          BottomNavigationBarItem(
            icon: Icon(Icons.track_changes),
            label: 'create success Roadmap',
          ),
        ],
      ),
    );
  }
}

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
                    'Welcome Back, Alumni!',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Stay connected and help shape the future of your alma mater.',
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
                'Student Connections',
                'Connect with current students',
                Icons.people,
                Colors.blue,
                () {
                  // Navigate to Student Connections
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
                  // Navigate to Forum
                  onFeatureSelected(2);
                },
              ),
              _buildFeatureCard(
                context,
                'Success Roadmap',
                'Share your career journey',
                Icons.track_changes,
                Colors.purple,
                () {
                  // Navigate to Success Roadmap
                  onFeatureSelected(3);
                },
              ),
              _buildFeatureCard(
                context,
                'Mentor Opportunities',
                'Become a mentor',
                Icons.workspace_premium,
                Colors.green,
                () {
                  // Future: Add mentor opportunities
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
            'New Success Story Added',
            'Check out the latest alumni achievement',
            '2 hours ago',
          ),
          _buildActivityItem(
            'Mentorship Program Update',
            'New mentoring opportunities available',
            '1 day ago',
          ),
          _buildActivityItem(
            'Forum Discussion',
            'Career development insights shared',
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
