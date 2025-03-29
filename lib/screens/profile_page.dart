import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class ProfilePage extends StatefulWidget {
  final String userType;

  const ProfilePage({Key? key, required this.userType}) : super(key: key);

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  // Color Palette (matching your existing theme)
  final Color lightBeige = Color.fromRGBO(247, 240, 234, 1);
  final Color warmBeige = Color.fromRGBO(225, 213, 201, 1);
  final Color darkGrayBlack = Color.fromRGBO(34, 35, 37, 1);
  final Color darkGrayBlack70 = Color.fromRGBO(34, 35, 37, 0.7);

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final _formKey = GlobalKey<FormState>();

  // User data
  String _name = '';
  String _email = '';
  String _bio = '';
  String _institution = '';
  String? _imageUrl;
  File? _imageFile;
  List<String> _skills = [];
  String _newSkill = '';
  bool _isEditing = false;
  bool _isLoading = true;

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _institutionController = TextEditingController();
  final TextEditingController _skillController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(currentUser.uid).get();

        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;

          setState(() {
            _name = userData['name'] ?? '';
            _email = currentUser.email ?? '';
            _bio = userData['bio'] ?? '';
            _institution = userData['institution'] ?? '';
            _imageUrl = userData['profileImageUrl'];
            _skills = List<String>.from(userData['skills'] ?? []);

            // Set controller values
            _nameController.text = _name;
            _bioController.text = _bio;
            _institutionController.text = _institution;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading profile: $e'),
          backgroundColor: darkGrayBlack,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return _imageUrl;

    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      String fileName =
          'profile_${currentUser.uid}_${DateTime.now().millisecondsSinceEpoch}';
      Reference storageRef = _storage.ref().child('profile_images/$fileName');

      await storageRef.putFile(_imageFile!);
      String downloadUrl = await storageRef.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading image: $e'),
          backgroundColor: darkGrayBlack,
        ),
      );
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Upload image if changed
      String? imageUrl = _imageFile != null ? await _uploadImage() : _imageUrl;

      // Update user data
      await _firestore.collection('users').doc(currentUser.uid).update({
        'name': _nameController.text,
        'bio': _bioController.text,
        'institution': _institutionController.text,
        'skills': _skills,
        'profileImageUrl': imageUrl,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      setState(() {
        _name = _nameController.text;
        _bio = _bioController.text;
        _institution = _institutionController.text;
        _imageUrl = imageUrl;
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: darkGrayBlack,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving profile: $e'),
          backgroundColor: darkGrayBlack,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addSkill() {
    if (_newSkill.isNotEmpty && !_skills.contains(_newSkill)) {
      setState(() {
        _skills.add(_newSkill);
        _skillController.clear();
        _newSkill = '';
      });
    }
  }

  void _removeSkill(String skill) {
    setState(() {
      _skills.remove(skill);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: lightBeige,
        appBar: AppBar(
          title: Text('Profile'),
          backgroundColor: darkGrayBlack,
          foregroundColor: lightBeige,
        ),
        body: Center(child: CircularProgressIndicator(color: darkGrayBlack)),
      );
    }

    return Scaffold(
      backgroundColor: lightBeige,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Profile' : 'Profile'),
        backgroundColor: darkGrayBlack,
        foregroundColor: lightBeige,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            )
          else
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                setState(() {
                  // Reset controllers to original values
                  _nameController.text = _name;
                  _bioController.text = _bio;
                  _institutionController.text = _institution;
                  _imageFile = null;
                  _isEditing = false;
                });
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Image
              GestureDetector(
                onTap: _isEditing ? _pickImage : null,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: warmBeige,
                      backgroundImage:
                          _imageFile != null
                              ? FileImage(_imageFile!) as ImageProvider
                              : (_imageUrl != null
                                  ? NetworkImage(_imageUrl!)
                                  : null),
                      child:
                          (_imageFile == null && _imageUrl == null)
                              ? Icon(
                                Icons.person,
                                size: 80,
                                color: darkGrayBlack70,
                              )
                              : null,
                    ),
                    if (_isEditing)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: darkGrayBlack,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            color: lightBeige,
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 16),

              // User Type Badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: darkGrayBlack,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.userType,
                  style: TextStyle(
                    color: lightBeige,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Name Field
              if (_isEditing)
                _buildTextField(
                  controller: _nameController,
                  labelText: 'Full Name',
                  prefixIcon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                )
              else
                _buildProfileItem('Full Name', _name, Icons.person_outline),
              SizedBox(height: 16),

              // Email (non-editable)
              _buildProfileItem('Email', _email, Icons.email_outlined),
              SizedBox(height: 16),

              // Institution Field
              if (_isEditing)
                _buildTextField(
                  controller: _institutionController,
                  labelText: 'Institution',
                  prefixIcon: Icons.school_outlined,
                )
              else
                _buildProfileItem(
                  'Institution',
                  _institution.isEmpty ? 'Not specified' : _institution,
                  Icons.school_outlined,
                ),
              SizedBox(height: 16),

              // Bio Field
              if (_isEditing)
                _buildTextField(
                  controller: _bioController,
                  labelText: 'Bio',
                  prefixIcon: Icons.info_outline,
                  maxLines: 3,
                )
              else
                _buildProfileItem(
                  'Bio',
                  _bio.isEmpty ? 'No bio added yet' : _bio,
                  Icons.info_outline,
                ),
              SizedBox(height: 24),

              // Skills Section
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Skills',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: darkGrayBlack,
                  ),
                ),
              ),
              SizedBox(height: 8),

              if (_isEditing)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _skillController,
                        decoration: InputDecoration(
                          labelText: 'Add a skill',
                          prefixIcon: Icon(
                            Icons.add_circle_outline,
                            color: darkGrayBlack,
                          ),
                          labelStyle: TextStyle(color: darkGrayBlack70),
                          filled: true,
                          fillColor: warmBeige,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: darkGrayBlack.withOpacity(0.2),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: darkGrayBlack,
                              width: 2,
                            ),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _newSkill = value;
                          });
                        },
                        onSubmitted: (_) => _addSkill(),
                      ),
                    ),
                    SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.add, color: darkGrayBlack),
                      onPressed: _addSkill,
                    ),
                  ],
                ),

              SizedBox(height: 8),

              // Skills Chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    _skills.map((skill) {
                      return Chip(
                        label: Text(skill),
                        backgroundColor: warmBeige,
                        deleteIcon:
                            _isEditing ? Icon(Icons.cancel, size: 18) : null,
                        onDeleted:
                            _isEditing ? () => _removeSkill(skill) : null,
                      );
                    }).toList(),
              ),

              SizedBox(height: 32),

              // Save Button
              if (_isEditing)
                ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkGrayBlack,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Save Profile',
                    style: TextStyle(
                      fontSize: 18,
                      color: lightBeige,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(prefixIcon, color: darkGrayBlack),
        labelStyle: TextStyle(color: darkGrayBlack70),
        filled: true,
        fillColor: warmBeige,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkGrayBlack.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkGrayBlack, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }

  Widget _buildProfileItem(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: warmBeige,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: darkGrayBlack.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: darkGrayBlack),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 14, color: darkGrayBlack70),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(fontSize: 16, color: darkGrayBlack),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _institutionController.dispose();
    _skillController.dispose();
    super.dispose();
  }
}
