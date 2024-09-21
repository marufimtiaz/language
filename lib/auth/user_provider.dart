import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProvider extends ChangeNotifier {
  User? _user;
  String? _role;
  String? _name;
  String? _email;
  bool _isLoading = true;

  User? get user => _user;
  String? get userId => _user?.uid; // New getter for user ID
  String? get role => _role;
  String? get name => _name;
  String? get email => _email;
  bool get isLoading => _isLoading;

  Future<void> setUser(User? user) async {
    print("setUser called with user: ${user?.uid}");
    if (_user?.uid != user?.uid) {
      _user = user;
      _isLoading = true;
      notifyListeners();
      print("Notified listeners after setting _isLoading to true");
      if (user != null) {
        await _fetchUserData();
      } else {
        _role = null;
        _name = null;
        _email = null;
        print("User is null, cleared user data");
      }
      _isLoading = false;
      notifyListeners();
      print("Notified listeners after setting _isLoading to false");
    } else {
      print("User ID unchanged, not updating");
    }
  }

  Future<void> _fetchUserData() async {
    print("_fetchUserData called");
    if (_user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .get();
        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;
          _role = userData['role'] as String?;
          _name = userData['name'] as String?;
          _email = userData['email'] as String?;
          print(
              "Fetched user data - Role: $_role, Name: $_name, Email: $_email");
        } else {
          print('User document does not exist for UID: ${_user!.uid}');
        }
      } catch (e) {
        print('Error fetching user data: $e');
      }
    }
  }

  Future<void> updateUserName(String newName) async {
    if (_user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .update({'name': newName});
        _name = newName;
        notifyListeners();
      } catch (e) {
        print('Error updating user name: $e');
        rethrow;
      }
    }
  }

  Future<void> updateUserRole(String newRole) async {
    if (_user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .update({'role': newRole});
        _role = newRole;
        notifyListeners();
      } catch (e) {
        print('Error updating user role: $e');
        rethrow;
      }
    }
  }
}
