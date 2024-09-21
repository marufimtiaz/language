import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:language/screens/homepage.dart';
import 'package:provider/provider.dart';
import '../auth/auth_check.dart';
import '../auth/auth_service.dart';
import '../auth/user_provider.dart';
import '../components/selectors.dart';
import 'login_page.dart';

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  String? _selectedRole;

  void _selectRole(String role) {
    setState(() {
      _selectedRole = role;
    });
  }

  Future<void> _confirmSelection() async {
    if (_selectedRole != null) {
      var user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
            'role': _selectedRole,
          });

          // Update the role in the provider
          final userProvider =
              Provider.of<UserProvider>(context, listen: false);
          userProvider.updateUserRole(_selectedRole!);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Homepage()),
          );
        } catch (e) {
          Fluttertoast.showToast(msg: "Error updating role: $e");
        }
      } else {
        Fluttertoast.showToast(msg: "Error: No user found");
      }
    } else {
      Fluttertoast.showToast(msg: "Please select a role");
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Your Role"),
        actions: [
          IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await signOutUser(context); // Call sign-out function
                // Redirect to login page
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AuthCheck()),
                );
              }),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Select Your Role", style: TextStyle(fontSize: 24)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ChoiceCard(
                    icon: Icons.person,
                    text: 'Student',
                    color: _selectedRole == 'Student'
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                    borderColor: _selectedRole == 'Student'
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                    onTap: () => _selectRole('Student'),
                  ),
                ),
                SizedBox(width: screenWidth * 0.05),
                Expanded(
                  child: ChoiceCard(
                    icon: Icons.school,
                    text: 'Teacher',
                    color: _selectedRole == 'Teacher'
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                    borderColor: _selectedRole == 'Teacher'
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                    onTap: () => _selectRole('Teacher'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _confirmSelection,
              child: const Text("Confirm"),
            ),
          ],
        ),
      ),
    );
  }
}
