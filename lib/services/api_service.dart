import 'dart:convert'; // Used to convert the raw internet data into readable maps
import 'package:http/http.dart' as http; // Used to actually talk to the internet
import '../models/external_recipe.dart';

class ApiService {
  // We use Future because going to the internet takes a few seconds. 
  // It promises that a List of ExternalRecipes will arrive 'in the future'.
  Future<List<ExternalRecipe>> fetchRecipes() async {
    // 1. The URL where the data lives. We are asking for the 'Dessert' category.
    final url = Uri.parse('https://www.themealdb.com/api/json/v1/1/filter.php?c=Dessert');
    
    // 2. We use http.get to literally "get" the data from that URL.
    final response = await http.get(url);

    // 3. Status code 200 means "OK" (like a thumbs up from the server)
    if (response.statusCode == 200) {
      // Decode the raw response text into a Dart Map
      final Map<String, dynamic> data = json.decode(response.body);
      
      // The API puts all the recipes inside a list called 'meals'
      final List meals = data['meals'];
      
      // We convert each item in the list into our ExternalRecipe object
      return meals.map((json) => ExternalRecipe.fromJson(json)).toList();
    } else {
      // If the server didn't give a thumbs up, something went wrong.
      throw Exception('Failed to load dessert recipes');
    }
  }

  // A new function to fetch the FULL details of a single recipe when clicked!
  Future<Map<String, dynamic>> fetchRecipeDetails(String id) async {
    final url = Uri.parse('https://www.themealdb.com/api/json/v1/1/lookup.php?i=$id');
    
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final meal = data['meals'][0];
      
      // The API gives ingredients and measures separated. Let's combine them into a list.
      List<String> ingredientsList = [];
      for (int i = 1; i <= 20; i++) {
        String? ingredient = meal['strIngredient$i'];
        String? measure = meal['strMeasure$i'];
        
        if (ingredient != null && ingredient.trim().isNotEmpty) {
          ingredientsList.add("${measure ?? ''} $ingredient".trim());
        }
      }
      
      // Return a neatly organized map with all the extra details!
      return {
        'ingredients': ingredientsList.join('\n'), // Joining them so it displays nicely
        'steps': meal['strInstructions'] ?? 'No instructions provided.',
      };
    } else {
      throw Exception('Failed to load full recipe details');
    }
  }
}
