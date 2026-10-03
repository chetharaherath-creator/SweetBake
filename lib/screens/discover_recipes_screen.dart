import 'package:flutter/material.dart';
import '../models/external_recipe.dart';
import '../models/external_recipe.dart';
import '../services/api_service.dart';
import 'recipe_details_screen.dart';

class DiscoverRecipesScreen extends StatefulWidget {
  const DiscoverRecipesScreen({super.key});

  @override
  State<DiscoverRecipesScreen> createState() => _DiscoverRecipesScreenState();
}

class _DiscoverRecipesScreenState extends State<DiscoverRecipesScreen> {
  // We create a variable to hold our data that is coming from the internet
  late Future<List<ExternalRecipe>> _recipesFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    // Start fetching the recipes as soon as this screen is opened
    _recipesFuture = _apiService.fetchRecipes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Discover Desserts', 
          style: TextStyle(color: Color(0xFF43302E), fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF43302E)),
      ),
      // FutureBuilder is perfect for waiting for the internet! 
      // It handles showing a loading spinner automatically.
      body: FutureBuilder<List<ExternalRecipe>>(
        future: _recipesFuture,
        builder: (context, snapshot) {
          
          // State 1: We are still waiting for the internet
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF43302E)));
          } 
          // State 2: Something went wrong
          else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } 
          // State 3: The data arrived successfully!
          else if (snapshot.hasData) {
            final recipes = snapshot.data!;
            
            return ListView.builder(
              padding: const EdgeInsets.all(20.0),
              itemCount: recipes.length,
              itemBuilder: (context, index) {
                final recipe = recipes[index];
                
                // Using the exact layout from your All Recipes list!
                return GestureDetector(
                  onTap: () async {
                    // 1. Show a loading circle while we fetch the FULL recipe details!
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF43302E))),
                    );
                    
                    try {
                      // 2. Fetch the ingredients and instructions
                      final fullDetails = await _apiService.fetchRecipeDetails(recipe.id);
                      
                      // 3. Close the loading circle
                      if (context.mounted) Navigator.pop(context); 
                      
                      // 4. Go to the Recipe Details Screen!
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RecipeDetailsScreen(
                              id: recipe.id, // The API ID
                              title: recipe.title,
                              time: "45 mins", // You can hardcode an estimated time
                              imageUrl: recipe.imageUrl,
                              recipeData: {
                                'category': recipe.category,
                                'ingredients': fullDetails['ingredients'],
                                'steps': fullDetails['steps'],
                                'uid': 'api_recipe', // Set an artificial user ID so it can't be edited/deleted by the user
                              },
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      // If it fails, close the loading circle and show an error
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Failed to load recipe details. Please try again.')),
                        );
                      }
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white, 
                      borderRadius: BorderRadius.circular(16)
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            recipe.imageUrl, 
                            width: 70, 
                            height: 70, 
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(
                              width: 70, 
                              height: 70, 
                              color: const Color(0xFFF0F5F9), 
                              child: const Icon(Icons.cake, color: Color(0xFF43302E))
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                recipe.title, 
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                recipe.category, 
                                style: const TextStyle(color: Color(0xFF43302E), fontSize: 12)
                              ),
                              const SizedBox(height: 4),
                              const Row(
                                children: [
                                  Icon(Icons.access_time, size: 14, color: Colors.grey),
                                  SizedBox(width: 4),
                                  Text("30 minutes", style: TextStyle(color: Colors.grey, fontSize: 12)), 
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
                );
              },
            );
          }
          
          // State 4: Default fallback
          return const Center(child: Text('No recipes found.'));
        },
      ),
    );
  }
}
