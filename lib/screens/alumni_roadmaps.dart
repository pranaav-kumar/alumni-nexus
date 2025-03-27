import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AlumniRoadmapsPage extends StatefulWidget {
  const AlumniRoadmapsPage({super.key});

  @override
  _AlumniRoadmapsPageState createState() => _AlumniRoadmapsPageState();
}

class _AlumniRoadmapsPageState extends State<AlumniRoadmapsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Alumni Success Roadmaps')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Roadmaps',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('success_roadmaps')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No roadmaps available'));
                }

                // Filter roadmaps based on search query
                var filteredDocs =
                    snapshot.data!.docs.where((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      return data['title'].toString().toLowerCase().contains(
                            _searchQuery,
                          ) ||
                          data['authorName'].toString().toLowerCase().contains(
                            _searchQuery,
                          );
                    }).toList();

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    var roadmap =
                        filteredDocs[index].data() as Map<String, dynamic>;
                    return _buildRoadmapCard(roadmap);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoadmapCard(Map<String, dynamic> roadmap) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      child: ExpansionTile(
        title: Text(
          roadmap['title'] ?? 'Untitled Roadmap',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'By ${roadmap['authorName'] ?? 'Anonymous'}',
          style: TextStyle(color: Colors.grey),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(roadmap['description'] ?? 'No description'),
                SizedBox(height: 16),
                Text(
                  'Milestones',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                ...?roadmap['milestones']
                    ?.map<Widget>(
                      (milestone) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: Colors.green,
                            ),
                            SizedBox(width: 8),
                            Expanded(child: Text(milestone)),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
