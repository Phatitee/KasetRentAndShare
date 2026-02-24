import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
          name: name,
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

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
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
