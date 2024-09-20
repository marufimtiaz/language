import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:language/auth/user_provider.dart';
import 'package:language/utils/ui_utils.dart';
import '../services/firebase_services.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _nameController = TextEditingController(text: userProvider.name);
    _emailController = TextEditingController(text: userProvider.email);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              setState(() {
                if (_isEditing) {
                  if (_formKey.currentState!.validate()) {
                    _saveProfile();
                  }
                } else {
                  _isEditing = true;
                }
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                enabled: _isEditing,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                enabled: false,
              ),
              const SizedBox(height: 16),
              Text('Role: ${userProvider.role ?? 'Not set'}'),
            ],
          ),
        ),
      ),
    );
  }

  void _saveProfile() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final firebaseService = FirebaseService();

    try {
      await firebaseService.updateUserDocument(
        userProvider.user!.uid,
        _nameController.text,
      );

      userProvider.updateUserName(_nameController.text);

      setState(() {
        _isEditing = false;
      });

      UIUtils.showToast('Profile updated successfully');
    } catch (e) {
      UIUtils.showErrorDialog(context, 'Error', 'Failed to update profile: $e');
    }
  }
}
