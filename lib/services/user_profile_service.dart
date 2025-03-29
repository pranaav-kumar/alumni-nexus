import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class UserProfileService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Get current user data
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      if (currentUserId == null) return null;

      DocumentSnapshot doc =
          await _firestore.collection('users').doc(currentUserId).get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Update user profile data
  Future<bool> updateUserProfile({
    String? name,
    String? bio,
    String? institution,
    List<String>? skills,
    File? profileImage,
  }) async {
    try {
      if (currentUserId == null) return false;

      Map<String, dynamic> userData = {};

      // Add non-null values to update
      if (name != null) userData['name'] = name;
      if (bio != null) userData['bio'] = bio;
      if (institution != null) userData['institution'] = institution;
      if (skills != null) userData['skills'] = skills;

      // Upload profile image if provided
      if (profileImage != null) {
        String? imageUrl = await uploadProfileImage(profileImage);
        if (imageUrl != null) {
          userData['profileImageUrl'] = imageUrl;
        }
      }

      // Add timestamp
      userData['lastUpdated'] = FieldValue.serverTimestamp();

      // Update in Firestore
      await _firestore.collection('users').doc(currentUserId).update(userData);

      return true;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }

  // Upload profile image to Firebase Storage
  Future<String?> uploadProfileImage(File imageFile) async {
    try {
      if (currentUserId == null) return null;

      String fileName =
          'profile_${currentUserId}_${DateTime.now().millisecondsSinceEpoch}';
      Reference storageRef = _storage.ref().child('profile_images/$fileName');

      await storageRef.putFile(imageFile);
      String downloadUrl = await storageRef.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // Add additional field to user profile
  Future<bool> addCustomField(String fieldName, dynamic value) async {
    try {
      if (currentUserId == null) return false;

      await _firestore.collection('users').doc(currentUserId).update({
        fieldName: value,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error adding custom field: $e');
      return false;
    }
  }

  // Get additional user-specific fields based on user type
  Future<Map<String, dynamic>?> getTypeSpecificFields(String userType) async {
    try {
      if (currentUserId == null) return null;

      DocumentSnapshot doc =
          await _firestore
              .collection(userType.toLowerCase())
              .doc(currentUserId)
              .get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting type-specific fields: $e');
      return null;
    }
  }
}
