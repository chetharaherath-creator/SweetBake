import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../components/recipe_card.dart';
import 'recipe_details_screen.dart';
import '../models/external_recipe.dart';
import '../services/api_service.dart';
import 'discover_recipes_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TextEditingController searchController = TextEditingController();
  List<String> categories = ['All', 'Cakes', 'Cookies', 'Cheesecakes', 'Pies', 'Macarons'];
  String selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    Query recipesQuery = FirebaseFirestore.instance.collection('recipes');
    if (selectedCategory != 'All') {
      recipesQuery = FirebaseFirestore.instance.collection('recipes')
          .where('category', isEqualTo: selectedCategory);
    }

    return Scaffold(
      body: SafeArea(
        child: Builder(
          builder: (context) {
            bool isDark = Theme.of(context).brightness == Brightness.dark;
            Color primaryText = isDark ? Colors.white : const Color(0xFF43302E);
            Color containerBg = isDark ? Colors.grey[850]! : const Color(0xFFF0F5F9);
            Color cardBg = isDark ? Colors.grey[900]! : Colors.white;

            return ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SweetBake', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: primaryText)),
                    const Text('BAKE. SHARE. ENJOY.', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: containerBg, borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bake something\nbeautiful today.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF2D2727))),
                        const SizedBox(height: 8),
                        const Text('Discover endless sweet inspirations from around the web!', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF43302E),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const DiscoverRecipesScreen(),
                              ),
                            );
                          },
                          child: const Text('Explore Now', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(Icons.cake_rounded, size: 70, color: primaryText),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('All Recipes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categories.map((category) {
                  bool isSelected = selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      checkmarkColor: const Color(0xFFFFF1B5),
                      label: Text(category),
                      selected: isSelected,
                      selectedColor: primaryText,
                      backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                      labelStyle: TextStyle(
                        color: isSelected 
                            ? (isDark ? Colors.black : Colors.white) 
                            : (isDark ? Colors.white : Colors.black), 
                        fontWeight: FontWeight.w600
                      ),
                      onSelected: (selected) {
                        setState(() { selectedCategory = category; });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: recipesQuery.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF43302E)));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Padding(padding: EdgeInsets.all(20.0), child: Text('No recipes found.')));
                }

                final recipes = snapshot.data!.docs.toList();
                
                // Sort the list so newest recipes appear at the top!
                recipes.sort((a, b) {
                  final dataA = a.data() as Map<String, dynamic>;
                  final dataB = b.data() as Map<String, dynamic>;
                  
                  final timeA = dataA['createdAt'] as Timestamp?;
                  final timeB = dataB['createdAt'] as Timestamp?;
                  
                  if (timeA == null) return 1;
                  if (timeB == null) return -1;
                  
                  return timeB.compareTo(timeA);
                });

                bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isLandscape ? 2 : 1,
                    childAspectRatio: isLandscape ? 3.5 : 4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemCount: recipes.length,
                  itemBuilder: (context, index) {
                    final recipeDoc = recipes[index];
                    final recipeData = recipeDoc.data() as Map<String, dynamic>;
                    String id = recipeDoc.id;
                    String title = recipeData['title'] ?? 'Untitled';
                    String time = recipeData['time'] ?? '';
                    String category = recipeData['category'] ?? '';
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
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16)),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Hero(
                                tag: 'recipe_image_$id',
                                child: Image.network(image, width: 70, height: 70, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(width: 70, height: 70, color: const Color(0xFFF0F5F9), child: const Icon(Icons.cake, color: Color(0xFF43302E)))),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.white : Colors.black)),
                                  const SizedBox(height: 4),
                                  Text(category, style: TextStyle(color: isDark ? Colors.grey[400] : const Color(0xFF43302E), fontSize: 12)),
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
                            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        );
        }
      )),
    );
  }
}
