class ExternalRecipe {
  final String id;
  final String title;
  final String imageUrl;
  final String category;

  ExternalRecipe({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.category, 
  });

  // A factory constructor takes the raw data from the internet (which is in a map/JSON format)
  // and turns it into our neat Dart object.
  factory ExternalRecipe.fromJson(Map<String, dynamic> json) {
    return ExternalRecipe(
      id: json['idMeal'],
      title: json['strMeal'],
      imageUrl: json['strMealThumb'],
      category: 'Dessert', // We can hardcode this since we only ask the API for desserts
    );
  }
}
