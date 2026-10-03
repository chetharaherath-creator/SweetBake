import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../components/custom_text_field.dart';
import '../components/custom_button.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Register Screen widget
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Input controllers for the registration form
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();

  // Booleans to toggle password visibility
  bool hidePassword = true;
  bool hideConfirmPassword = true;

  // Function to register a new user
  Future<void> registerUser() async {
    String name = nameController.text.trim();
    String email = emailController.text.trim();
    String password = passwordController.text;
    String confirmPassword = confirmPasswordController.text;

    // Check if any field is empty
    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      Fluttertoast.showToast(
        msg: "Please fill in all fields",
        backgroundColor: const Color(0xFF43302E), textColor: const Color(0xFFFFF1B5), webBgColor: "#43302E");
      return;
    }

    // Check if passwords match
    if (password != confirmPassword) {
      Fluttertoast.showToast(
        msg: "Passwords do not match",
        backgroundColor: const Color(0xFF43302E), textColor: const Color(0xFFFFF1B5), webBgColor: "#43302E");
      return;
    }

    try {
      // Create user with Firebase Auth
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Success toast
      Fluttertoast.showToast(
        msg: "Account created for $name!",
        backgroundColor: const Color(0xFF43302E), textColor: const Color(0xFFFFF1B5), webBgColor: "#43302E");

      // Navigate back to Login screen if context is still valid
      if (mounted) {
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Registration failed";
      if (e.code == 'weak-password') {
        errorMessage = "The password provided is too weak.";
      } else if (e.code == 'email-already-in-use') {
        errorMessage = "An account already exists for that email.";
      }
      
      Fluttertoast.showToast(
        msg: errorMessage,
        backgroundColor: const Color(0xFF43302E), textColor: const Color(0xFFFFF1B5), webBgColor: "#43302E");
    } catch (e) {
      Fluttertoast.showToast(
        msg: "An unexpected error occurred.",
        backgroundColor: const Color(0xFF43302E), textColor: const Color(0xFFFFF1B5), webBgColor: "#43302E");
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color primaryText = isDark ? Colors.white : const Color(0xFF43302E);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryText),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: ListView(
            children: [
              // Cake Icon Header
              Icon(
                Icons.cake_rounded,
                size: 60,
                color: primaryText,
              ),

              const SizedBox(height: 10),

              // App Title
              Text(
                'SweetBake',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: primaryText,
                ),
              ),

              const Text(
                'BAKE. SHARE. ENJOY.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),

              const SizedBox(height: 30),

              // Create Account Header
              const Text(
                'Create Account',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const Text(
                'Join SweetBake and start sharing recipes',
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 20),

              // Full Name Field
              CustomTextField(
                hintText: 'Full Name',
                icon: Icons.person,
                controller: nameController,
              ),

              // Email Field
              CustomTextField(
                hintText: 'Email',
                icon: Icons.email,
                controller: emailController,
              ),

              // Password Field
              CustomTextField(
                hintText: 'Password',
                icon: Icons.lock,
                controller: passwordController,
                isPassword: hidePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    hidePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      hidePassword = !hidePassword;
                    });
                  },
                ),
              ),

              // Confirm Password Field
              CustomTextField(
                hintText: 'Confirm Password',
                icon: Icons.lock_outline,
                controller: confirmPasswordController,
                isPassword: hideConfirmPassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    hideConfirmPassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      hideConfirmPassword = !hideConfirmPassword;
                    });
                  },
                ),
              ),

              const SizedBox(height: 10),

              // Sign Up Button
              CustomButton(
                text: 'Sign Up',
                onPressed: registerUser,
              ),

              const SizedBox(height: 20),

              // Already have an account? Login row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account? "),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context); // Go back to Login Screen
                    },
                    child: Text(
                      'Login',
                      style: TextStyle(
                        color: primaryText,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
