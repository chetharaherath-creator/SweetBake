import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_recipe_screen.dart';
import 'add_recipe_screen.dart';
import 'recipe_details_screen.dart';

class MyRecipesScreen extends StatefulWidget {
  const MyRecipesScreen({super.key});

  @override
  State<MyRecipesScreen> createState() => _MyRecipesScreenState();
}

class _MyRecipesScreenState extends State<MyRecipesScreen> {
  void deleteRecipe(String docId) {
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
                await FirebaseFirestore.instance.collection('recipes').doc(docId).delete();
                Fluttertoast.showToast(msg: "Recipe deleted", backgroundColor: const Color(0xFF43302E), textColor: const Color(0xFFFFF1B5), webBgColor: "#43302E");
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Recipes'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: Color(0xFF43302E), size: 28),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AddRecipeScreen()));
            },
          ),
        ],
      ),
      body: SafeArea(
        child: currentUid == null
            ? const Center(child: Text("Please log in to see your recipes."))
            : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('recipes').where('uid', isEqualTo: currentUid).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF43302E)));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('You haven\'t uploaded any recipes yet!', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    );
                  }

                  final recipes = snapshot.data!.docs.toList();
                  
                  // Sort the list so newest recipes appear at the top!
                  recipes.sort((a, b) {
                    final dataA = a.data() as Map<String, dynamic>;
                    final dataB = b.data() as Map<String, dynamic>;
                    
                    // Get the timestamps
                    final timeA = dataA['createdAt'] as Timestamp?;
                    final timeB = dataB['createdAt'] as Timestamp?;
                    
                    // If a recipe is old and doesn't have a time, put it at the bottom
                    if (timeA == null) return 1; 
                    if (timeB == null) return -1;
                    
                    // Compare times to put newest on top
                    return timeB.compareTo(timeA); 
                  });

                  return ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: recipes.length,
                    itemBuilder: (context, index) {
                      final recipeDoc = recipes[index];
                      final recipeData = recipeDoc.data() as Map<String, dynamic>;
                      String id = recipeDoc.id;
                      String title = recipeData['title'] ?? 'Untitled';
                      String time = recipeData['time'] ?? '';
                      String image = recipeData['image'] ?? recipeData['imageUrl'] ?? 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=500';

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RecipeDetailsScreen(
                                id: id,
                                title: title,
                                time: time,
                                imageUrl: image,
                                recipeData: recipeData,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12.0),
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(image, width: 70, height: 70, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(width: 70, height: 70, color: const Color(0xFFF0F5F9), child: const Icon(Icons.cake, color: Color(0xFF43302E)))),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: Colors.grey),
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => EditRecipeScreen(id: id, recipeData: recipeData)));
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                onPressed: () => deleteRecipe(id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}
