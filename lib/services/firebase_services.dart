import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

// Login user with email and password
  Future<String?> loginUserWithEmail(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return 'success'; // Return success to indicate the login was successful
    } catch (e) {
      Fluttertoast.showToast(msg: "Login Failed: $e");
      return null; // Return null on failure
    }
  }

  Future<String?> signupUserWithEmail(
      String name, String email, String password) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore with the role (role is initially null or can be set to 'student')
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user?.uid)
          .set({
        'name': name,
        'email': email,
        'role': null, // or another default role
      });

      return 'success'; // Return success to indicate the signup was successful
    } catch (e) {
      Fluttertoast.showToast(msg: "Signup Failed: $e");
      return null; // Return null on failure
    }
  }

  Future<String?> signInWithGoogle() async {
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
          await _auth.signInWithCredential(credential);

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

      return 'success'; // Return success to indicate the sign-in was successful
    } catch (e) {
      Fluttertoast.showToast(msg: "Google Sign-In Failed: $e");
      return null; // Return null on failure
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
      Fluttertoast.showToast(msg: "Error fetching user role: $e");
      return null;
    }
  }

  Future<void> signOutUser() async {
    try {
      await _auth.signOut();
    } catch (e) {
      // Handle sign-out errors if needed
      Fluttertoast.showToast(msg: "Sign out error: $e");
    }
  }

  Future<void> createUserDocument(User user, String? name) async {
    await _firestore.collection('users').doc(user.uid).set({
      'name': name ?? user.displayName ?? 'Anonymous',
      'email': user.email,
      'role': null,
    });
  }

  Future<void> updateUserRole(String uid, String role) async {
    await _firestore.collection('users').doc(uid).update({'role': role});
  }

  Future<void> updateUserDocument(String uid, String name) async {
    await _firestore.collection('users').doc(uid).update({
      'name': name,
    });
  }

  Future<DocumentSnapshot> getUserDocument(String uid) async {
    return await _firestore.collection('users').doc(uid).get();
  }

  Future<void> createClass(
      String name, String teacherEmail, String dateEnd) async {
    String classId = _firestore.collection('classes').doc().id;
    await _firestore.collection('classes').doc(classId).set({
      'name': name,
      'teacherEmail': teacherEmail,
      'dateEnd': dateEnd,
      'classId': classId,
      'studentEmails': [],
    });
  }

  Future<void> joinClass(String classId, String studentEmail) async {
    await _firestore.collection('classes').doc(classId).update({
      'studentEmails': FieldValue.arrayUnion([studentEmail]),
    });
  }

  Stream<QuerySnapshot> getTeacherClasses(String teacherEmail) {
    return _firestore
        .collection('classes')
        .where('teacherEmail', isEqualTo: teacherEmail)
        .snapshots();
  }

  Stream<QuerySnapshot> getStudentClasses(String studentEmail) {
    return _firestore
        .collection('classes')
        .where('studentEmails', arrayContains: studentEmail)
        .snapshots();
  }
}
