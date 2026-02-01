/// Exercise model from ExerciseDB API
class Exercise {
  final String id;
  final String name;
  final String bodyPart;
  final String target;
  final String equipment;
  final List<String> secondaryMuscles;
  final List<String> instructions;
  final String? gifUrl;

  Exercise({
    required this.id,
    required this.name,
    required this.bodyPart,
    required this.target,
    required this.equipment,
    required this.secondaryMuscles,
    required this.instructions,
    this.gifUrl,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    // Try multiple possible field names for gifUrl (different API versions might use different names)
    String? gifUrl;
    if (json['gifUrl'] != null) {
      gifUrl = json['gifUrl']?.toString();
    } else if (json['gif_url'] != null) {
      gifUrl = json['gif_url']?.toString();
    } else if (json['gif'] != null) {
      gifUrl = json['gif']?.toString();
    } else if (json['imageUrl'] != null) {
      gifUrl = json['imageUrl']?.toString();
    } else if (json['image_url'] != null) {
      gifUrl = json['image_url']?.toString();
    }
    
    return Exercise(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      bodyPart: json['bodyPart']?.toString() ?? '',
      target: json['target']?.toString() ?? '',
      equipment: json['equipment']?.toString() ?? '',
      secondaryMuscles: json['secondaryMuscles'] != null
          ? List<String>.from(json['secondaryMuscles'])
          : [],
      instructions: json['instructions'] != null
          ? List<String>.from(json['instructions'])
          : [],
      gifUrl: gifUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'bodyPart': bodyPart,
      'target': target,
      'equipment': equipment,
      'secondaryMuscles': secondaryMuscles,
      'instructions': instructions,
      'gifUrl': gifUrl,
    };
  }
}
