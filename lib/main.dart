import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SweetBakeApp());
}

// Root widget of SweetBake application
class SweetBakeApp extends StatelessWidget {
  const SweetBakeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SweetBake',
      debugShowCheckedModeBanner: false,
      // Light Theme configuration matching inspo UI
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFFF9DB),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF0F5F9),
          primary: const Color(0xFFF0F5F9),
        ),
      ),
      // System Dark Theme configuration
      darkTheme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF0F5F9),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system, // Supports both Light and Dark mode based on device setting
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // While checking auth state, show a loading spinner
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Color(0xFFFFF9DB),
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF43302E)),
              ),
            );
          }
          
          // If user is already logged in, go straight to home
          if (snapshot.hasData) {
            return const MainNavigation();
          }
          
          // Otherwise, show the Login Screen
          return const LoginScreen();
        },
      ),
    );
  }
}
