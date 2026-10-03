import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../components/custom_text_field.dart';
import '../components/custom_button.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditRecipeScreen extends StatefulWidget {
  final String id;
  final Map<String, dynamic> recipeData;

  const EditRecipeScreen({
    super.key,
    required this.id,
    required this.recipeData,
  });

  @override
  State<EditRecipeScreen> createState() => _EditRecipeScreenState();
}

class _EditRecipeScreenState extends State<EditRecipeScreen> {
  late TextEditingController titleController;
  late TextEditingController timeController;
  late TextEditingController ingredientsController;
  late TextEditingController stepsController;

  late String selectedCategory;
  final List<String> categories = ['Cakes', 'Cookies', 'Cheesecakes', 'Pies', 'Macarons'];

  bool isUploading = false;
  String? uploadedImageUrl;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.recipeData['title']);
    timeController = TextEditingController(text: widget.recipeData['time']);
    selectedCategory = widget.recipeData['category'] ?? 'Cakes';
    if (!categories.contains(selectedCategory)) selectedCategory = 'Cakes';
    
    ingredientsController = TextEditingController(text: widget.recipeData['ingredients']);
    stepsController = TextEditingController(text: widget.recipeData['steps']);
    
    uploadedImageUrl = widget.recipeData['image'] ?? widget.recipeData['imageUrl'];
  }

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
        
        request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: image.name));

        var response = await request.send();
        var responseData = await response.stream.bytesToString();
        var jsonResponse = json.decode(responseData);

        if (response.statusCode == 200) {
          setState(() {
            uploadedImageUrl = jsonResponse['secure_url'];
          });
          Fluttertoast.showToast(msg: "Photo updated!", backgroundColor: const Color(0xFF43302E), textColor: const Color(0xFFFFF1B5), webBgColor: "#43302E");
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

  Future<void> updateRecipe() async {
    String newTitle = titleController.text.trim();
    if (newTitle.isEmpty) {
      Fluttertoast.showToast(msg: "Please enter a recipe title", backgroundColor: const Color(0xFF43302E), textColor: const Color(0xFFFFF1B5), webBgColor: "#43302E");
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('recipes').doc(widget.id).update({
        'title': newTitle,
        'category': selectedCategory,
        'time': timeController.text.trim(),
        'ingredients': ingredientsController.text.trim(),
        'steps': stepsController.text.trim(),
        if (uploadedImageUrl != null) 'image': uploadedImageUrl,
      });

      Fluttertoast.showToast(msg: "Recipe updated!", backgroundColor: const Color(0xFF43302E), textColor: const Color(0xFFFFF1B5), webBgColor: "#43302E");
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to update", backgroundColor: const Color(0xFF43302E), textColor: const Color(0xFFFFF1B5), webBgColor: "#43302E");
    }
  }

  void deleteRecipe() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Recipe?"),
        content: const Text("Are you sure you want to delete this recipe? This cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("Cancel", style: TextStyle(color: Colors.grey))
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              try {
                await FirebaseFirestore.instance.collection('recipes').doc(widget.id).delete();
                Fluttertoast.showToast(msg: "Recipe deleted", backgroundColor: const Color(0xFF43302E), textColor: const Color(0xFFFFF1B5), webBgColor: "#43302E");
                if (mounted) Navigator.pop(context, true);
              } catch (e) {
                Fluttertoast.showToast(msg: "Failed to delete", backgroundColor: const Color(0xFF43302E), textColor: const Color(0xFFFFF1B5), webBgColor: "#43302E");
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String displayImage = uploadedImageUrl ?? 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=500';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Recipe'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: deleteRecipe,
          ),
        ],
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
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: NetworkImage(displayImage),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: isUploading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Change Photo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
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
              CustomTextField(hintText: 'Preparation Time', icon: Icons.timer, controller: timeController),
              CustomTextField(
                hintText: 'Ingredients', 
                icon: Icons.format_list_bulleted, 
                controller: ingredientsController,
                maxLines: 3,
              ),
              CustomTextField(
                hintText: 'Steps', 
                icon: Icons.list_alt, 
                controller: stepsController,
                maxLines: 3,
              ),
              const SizedBox(height: 10),
              CustomButton(text: 'Update Recipe', onPressed: isUploading ? () {} : updateRecipe),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
