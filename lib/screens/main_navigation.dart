import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'my_recipes_screen.dart';
import 'add_recipe_screen.dart';
import 'profile_screen.dart';

// MainNavigation holding the fixed BottomNavigationBar with 4 tabs
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  // Current active tab index
  int selectedIndex = 0;

  // List of screens connected to BottomNavigationBar
  final List<Widget> screens = [
    const HomeScreen(),
    const MyRecipesScreen(),
    const AddRecipeScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Body displays the screen at selectedIndex
      body: screens[selectedIndex],

      // Fixed Bottom Navigation Bar matching inspo design
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        selectedItemColor: Color(0xFF43302E),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          // Change current screen tab using setState
          setState(() {
            selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'My Recipes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle, size: 32),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
