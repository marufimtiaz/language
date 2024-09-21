import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:language/auth/user_provider.dart';
import 'package:language/screens/role_selection_page.dart';
import 'package:language/screens/homepage.dart';
import 'package:language/screens/login_page.dart';

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);

        if (snapshot.connectionState == ConnectionState.active) {
          User? user = snapshot.data;

          // Update the UserProvider
          WidgetsBinding.instance.addPostFrameCallback((_) {
            userProvider.setUser(user);
          });

          if (user == null) {
            return const LoginPage();
          }

          return Consumer<UserProvider>(
            builder: (context, userProvider, _) {
              if (userProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (userProvider.role != null) {
                return Homepage();
              } else {
                return const RoleSelectionPage();
              }
            },
          );
        }

        // Show loading indicator while the stream is not yet ready
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
