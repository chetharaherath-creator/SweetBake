import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../components/custom_text_field.dart';
import '../components/custom_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddRecipeScreen extends StatefulWidget {
  const AddRecipeScreen({super.key});

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  TextEditingController titleController = TextEditingController();
  TextEditingController timeController = TextEditingController();
  TextEditingController ingredientsController = TextEditingController();
  TextEditingController stepsController = TextEditingController();

  String selectedCategory = 'Cakes';
  final List<String> categories = ['Cakes', 'Cookies', 'Cheesecakes', 'Pies', 'Macarons'];

  bool isUploading = false;
  String? uploadedImageUrl;

  // Take photo and upload to Cloudinary
  Future<void> pickAndUploadImage() async {
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
      setState(() {
        isUploading = true;
      });

      try {
        final bytes = await image.readAsBytes();
        
        var request = http.MultipartRequest('POST', Uri.parse('https://api.cloudinary.com/v1_1/djcrejx6n/image/upload'));
        request.fields['upload_preset'] = 'flutter_recipes';
        
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: image.name,
        ));

        var response = await request.send();
        var responseData = await response.stream.bytesToString();
        var jsonResponse = json.decode(responseData);

        if (response.statusCode == 200) {
          setState(() {
            uploadedImageUrl = jsonResponse['secure_url'];
          });
          Fluttertoast.showToast(msg: "Photo uploaded successfully!", backgroundColor: const Color(0xFF43302E), textColor: const Color(0xFFFFF1B5), webBgColor: "#43302E");
        } else {
          Fluttertoast.showToast(msg: "Failed to upload photo.", backgroundColor: const Color(0xFF43302E), textColor: const Color(0xFFFFF1B5), webBgColor: "#43302E");
        }
      } catch (e) {
        Fluttertoast.showToast(msg: "Error uploading photo.", backgroundColor: const Color(0xFF43302E), textColor: const Color(0xFFFFF1B5), webBgColor: "#43302E");
      } finally {
        setState(() {
          isUploading = false;
        });
      }
    }
  }

  Future<void> saveRecipe() async {
    String title = titleController.text.trim();
    String time = timeController.text.trim();
    String ingredients = ingredientsController.text.trim();
    String steps = stepsController.text.trim();

    if (title.isEmpty || time.isEmpty) {
      Fluttertoast.showToast(msg: "Please enter recipe title and preparation time", backgroundColor: const Color(0xFF43302E), textColor: const Color(0xFFFFF1B5), webBgColor: "#43302E");
      return;
    }

    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      Fluttertoast.showToast(msg: "You must be logged in to add a recipe.", backgroundColor: const Color(0xFF43302E), textColor: const Color(0xFFFFF1B5), webBgColor: "#43302E");
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('recipes').add({
        'title': title,
        'category': selectedCategory,
        'time': time,
        'ingredients': ingredients,
        'steps': steps,
        'uid': uid,
        'image': uploadedImageUrl ?? 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=500', // Use uploaded image or default
        'createdAt': FieldValue.serverTimestamp(),
      });

      Fluttertoast.showToast(msg: "Recipe saved successfully!", backgroundColor: const Color(0xFF43302E), textColor: const Color(0xFFFFF1B5), webBgColor: "#43302E");
      
      if (mounted) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          titleController.clear();
          timeController.clear();
          ingredientsController.clear();
          stepsController.clear();
          setState(() {
            uploadedImageUrl = null;
            selectedCategory = 'Cakes';
          });
        }
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to save recipe", backgroundColor: const Color(0xFF43302E), textColor: const Color(0xFFFFF1B5), webBgColor: "#43302E");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Recipe'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: ListView(
            children: [
              GestureDetector(
                onTap: isUploading ? null : pickAndUploadImage,
                child: Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F5F9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF43302E), style: BorderStyle.solid),
                    image: uploadedImageUrl != null 
                        ? DecorationImage(image: NetworkImage(uploadedImageUrl!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: isUploading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF43302E)))
                      : uploadedImageUrl == null
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt_rounded, size: 40, color: Color(0xFF43302E)),
                                SizedBox(height: 8),
                                Text('Take Photo', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF43302E))),
                                Text('Tap to capture photo with Camera', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            )
                          : Container(), // Empty if image is shown, or could put a small edit icon
                ),
              ),
              const SizedBox(height: 20),
              CustomTextField(hintText: 'Recipe Title', icon: Icons.title, controller: titleController),
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    prefixIcon: const Icon(Icons.category, color: Color(0xFF43302E)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: categories.map((String cat) {
                    return DropdownMenuItem<String>(value: cat, child: Text(cat));
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() { selectedCategory = newValue!; });
                  },
                ),
              ),
              CustomTextField(hintText: 'Preparation Time (e.g. 30 min)', icon: Icons.timer, controller: timeController),
              CustomTextField(
                hintText: 'Ingredients (one per line)', 
                icon: Icons.format_list_bulleted, 
                controller: ingredientsController,
                maxLines: 3,
              ),
              CustomTextField(
                hintText: 'Preparation Steps', 
                icon: Icons.list_alt, 
                controller: stepsController,
                maxLines: 4,
              ),
              const SizedBox(height: 10),
              CustomButton(text: 'Save Recipe', onPressed: isUploading ? () {} : saveRecipe),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
