import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../components/custom_text_field.dart';
import '../components/custom_button.dart';

class UpdatePasswordScreen extends StatefulWidget {
  const UpdatePasswordScreen({super.key});

  @override
  State<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<UpdatePasswordScreen> {
  final TextEditingController currentPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  bool isLoading = false;

  void updatePassword() async {
    String currentPassword = currentPasswordController.text;
    String newPassword = newPasswordController.text;
    String confirmPassword = confirmPasswordController.text;

    if (currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      Fluttertoast.showToast(msg: "Please fill all fields", backgroundColor: const Color(0xFF43302E), textColor: const Color(0xFFFFF1B5));
      return;
    }

    if (newPassword != confirmPassword) {
      Fluttertoast.showToast(msg: "New passwords do not match", backgroundColor: const Color(0xFF43302E), textColor: const Color(0xFFFFF1B5));
      return;
    }

    setState(() => isLoading = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null && user.email != null) {
        // Re-authenticate user
        AuthCredential credential = EmailAuthProvider.credential(email: user.email!, password: currentPassword);
        await user.reauthenticateWithCredential(credential);
        
        // Update password
        await user.updatePassword(newPassword);
        
        Fluttertoast.showToast(msg: "Password updated successfully!", backgroundColor: const Color(0xFF43302E), textColor: const Color(0xFFFFF1B5));
        if (mounted) Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        Fluttertoast.showToast(msg: "Incorrect current password", backgroundColor: Colors.red);
      } else {
        Fluttertoast.showToast(msg: "Error updating password", backgroundColor: Colors.red);
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color textColor = isDark ? Colors.white : const Color(0xFF43302E);

    return Scaffold(
      appBar: AppBar(
        title: Text('Update Password', style: TextStyle(color: textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current Password', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              CustomTextField(
                hintText: 'Enter your current password',
                icon: Icons.lock_outline,
                controller: currentPasswordController,
                isPassword: true,
              ),
              const SizedBox(height: 16),
              Text('New Password', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              CustomTextField(
                hintText: 'Enter your new password',
                icon: Icons.lock_outline,
                controller: newPasswordController,
                isPassword: true,
              ),
              const SizedBox(height: 16),
              Text('Confirm New Password', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              CustomTextField(
                hintText: 'Confirm your new password',
                icon: Icons.lock_outline,
                controller: confirmPasswordController,
                isPassword: true,
              ),
              const SizedBox(height: 30),
              isLoading 
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF43302E)))
                  : CustomButton(
                      text: 'Update Password',
                      onPressed: updatePassword,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
