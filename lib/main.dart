import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:language/screens/homepage.dart';
import 'package:language/screens/login_page.dart';
import 'package:provider/provider.dart';
import 'auth/auth_check.dart';
import 'firebase_options.dart';
import 'screens/profile.dart';
import 'screens/role_selection_page.dart';
import 'auth/user_provider.dart';
import 'screens/signup_page.dart';
import 'theme/light_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserProvider(),
      child: MaterialApp(
        title: 'E-Learning App',
        theme: AppTheme.lightTheme,
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthCheck(),
          '/loginpage': (context) => const LoginPage(),
          '/signuppage': (context) => const SignupPage(),
          '/homepage': (context) => const Homepage(),
          '/profile': (context) => const ProfilePage(),
          '/teacherHomepage': (context) => const TeacherHomepage(),
          '/studentHomepage': (context) => const StudentHomepage(),
          // '/createClass': (context) => const CreateClassPage(),
          // '/joinClass': (context) => JoinClassPage(),
          '/roleSelection': (context) => const RoleSelectionPage(),
        },
      ),
    );
  }
}
