import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../auth/auth_check.dart';
import '../providers/user_provider.dart';

class ProfileManagementPage extends StatefulWidget {
  const ProfileManagementPage({super.key});

  @override
  _ProfileManagementPageState createState() => _ProfileManagementPageState();
}

class _ProfileManagementPageState extends State<ProfileManagementPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  // Email is read-only, no need for a controller unless displaying it
  final _oldPasswordController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _selectedRole;
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      _nameController.text = userProvider.name ?? '';
      // Assuming email is displayed elsewhere or can be fetched directly from provider
      _selectedRole = userProvider.role;
    });
  }

  // Future<bool> _requestPermissions() async {
  //   final status = await Permission.photos.request();
  //   return status == PermissionStatus.granted;
  // }

  Future<void> _pickImage() async {
    // final hasPermission = await _requestPermissions();
    // if (!hasPermission) {
    //   throw Exception('Gallery permission not granted');
    // }
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profile Management'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await userProvider.signOutUser();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AuthCheck()),
                );
              },
            ),
          ],
        ),
        body: userProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: _imageFile != null
                              ? FileImage(_imageFile!)
                              : (userProvider.profileImageUrl != null
                                  ? NetworkImage(userProvider.profileImageUrl!)
                                  : null),
                          child: _imageFile == null &&
                                  userProvider.profileImageUrl == null
                              ? const Icon(Icons.person, size: 50)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Name'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        readOnly: true,
                        initialValue: userProvider.email,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          enabled: false,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                            labelText: 'New Password (optional)'),
                        obscureText: true,
                        validator: (value) {
                          if (value != null &&
                              value.isNotEmpty &&
                              value.length < 6) {
                            return 'Password must be at least 6 characters long';
                          }
                          if (value != null &&
                              value.isNotEmpty &&
                              _confirmPasswordController.text.isNotEmpty &&
                              value == _oldPasswordController.text) {
                            return 'New password must be different from current password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      if (_passwordController.text.isNotEmpty)
                        TextFormField(
                          controller: _confirmPasswordController,
                          decoration: const InputDecoration(
                            labelText: 'Confirm New Password',
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                      if (_passwordController.text.isNotEmpty)
                        const SizedBox(height: 10),
                      if (_passwordController.text.isNotEmpty)
                        TextFormField(
                          controller: _oldPasswordController,
                          decoration: const InputDecoration(
                            labelText: 'Current Password',
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your current password';
                            }

                            return null;
                          },
                        ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: _selectedRole,
                        decoration: const InputDecoration(labelText: 'Role'),
                        items: ['Student', 'Teacher']
                            .map((role) => DropdownMenuItem(
                                value: role, child: Text(role)))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a role';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: userProvider.isLoading
                            ? null
                            : () async {
                                if (_formKey.currentState!.validate()) {
                                  await userProvider.updateProfile(
                                    newName: _nameController.text,
                                    currentPassword:
                                        _oldPasswordController.text.isNotEmpty
                                            ? _oldPasswordController.text
                                            : null,
                                    newPassword:
                                        _passwordController.text.isNotEmpty
                                            ? _passwordController.text
                                            : null,
                                    newRole: _selectedRole,
                                    newProfileImage: _imageFile,
                                  );
                                  // Optionally, clear password fields
                                  _passwordController.clear();
                                  _confirmPasswordController.clear();
                                  setState(() {
                                    _imageFile = null;
                                  });
                                }
                              },
                        child: userProvider.isLoading
                            ? const CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              )
                            : const Text('Update Profile'),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _oldPasswordController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
