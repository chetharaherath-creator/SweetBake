import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart';
import 'update_password_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool isUploading = false;

  // Real Firebase Logout
  void logout() async {
    await FirebaseAuth.instance.signOut();
    Fluttertoast.showToast(msg: "Logged out successfully", backgroundColor: const Color(0xFF43302E), textColor: const Color(0xFFFFF1B5), webBgColor: "#43302E");
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
    }
  }

  // Upload Profile Picture
  Future<void> updateProfilePicture() async {
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Image Source"),
        content: const Text("Where do you want to get the picture from?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            child: const Text("Gallery", style: TextStyle(color: Color(0xFF43302E), fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            child: const Text("Camera", style: TextStyle(color: Color(0xFF43302E), fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );

    if (source == null) return;

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image != null) {
      setState(() => isUploading = true);

      try {
        final bytes = await image.readAsBytes();
        var request = http.MultipartRequest('POST', Uri.parse('https://api.cloudinary.com/v1_1/djcrejx6n/image/upload'));
        request.fields['upload_preset'] = 'flutter_recipes';
        request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: image.name));

        var response = await request.send();
        var responseData = await response.stream.bytesToString();
        var jsonResponse = json.decode(responseData);

        if (response.statusCode == 200) {
          String newImageUrl = jsonResponse['secure_url'];
          await user?.updatePhotoURL(newImageUrl);
          setState(() {}); // refresh UI
          Fluttertoast.showToast(msg: "Profile picture updated!", backgroundColor: const Color(0xFF43302E), textColor: const Color(0xFFFFF1B5), webBgColor: "#43302E");
        } else {
          Fluttertoast.showToast(msg: "Failed to upload photo.");
        }
      } catch (e) {
        Fluttertoast.showToast(msg: "Error uploading photo.");
      } finally {
        setState(() => isUploading = false);
      }
    }
  }

  void navigateToUpdatePassword() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const UpdatePasswordScreen()));
  }

  // Delete Account
  void deleteAccount() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Account?"),
        content: const Text("This action cannot be undone. Are you sure?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              try {
                await user?.delete();
                if (mounted) {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                }
              } catch (e) {
                // If it fails, Firebase requires recent login to delete an account
                Fluttertoast.showToast(msg: "Failed to delete account. Please log out and log back in to verify your identity.", backgroundColor: Colors.red);
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color textColor = isDark ? Colors.white : const Color(0xFF43302E);
    Color cardBg = isDark ? Colors.grey[850]! : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: Text('My Profile', style: TextStyle(color: textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ListView(
            children: [
              // Profile Avatar with Camera Icon overlay
              Center(
                child: GestureDetector(
                  onTap: isUploading ? null : updateProfilePicture,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 55,
                        backgroundColor: const Color(0xFFF0F5F9),
                        backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                        child: user?.photoURL == null 
                            ? (isUploading ? const CircularProgressIndicator(color: Color(0xFF43302E)) : const Icon(Icons.person, size: 60, color: Color(0xFF43302E)))
                            : (isUploading ? const CircularProgressIndicator(color: Color(0xFF43302E)) : null),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: Color(0xFF43302E), shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Real User Email from Firebase
              Center(
                child: Text(user?.email ?? 'No email found', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 40),
              
              // Sleek Settings Menu
              Container(
                decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.lock_outline, color: textColor),
                      title: Text('Update Password', style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                      onTap: navigateToUpdatePassword,
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      title: const Text('Delete Account', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.redAccent)),
                      onTap: deleteAccount,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Logout Tile (Clean and professional)
              Container(
                decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
                  onTap: logout,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
