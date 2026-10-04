import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_recipe_screen.dart';
import 'main_navigation.dart';

class RecipeDetailsScreen extends StatefulWidget {
  final String id;
  final String title;
  final String time;
  final String imageUrl;
  final Map<String, dynamic> recipeData;

  const RecipeDetailsScreen({
    super.key,
    required this.id,
    required this.title,
    required this.time,
    required this.imageUrl,
    required this.recipeData,
  });

  @override
  State<RecipeDetailsScreen> createState() => _RecipeDetailsScreenState();
}

class _RecipeDetailsScreenState extends State<RecipeDetailsScreen> {

  void deleteRecipe() {
    bool isDeleting = false; // Add safety lock to prevent double-tapping

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Delete Recipe?"),
        content: const Text("Are you sure you want to delete this recipe? This cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext), 
            child: const Text("Cancel", style: TextStyle(color: Colors.grey))
          ),
          TextButton(
            onPressed: () async {
              if (isDeleting) return; // If already running, ignore the extra click!
              isDeleting = true;

              Navigator.pop(dialogContext); // Close dialog safely using dialogContext
              try {
                // 1. Delete the recipe from the database
                await FirebaseFirestore.instance.collection('recipes').doc(widget.id).delete();
                
                // 2. Show the success message
                Fluttertoast.showToast(msg: "Recipe deleted", backgroundColor: const Color(0xFF43302E), textColor: const Color(0xFFFFF1B5), webBgColor: "#43302E");
                
                // 3. Immediately send the user back to the Home Screen using the SCREEN's context
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context, 
                    MaterialPageRoute(builder: (context) => const MainNavigation()), 
                    (route) => false
                  );
                }
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
    String? currentUid = FirebaseAuth.instance.currentUser?.uid;
    String ownerUid = widget.recipeData['uid'] ?? '';
    bool isOwner = currentUid == ownerUid;

    // Parse ingredients and steps safely
    String rawIngredients = widget.recipeData['ingredients'] ?? '';
    List<String> ingredients = rawIngredients.split('\n').where((s) => s.trim().isNotEmpty).toList();
    if (ingredients.isEmpty) ingredients = ['No ingredients provided.'];

    String rawSteps = widget.recipeData['steps'] ?? '';
    List<String> steps = rawSteps.split('\n').where((s) => s.trim().isNotEmpty).toList();
    if (steps.isEmpty) steps = ['No steps provided.'];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.grey),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditRecipeScreen(
                      id: widget.id,
                      recipeData: widget.recipeData,
                    ),
                  ),
                ).then((value) {
                  if (value == true && mounted) {
                    Navigator.pop(context); // Pop if edited so it refreshes from stream
                  }
                });
              },
            ),
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: deleteRecipe,
            ),
        ],
      ),
      body: ListView(
        children: [
          Hero(
            tag: 'recipe_image_${widget.id}',
            child: Image.network(
              widget.imageUrl,
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 220,
                  color: const Color(0xFFF0F5F9),
                  child: const Icon(Icons.cake, size: 80, color: Color(0xFF43302E)),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, size: 16, color: Color(0xFF43302E)),
                          const SizedBox(width: 4),
                          Text(
                            widget.time,
                            style: const TextStyle(color: Color(0xFF43302E), fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  widget.recipeData['category'] ?? 'Recipe',
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 24),
                const Text('Ingredients', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ...ingredients.map(
                  (ingredient) => Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 6.0),
                          child: Icon(Icons.circle, size: 6, color: Color(0xFF43302E)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(ingredient.trim(), style: const TextStyle(fontSize: 14))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Instructions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ...steps.asMap().entries.map((entry) {
                  int stepNum = entry.key + 1;
                  String stepText = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: const Color(0xFF43302E),
                          child: Text('$stepNum', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(stepText.trim(), style: const TextStyle(fontSize: 14)),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
