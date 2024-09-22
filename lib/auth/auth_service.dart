import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:language/providers/user_provider.dart';

// Login user with email and password
Future<String?> loginUserWithEmail(
    String email, String password, BuildContext context) async {
  try {
    UserCredential userCredential =
        await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Update UserProvider
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.setUser(userCredential.user);

    print("Login successful, UserProvider updated");
    return 'success';
  } catch (e) {
    print("Login failed: $e");
    Fluttertoast.showToast(msg: "Login Failed: $e");
    return null;
  }
}

// Sign up user with email and password
Future<String?> signupUserWithEmail(
    String name, String email, String password, BuildContext context) async {
  try {
    UserCredential userCredential =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Create user document in Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userCredential.user?.uid)
        .set({
      'name': name,
      'email': email,
      'role': null, // or another default role
    });

    // Update UserProvider
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.setUser(userCredential.user);

    print("Signup successful, UserProvider updated");
    return 'success';
  } catch (e) {
    print("Signup failed: $e");
    Fluttertoast.showToast(msg: "Signup Failed: $e");
    return null;
  }
}

// Sign in with Google
Future<String?> signInWithGoogle(BuildContext context) async {
  try {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      return null; // The user canceled the sign-in
    }
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Sign in to Firebase with the Google credential
    UserCredential userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);

    // Check if user already exists in Firestore
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userCredential.user?.uid)
        .get();

    if (!userDoc.exists) {
      // Create a new user document if it doesn't exist
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user?.uid)
          .set({
        'name': userCredential.user?.displayName ?? 'Anonymous',
        'email': userCredential.user?.email,
        'role': null, // Set role to null for new users
      });
    }

    // Update UserProvider
    // Wrap this in a try-catch block to handle potential errors
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.setUser(userCredential.user);
      print("Google Sign-In successful, UserProvider updated");
    } catch (e) {
      print("Failed to update UserProvider: $e");
      // The widget might have been disposed, but the sign-in was successful
    }

    return 'success';
  } catch (e) {
    print("Google Sign-In failed: $e");
    Fluttertoast.showToast(msg: "Google Sign-In Failed: $e");
    return null;
  }
}

// Fetch user role from Firestore and return it
Future<String?> getUserRole(String uid) async {
  try {
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (userDoc.exists) {
      return userDoc['role']; // Return the user role
    } else {
      Fluttertoast.showToast(msg: "Error: User document does not exist.");
      return null;
    }
  } catch (e) {
    print("Error fetching user role: $e");
    Fluttertoast.showToast(msg: "Error fetching user role: $e");
    return null;
  }
}

// Sign out user
Future<void> signOutUser(BuildContext context) async {
  try {
    await FirebaseAuth.instance.signOut();

    // Clear UserProvider
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.setUser(null);

    print("Sign out successful, UserProvider cleared");
  } catch (e) {
    print("Sign out error: $e");
    Fluttertoast.showToast(msg: "Sign out error: $e");
  }
}
