import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:language/providers/user_provider.dart';
import 'package:language/screens/role_selection_page.dart';
import 'package:language/screens/homepage.dart';
import 'package:language/screens/login_page.dart';

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    print("AuthCheck build method called");
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        print("StreamBuilder rebuild - Auth state changed");
        if (snapshot.connectionState == ConnectionState.active) {
          User? user = snapshot.data;
          if (user == null) {
            print("User is null, returning LoginPage");
            return const LoginPage();
          }
          return FutureBuilder(
            future: _updateUserProvider(context, user),
            builder: (context, _) {
              return Consumer<UserProvider>(
                builder: (context, userProvider, _) {
                  print(
                      "Consumer rebuild - UserProvider: ${userProvider.user?.uid}, Role: ${userProvider.role}");
                  if (userProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (userProvider.role == null) {
                    print("User role is null, returning RoleSelectionPage");
                    return const RoleSelectionPage();
                  } else {
                    print("User role is set, returning Homepage");
                    return const Homepage();
                  }
                },
              );
            },
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Future<void> _updateUserProvider(BuildContext context, User? user) async {
    print("_updateUserProvider called with user: ${user?.uid}");
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.setUser(user);
  }
}
