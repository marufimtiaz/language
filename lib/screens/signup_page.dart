import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_check.dart';
import '../components/my_button.dart';
import '../components/textfield.dart';
import '../providers/user_provider.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    Future<void> signup() async {
      if (_formKey.currentState!.validate()) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });

        try {
          String? result = await userProvider.signupUserWithEmail(
            _nameController.text.trim(),
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );

          if (result != 'success') {
            setState(() {
              _errorMessage = result;
            });
          } else {
            print("Login successful in LoginPage");
            // Force a rebuild of the widget tree
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AuthCheck()),
            );
          }
          // Successful signup is handled by AuthCheck
        } catch (e) {
          setState(() {
            _errorMessage = 'An error occurred. Please try again later.';
          });
        } finally {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }

    Future<void> handleGoogleSignIn() async {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        String? result = await userProvider.signInWithGoogle();

        if (!mounted) return; // Check if widget is still mounted

        if (mounted) {
          if (result != 'success') {
            setState(() {
              _errorMessage = result;
            });
          } else {
            print("Login successful in LoginPage");
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AuthCheck()),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = 'An error occurred. Please try again later.';
          });
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }

    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: screenHeight * 0.05),
                const Text(
                  'Sign Up',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: screenHeight * 0.05),
                CustomTextField(
                  controller: _nameController,
                  labelText: 'Username',
                  hintText: 'Enter your username here',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: screenHeight * 0.02),
                CustomTextField(
                  controller: _emailController,
                  labelText: 'Email',
                  hintText: 'Enter your email here',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                SizedBox(height: screenHeight * 0.02),
                CustomTextField(
                  controller: _passwordController,
                  labelText: 'Password',
                  hintText: 'Enter new password',
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters long';
                    }
                    return null;
                  },
                ),
                SizedBox(height: screenHeight * 0.02),
                CustomTextField(
                  controller: _confirmPasswordController,
                  labelText: 'Confirm Password',
                  hintText: 'Enter password again',
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                SizedBox(height: screenHeight * 0.04),
                CustomButton(
                  isLoading: _isLoading,
                  label: 'Sign Up',
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  textColor: Colors.white,
                  onPressed: signup,
                ),
                SizedBox(height: screenHeight * 0.02),
                SizedBox(height: screenHeight * 0.02),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account? "),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        "Sign In",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  ],
                ),
                SizedBox(height: screenHeight * 0.04),
                Divider(
                  color: Theme.of(context).colorScheme.secondary,
                ),
                SizedBox(height: screenHeight * 0.04),
                Column(
                  children: [
                    CustomButton(
                      isLoading: _isLoading,
                      label: 'Sign in with Google',
                      image: Image.asset(
                        'assets/g.png',
                        scale: 5,
                      ),
                      backgroundColor: Colors.white,
                      textColor: Colors.black,
                      borderColor: Colors.grey,
                      onPressed:
                          // Handle Google sign in button press
                          handleGoogleSignIn,
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    CustomButton(
                      isLoading: _isLoading,
                      label: 'Sign in with Apple',
                      icon: Icons.apple,
                      backgroundColor: Colors.white,
                      textColor: Colors.black,
                      borderColor: Colors.grey,
                      onPressed:
                          // Handle Apple sign in button press
                          handleGoogleSignIn,
                    ),
                  ],
                ),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
