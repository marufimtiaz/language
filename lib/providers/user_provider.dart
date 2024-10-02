import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_storage/firebase_storage.dart';

class UserProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  User? _user;
  String? _id;
  String? _role;
  String? _name;
  String? _email;
  String? _profileImageUrl;
  bool _isLoading = false;

  User? get user => _user;
  String? get userId => _id;
  String? get role => _role;
  String? get name => _name;
  String? get email => _email;
  String? get profileImageUrl => _profileImageUrl;
  bool get isLoading => _isLoading;

  Future<void> setUser(User? user) async {
    _isLoading = true;
    // notifyListeners();

    _user = user;
    if (user != null) {
      await _fetchUserData();
    } else {
      _clearUserData();
    }

    _isLoading = false;
    notifyListeners();
  }

  void _clearUserData() {
    _id = null;
    _role = null;
    _name = null;
    _email = null;
    _profileImageUrl = null;
  }

  Future<void> _fetchUserData() async {
    if (_user != null) {
      try {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(_user!.uid).get();
        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;
          if (userData['id'] == null) {
            await _firestore.collection('users').doc(_user!.uid).update({
              'id': _user!.uid,
            });
          }
          if (userData['profileImageUrl'] == null) {
            await _firestore.collection('users').doc(_user!.uid).update({
              'profileImageUrl':
                  'https://firebasestorage.googleapis.com/v0/b/language-flutter.appspot.com/o/profile_images%2Fdefault.png?alt=media&token=f3660a54-12b1-4145-bb8d-f9972a00f46e',
            });
          }
          _id = _user!.uid;
          _role = userData['role'] as String?;
          _name = userData['name'] as String?;
          _email = userData['email'] as String?;
          _profileImageUrl = userData['profileImageUrl'] as String?;
        }
      } catch (e) {
        print('Error fetching user data: $e');
      }
    }
  }

  Future<String?> loginUserWithEmail(String email, String password) async {
    try {
      _isLoading = true;
      // notifyListeners();

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await setUser(userCredential.user);
      return 'success';
    } catch (e) {
      Fluttertoast.showToast(msg: "Login Failed: $e");
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> signupUserWithEmail(
      String name, String email, String password) async {
    try {
      _isLoading = true;
      // notifyListeners();

      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('users').doc(userCredential.user?.uid).set({
        'id': userCredential.user?.uid,
        'name': name,
        'email': email,
        'role': null,
        'profileImageUrl':
            'https://firebasestorage.googleapis.com/v0/b/language-flutter.appspot.com/o/profile_images%2Fdefault.png?alt=media&token=f3660a54-12b1-4145-bb8d-f9972a00f46e',
      });

      await setUser(userCredential.user);
      return 'success';
    } catch (e) {
      Fluttertoast.showToast(msg: "Signup Failed: $e");
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> signInWithGoogle() async {
    try {
      _isLoading = true;
      // notifyListeners();

      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user?.uid)
          .get();

      if (!userDoc.exists) {
        await _firestore.collection('users').doc(userCredential.user?.uid).set({
          'id': userCredential.user?.uid,
          'name': userCredential.user?.displayName ?? 'Anonymous',
          'email': userCredential.user?.email,
          'role': null,
          'profileImageUrl': userCredential.user?.photoURL ??
              'https://firebasestorage.googleapis.com/v0/b/language-flutter.appspot.com/o/profile_images%2Fdefault.png?alt=media&token=f3660a54-12b1-4145-bb8d-f9972a00f46e',
        });
      }

      await setUser(userCredential.user);
      return 'success';
    } catch (e) {
      Fluttertoast.showToast(msg: "Google Sign-In Failed: $e");
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOutUser() async {
    try {
      _isLoading = true;
      // notifyListeners();

      await _auth.signOut();
      await setUser(null);
    } catch (e) {
      Fluttertoast.showToast(msg: "Sign out error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile({
    String? newName,
    String? currentPassword,
    String? newPassword,
    String? newRole,
    File? newProfileImage,
  }) async {
    if (_user == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      Map<String, dynamic> updates = {};

      if (newName != null && newName != _name) {
        updates['name'] = newName;
        _name = newName;
      }

      if (newPassword != null && currentPassword != null) {
        // Reauthenticate the user with their old password
        final credential = EmailAuthProvider.credential(
          email: email!,
          password: currentPassword,
        );
        await user?.reauthenticateWithCredential(credential);
        await _user!.updatePassword(newPassword);
      }

      if (newRole != null && newRole != _role) {
        updates['role'] = newRole;
        _role = newRole;
      }

      if (newProfileImage != null) {
        String imageUrl = await uploadProfileImage(newProfileImage);
        updates['profileImageUrl'] = imageUrl;
        _profileImageUrl = imageUrl;
      }

      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(_user!.uid).update(updates);
      }

      Fluttertoast.showToast(msg: "Profile updated successfully");
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to update profile: $e");
      print('Error updating user profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> uploadProfileImage(File imageFile) async {
    String fileName =
        'profile_${_user!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    Reference storageRef = _storage.ref().child('profile_images/$fileName');
    UploadTask uploadTask = storageRef.putFile(imageFile);
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> updateUserRole(String newRole) async {
    if (_user != null) {
      try {
        _isLoading = true;
        // notifyListeners();

        await _firestore
            .collection('users')
            .doc(_user!.uid)
            .update({'role': newRole});
        _role = newRole;
      } catch (e) {
        print('Error updating user role: $e');
        Fluttertoast.showToast(msg: "Failed to update role: $e");
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }
  }
}
