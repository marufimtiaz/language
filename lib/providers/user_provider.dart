import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:language/utils/ui_utils.dart';

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
                  'https://firebasestorage.googleapis.com/v0/b/language-flutter.appspot.com/o/profile_images%2Fdefault.png?alt=media&token=471db6ef-440e-47c1-b96b-cb5451255192',
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

  String _handleAuthError(String code) {
    switch (code) {
      case 'claims-too-large':
        return 'The account settings are too large to update. Please reduce the size of custom claims.';
      case 'email-already-exists':
        return 'This email is already registered. Please use a different email.';
      case 'id-token-expired':
        return 'Your session has expired. Please log in again.';
      case 'id-token-revoked':
        return 'Your session was revoked. Please log in again.';
      case 'insufficient-permission':
        return 'You do not have permission to perform this action.';
      case 'internal-error':
        return 'An internal error occurred. Please try again later.';
      case 'invalid-argument':
        return 'An invalid argument was provided for the authentication request.';
      case 'invalid-claims':
        return 'The custom claim attributes provided are invalid.';
      case 'invalid-continue-uri':
        return 'The provided continue URL is invalid.';
      case 'invalid-creation-time':
        return 'The account creation time must be a valid UTC date string.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'invalid-disabled-field':
        return 'The disabled property value is invalid. It must be a boolean.';
      case 'invalid-display-name':
        return 'The provided display name is invalid. It must be a non-empty string.';
      case 'invalid-dynamic-link-domain':
        return 'The provided dynamic link domain is not configured or authorized for this project.';
      case 'invalid-email':
        return 'The provided email is invalid.';
      case 'invalid-email-verified':
        return 'The emailVerified property must be a boolean.';
      case 'invalid-hash-algorithm':
        return 'The hash algorithm must be one of the supported types.';
      case 'invalid-hash-block-size':
        return 'The hash block size must be a valid number.';
      case 'invalid-hash-derived-key-length':
        return 'The hash derived key length must be a valid number.';
      case 'invalid-hash-key':
        return 'The hash key must be a valid byte buffer.';
      case 'invalid-hash-memory-cost':
        return 'The hash memory cost must be a valid number.';
      case 'invalid-hash-parallelization':
        return 'The hash parallelization must be a valid number.';
      case 'invalid-hash-rounds':
        return 'The hash rounds must be a valid number.';
      case 'invalid-hash-salt-separator':
        return 'The salt separator must be a valid byte buffer.';
      case 'invalid-id-token':
        return 'The provided ID token is not a valid Firebase ID token.';
      case 'invalid-last-sign-in-time':
        return 'The last sign-in time must be a valid UTC date string.';
      case 'invalid-page-token':
        return 'The next page token provided is invalid.';
      case 'invalid-password':
        return 'The provided password is invalid. It must be at least six characters.';
      case 'invalid-password-hash':
        return 'The password hash must be a valid byte buffer.';
      case 'invalid-password-salt':
        return 'The password salt must be a valid byte buffer.';
      case 'invalid-phone-number':
        return 'The phone number provided is invalid. It must be a valid E.164 format.';
      case 'invalid-photo-url':
        return 'The photo URL must be a valid string URL.';
      case 'invalid-provider-data':
        return 'The providerData must be a valid array of UserInfo objects.';
      case 'invalid-provider-id':
        return 'The provider ID must be a valid supported provider identifier.';
      case 'invalid-oauth-responsetype':
        return 'Only one OAuth responseType can be set to true.';
      case 'invalid-session-cookie-duration':
        return 'The session cookie duration must be a valid number between 5 minutes and 2 weeks.';
      case 'invalid-uid':
        return 'The provided UID must be a non-empty string with at most 128 characters.';
      case 'invalid-user-import':
        return 'The user record provided for import is invalid.';
      case 'maximum-user-count-exceeded':
        return 'The maximum allowed number of users to import has been exceeded.';
      case 'missing-android-pkg-name':
        return 'An Android package name must be provided if the Android app is required to be installed.';
      case 'missing-continue-uri':
        return 'A valid continue URL must be provided in the request.';
      case 'missing-hash-algorithm':
        return 'Importing users with password hashes requires the hashing algorithm and parameters.';
      case 'missing-ios-bundle-id':
        return 'A Bundle ID must be provided for the iOS app.';
      case 'missing-uid':
        return 'A UID identifier is required for this operation.';
      case 'missing-oauth-client-secret':
        return 'The OAuth client secret is required to enable OIDC code flow.';
      case 'operation-not-allowed':
        return 'The provided sign-in provider is disabled for your Firebase project.';
      case 'phone-number-already-exists':
        return 'This phone number is already in use by an existing user.';
      case 'project-not-found':
        return 'No Firebase project was found for the credentials provided.';
      case 'reserved-claims':
        return 'One or more custom claims provided are reserved and cannot be used.';
      case 'session-cookie-expired':
        return 'The session cookie has expired.';
      case 'session-cookie-revoked':
        return 'The session cookie has been revoked.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'uid-already-exists':
        return 'The provided UID is already in use by another user.';
      case 'unauthorized-continue-uri':
        return 'The domain of the continue URL is not whitelisted in the Firebase project.';
      case 'user-not-found':
        return 'No user found with the provided identifier.';
      default:
        return code;
    }
  }

  Future<String?> loginUserWithEmail(String email, String password) async {
    try {
      _isLoading = true;
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await setUser(userCredential.user);
      return 'success';
    } on FirebaseAuthException catch (e) {
      String errorMessage = _handleAuthError(e.code);
      UIUtils.showToast(msg: errorMessage);
      return errorMessage;
    } catch (e) {
      UIUtils.showToast(msg: "Login Failed: $e");
      return "Login Failed: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> signupUserWithEmail(
      String name, String email, String password) async {
    try {
      _isLoading = true;
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
            'https://firebasestorage.googleapis.com/v0/b/language-flutter.appspot.com/o/profile_images%2Fdefault.png?alt=media&token=471db6ef-440e-47c1-b96b-cb5451255192',
      });

      await setUser(userCredential.user);
      return 'success';
    } on FirebaseAuthException catch (e) {
      String errorMessage = _handleAuthError(e.code);
      UIUtils.showToast(msg: errorMessage);
      return errorMessage;
    } catch (e) {
      UIUtils.showToast(msg: "Signup Failed: $e");
      return "Signup Failed: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> signInWithGoogle() async {
    try {
      _isLoading = true;
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
              'https://firebasestorage.googleapis.com/v0/b/language-flutter.appspot.com/o/profile_images%2Fdefault.png?alt=media&token=471db6ef-440e-47c1-b96b-cb5451255192',
        });
      }

      await setUser(userCredential.user);
      return 'success';
    } on FirebaseAuthException catch (e) {
      String errorMessage = _handleAuthError(e.code);
      UIUtils.showToast(msg: errorMessage);
      return errorMessage;
    } catch (e) {
      UIUtils.showToast(msg: "Google Sign-In Failed: $e");
      return 'Google Sign-In Failed: $e';
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
      UIUtils.showToast(msg: "Sign out error: $e");
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
        try {
          // Reauthenticate the user with their old password
          final credential = EmailAuthProvider.credential(
            email: email!,
            password: currentPassword,
          );
          await user?.reauthenticateWithCredential(credential);
          await _user!.updatePassword(newPassword);
        } on FirebaseAuthException catch (e) {
          String errorMessage = _handleAuthError(e.code);
          throw Exception(errorMessage);
        }
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

      UIUtils.showToast(msg: "Profile updated successfully");
    } catch (e) {
      UIUtils.showToast(msg: "Failed to update profile: $e");
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
        UIUtils.showToast(msg: "Failed to update role: $e");
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }
  }
}
