import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserProfile {
  String id;
  String name;
  String email;
  String profileImage;
  String bio;
  String graduationYear;
  String backgroundImage;
  String location;
  String jobTitle;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.profileImage,
    required this.bio,
    required this.graduationYear,
    required this.backgroundImage,
    required this.location,
    required this.jobTitle,
  });

  // Factory constructor to create a UserProfile from Firestore document
  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      profileImage: data['profileImage'] ?? '',
      bio: data['bio'] ?? '',
      graduationYear: data['graduationYear'] ?? '',
      backgroundImage: data['backgroundImage'] ?? '',
      location: data['location'] ?? '',
      jobTitle: data['jobTitle'] ?? '',
    );
  }

  // Method to convert UserProfile to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'profileImage': profileImage,
      'bio': bio,
      'graduationYear': graduationYear,
      'backgroundImage': backgroundImage,
      'location': location,
      'jobTitle': jobTitle,
    };
  }
}

class ProfilePage extends StatefulWidget {
  final String? userId;

  const ProfilePage({Key? key, this.userId}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<UserProfile> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _fetchUserProfile();
  }

  Future<UserProfile> _fetchUserProfile() async {
    try {
      // Use the provided userId or get the current user's ID
      String userId =
          widget.userId ??
          firebase_auth.FirebaseAuth.instance.currentUser?.uid ??
          'unknown';

      // Fetch user profile from Firestore
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

      if (userDoc.exists) {
        return UserProfile.fromFirestore(userDoc);
      } else {
        // Return a default profile if no profile is found
        return UserProfile(
          id: userId,
          name: 'User',
          email: 'user@example.com',
          profileImage: 'https://example.com/default-profile.jpg',
          bio: 'No bio available',
          graduationYear: 'N/A',
          backgroundImage: 'https://example.com/default-background.jpg',
          location: 'N/A',
          jobTitle: 'N/A',
        );
      }
    } catch (e) {
      print('Error fetching profile: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<UserProfile>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          UserProfile user = snapshot.data!;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 250.0,
                pinned: true,
                backgroundColor: Colors.black,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      // Navigate to edit profile page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => EditProfilePage(userId: user.id),
                        ),
                      );
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: user.backgroundImage,
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) =>
                                Container(color: Colors.grey[300]),
                        errorWidget:
                            (context, url, error) =>
                                Container(color: Colors.grey[300]),
                      ),
                      Positioned(
                        bottom: 10,
                        left: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundImage: CachedNetworkImageProvider(
                                user.profileImage,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              user.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              user.jobTitle,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              user.location,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        color: Colors.white,
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'About',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                user.bio,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.email),
                        title: Text(user.email),
                      ),
                      ListTile(
                        leading: const Icon(Icons.school),
                        title: Text('Graduation Year: ${user.graduationYear}'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class EditProfilePage extends StatefulWidget {
  final String userId;

  const EditProfilePage({Key? key, required this.userId}) : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController jobTitleController;
  late TextEditingController bioController;
  late TextEditingController graduationYearController;
  late TextEditingController locationController;
  late TextEditingController profileImageController;
  late TextEditingController backgroundImageController;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with empty strings
    nameController = TextEditingController();
    emailController = TextEditingController();
    jobTitleController = TextEditingController();
    bioController = TextEditingController();
    graduationYearController = TextEditingController();
    locationController = TextEditingController();
    profileImageController = TextEditingController();
    backgroundImageController = TextEditingController();

    // Fetch existing user data
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .get();

      if (userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          nameController.text = data['name'] ?? '';
          emailController.text = data['email'] ?? '';
          jobTitleController.text = data['jobTitle'] ?? '';
          bioController.text = data['bio'] ?? '';
          graduationYearController.text = data['graduationYear'] ?? '';
          locationController.text = data['location'] ?? '';
          profileImageController.text = data['profileImage'] ?? '';
          backgroundImageController.text = data['backgroundImage'] ?? '';
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Create a user profile object
        UserProfile userProfile = UserProfile(
          id: widget.userId,
          name: nameController.text,
          email: emailController.text,
          jobTitle: jobTitleController.text,
          bio: bioController.text,
          graduationYear: graduationYearController.text,
          location: locationController.text,
          profileImage: profileImageController.text,
          backgroundImage: backgroundImageController.text,
        );

        // Save to Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .set(userProfile.toFirestore(), SetOptions(merge: true));

        // Navigate back to profile page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProfilePage(userId: widget.userId),
          ),
        );
      } catch (e) {
        // Show error
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving profile: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Name"),
                validator: (value) => value!.isEmpty ? "Enter a name" : null,
              ),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email"),
                validator: (value) => value!.isEmpty ? "Enter an email" : null,
              ),
              TextFormField(
                controller: jobTitleController,
                decoration: const InputDecoration(labelText: "Job Title"),
              ),
              TextFormField(
                controller: bioController,
                decoration: const InputDecoration(labelText: "Bio"),
              ),
              TextFormField(
                controller: graduationYearController,
                decoration: const InputDecoration(labelText: "Graduation Year"),
              ),
              TextFormField(
                controller: locationController,
                decoration: const InputDecoration(labelText: "Location"),
              ),
              TextFormField(
                controller: profileImageController,
                decoration: const InputDecoration(
                  labelText: "Profile Image URL",
                ),
              ),
              TextFormField(
                controller: backgroundImageController,
                decoration: const InputDecoration(
                  labelText: "Background Image URL",
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveProfile,
                child: const Text("Save Profile"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Dispose controllers
    nameController.dispose();
    emailController.dispose();
    jobTitleController.dispose();
    bioController.dispose();
    graduationYearController.dispose();
    locationController.dispose();
    profileImageController.dispose();
    backgroundImageController.dispose();
    super.dispose();
  }
}
