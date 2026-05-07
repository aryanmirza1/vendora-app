import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vendora/models/user_model.dart';

class AuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  firebase_auth.User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();

  // Sign up for buyers
  Future<firebase_auth.UserCredential?> signUpBuyer({
    required String email,
    required String password,
    required String name,
    required String phone,
    String? address,
  }) async {
    try {
      // Create user in Firebase Auth
      debugPrint("AuthService: Creating buyer in Auth...");
      firebase_auth.UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint("AuthService: Buyer Auth created: ${credential.user?.uid}");

      // Create user document in Firestore
      debugPrint("AuthService: Saving buyer to Firestore...");
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'id': credential.user!.uid,
        'name': name,
        'email': email,
        'phone': phone,
        'address': address ?? '',
        'role': 'buyer',
        'profileImageUrl': null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return credential;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Sign up for sellers
  Future<firebase_auth.UserCredential?> signUpSeller({
    required String email,
    required String password,
    required String name,
    required String businessCategory,
    required String address,
  }) async {
    try {
      // Create user in Firebase Auth
      debugPrint("AuthService: Creating seller in Auth...");
      firebase_auth.UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint("AuthService: Seller Auth created: ${credential.user?.uid}");

      // Create seller document in Firestore
      debugPrint("AuthService: Saving seller to Firestore...");
      await _firestore.collection('sellers').doc(credential.user!.uid).set({
        'id': credential.user!.uid,
        'name': name,
        'email': email,
        'businessCategory': businessCategory,
        'address': address,
        'status': 'pending', // New sellers need admin approval
        'profileImageUrl': null,
        'totalProducts': 0,
        'totalSales': 0.0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Also create a user entry with seller role
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'id': credential.user!.uid,
        'name': name,
        'email': email,
        'phone': '',
        'address': address,
        'role': 'seller',
        'profileImageUrl': null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return credential;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Sign up for admins (usually created by super admin)
  Future<firebase_auth.UserCredential?> signUpAdmin({
    required String email,
    required String password,
    required String name,
    String role = 'admin',
  }) async {
    try {
      firebase_auth.UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('admins').doc(credential.user!.uid).set({
        'id': credential.user!.uid,
        'name': name,
        'email': email,
        'role': role,
        'profileImageUrl': null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return credential;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Sign in
  Future<firebase_auth.UserCredential?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint("AuthService: Attempting sign in for $email");
      firebase_auth.UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint("AuthService: Sign in successful");
      return credential;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Forgot password - sends password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Confirm password reset
  Future<void> confirmPasswordReset({
    required String code,
    required String newPassword,
  }) async {
    try {
      await _auth.confirmPasswordReset(
        code: code,
        newPassword: newPassword,
      );
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Get user role from Firestore
  Future<String?> getUserRole(String userId) async {
    try {
      debugPrint("AuthService: Getting user role for $userId");
      
      // Use serverAndCache - tries server first, falls back to cache
      final userDoc = await _firestore.collection('users').doc(userId).get(
        const GetOptions(source: Source.serverAndCache),
      );
      if (userDoc.exists) {
        final role = userDoc.data()?['role'] as String?;
        debugPrint("AuthService: Found role in users: $role");
        return role;
      }

      // Check if admin
      final adminDoc = await _firestore.collection('admins').doc(userId).get(
        const GetOptions(source: Source.serverAndCache),
      );
      if (adminDoc.exists) {
        debugPrint("AuthService: Found admin role");
        return 'admin';
      }

      debugPrint("AuthService: No role found for $userId");
      return null;
    } catch (e) {
      debugPrint("AuthService: Error getting user role: $e");
      return null;
    }
  }

  // Get user data
  Future<User?> getUserData(String userId) async {
    try {
      debugPrint("AuthService: Fetching user data for $userId");
      // Use serverAndCache - tries server first, falls back to cache if unavailable
      final userDoc = await _firestore.collection('users').doc(userId).get(
        const GetOptions(source: Source.serverAndCache),
      );
      
      if (!userDoc.exists) {
        debugPrint("AuthService: User document does not exist for $userId");
        // Try checking sellers collection as fallback or logic specific
        return null;
      }

      debugPrint("AuthService: User data found: ${userDoc.data()}");
      final data = userDoc.data()!;
      return User(
        id: data['id'] as String,
        name: data['name'] as String,
        email: data['email'] as String,
        phone: data['phone'] as String,
        address: data['address'] as String?,
        role: data['role'] as String,
        profileImageUrl: data['profileImageUrl'] as String?,
      );
    } catch (e) {
      debugPrint("AuthService: Error getting user data: $e");
      return null;
    }
  }

  // Update user data
  Future<void> updateUserData(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(userId).update(data);
    } catch (e) {
      throw Exception('Failed to update user data: $e');
    }
  }

  // Error handling
  String _handleAuthError(dynamic error) {
    print("Auth Error: $error"); // Log raw error
    if (error is firebase_auth.FirebaseAuthException) {
      switch (error.code) {
        case 'weak-password':
          return 'The password provided is too weak.';
        case 'email-already-in-use':
          return 'An account already exists for that email.';
        case 'user-not-found':
          return 'No user found for that email.';
        case 'wrong-password':
          return 'Wrong password provided.';
        case 'invalid-email':
          return 'The email address is invalid.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        case 'too-many-requests':
          return 'Too many requests. Please try again later.';
        case 'operation-not-allowed':
          return 'This operation is not allowed.';
        default:
          return error.message ?? 'An authentication error occurred.';
      }
    }
    return error.toString();
  }
}


