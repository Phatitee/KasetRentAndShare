import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      // Validate KU email
      if (!email.endsWith('@ku.th')) {
        throw Exception('กรุณาใช้อีเมล @ku.th เท่านั้น');
      }

      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return credential;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw Exception('ไม่พบผู้ใช้นี้ในระบบ');
        case 'wrong-password':
          throw Exception('รหัสผ่านไม่ถูกต้อง');
        case 'invalid-email':
          throw Exception('รูปแบบอีเมลไม่ถูกต้อง');
        case 'user-disabled':
          throw Exception('บัญชีนี้ถูกระงับการใช้งาน');
        default:
          throw Exception('เข้าสู่ระบบล้มเหลว: ${e.message}');
      }
    } catch (e) {
      throw Exception('เกิดข้อผิดพลาด: $e');
    }
  }

  // Helper method to format name to "First Letter Capitalized"
  String _formatName(String name) {
    if (name.isEmpty) return name;
    
    // Split by space, filter out empty strings, capitalize first letter of each word
    return name.trim().split(RegExp(r'\s+')).map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  // Register with email and password
  Future<UserCredential?> registerWithEmail(
    String email,
    String password,
    String name,
  ) async {
    try {
      // Validate KU email
      if (!email.endsWith('@ku.th')) {
        throw Exception('กรุณาใช้อีเมล @ku.th เท่านั้น');
      }

      final formattedName = _formatName(name);

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Send email verification
      await credential.user?.sendEmailVerification();

      // Create user document in Firestore
      if (credential.user != null) {
        final userModel = UserModel(
          uid: credential.user!.uid,
          email: email,
          name: formattedName,
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .set(userModel.toFirestore());
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'weak-password':
          throw Exception('รหัสผ่านอ่อนแอเกินไป');
        case 'email-already-in-use':
          throw Exception('อีเมลนี้ถูกใช้งานแล้ว');
        case 'invalid-email':
          throw Exception('รูปแบบอีเมลไม่ถูกต้อง');
        default:
          throw Exception('สมัครสมาชิกล้มเหลว: ${e.message}');
      }
    } catch (e) {
      throw Exception('เกิดข้อผิดพลาด: $e');
    }
  }

  // Sign out (Firebase + Google)
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Sign in with Google (enforces @ku.th)
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // user cancelled

      // Enforce KU email
      if (!googleUser.email.endsWith('@ku.th')) {
        await _googleSignIn.signOut();
        throw Exception('กรุณาใช้บัญชี Google @ku.th เท่านั้น');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        // Create or update Firestore doc
        final docRef = _firestore.collection('users').doc(user.uid);
        final doc = await docRef.get();
        if (!doc.exists) {
          final formattedName = _formatName(user.displayName ?? '');
          final userModel = UserModel(
            uid: user.uid,
            email: user.email ?? '',
            name: formattedName,
            photoUrl: user.photoURL,
            createdAt: DateTime.now(),
          );
          await docRef.set(userModel.toFirestore());
        } else {
          // Update photoUrl only if it's currently null or a Google URL
          final currentData = doc.data() as Map<String, dynamic>;
          final currentPhotoUrl = currentData['photoUrl'] as String?;
          if (currentPhotoUrl == null ||
              currentPhotoUrl.contains('googleusercontent.com')) {
            await docRef.update({'photoUrl': user.photoURL});
          }
        }
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception('Google Sign-In ล้มเหลว: ${e.message}');
    } catch (e) {
      rethrow;
    }
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    return FirestoreService().getUserData(uid);
  }

  // Update user data
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      throw Exception('อัปเดตข้อมูลล้มเหลว: $e');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw Exception('ไม่พบผู้ใช้นี้ในระบบ');
        case 'invalid-email':
          throw Exception('รูปแบบอีเมลไม่ถูกต้อง');
        default:
          throw Exception('ส่งอีเมลรีเซ็ตรหัสผ่านล้มเหลว: ${e.message}');
      }
    }
  }

  // Check if email is verified
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // Resend verification email
  Future<void> resendVerificationEmail() async {
    await _auth.currentUser?.sendEmailVerification();
  }
}
