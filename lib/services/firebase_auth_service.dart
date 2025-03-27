import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ Updated: Sign Up with Name
  Future<String?> signUp(
    String email,
    String password,
    String userType,
    String name,
  ) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': name, // ✅ Store User's Name
        'email': email,
        'userType': userType,
      });

      return null; // No error
    } catch (e) {
      return e.toString(); // Return error message
    }
  }

  // Sign In
  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // Get User Type
  Future<String?> getUserType(String uid) async {
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(uid).get();
    return userDoc['userType'];
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
