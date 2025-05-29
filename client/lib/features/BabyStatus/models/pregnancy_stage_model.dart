class PregnancyStageModel {
  final int week;
  final String title;
  final String imagePath;
  final String description;
  final String babySize;
  final List<String> keyDevelopments;
  final List<String> motherSymptoms;
  final List<String> tipsForParents;

  PregnancyStageModel({
    required this.week,
    required this.title,
    required this.imagePath,
    required this.description,
    required this.babySize,
    required this.keyDevelopments,
    required this.motherSymptoms,
    required this.tipsForParents,
  });

  factory PregnancyStageModel.fromJson(Map<String, dynamic> json) {
    return PregnancyStageModel(
      week: json['week'] ?? 0,
      title: json['title'] ?? '',
      imagePath: json['image_path'] ?? '',
      description: json['description'] ?? '',
      babySize: json['baby_size'] ?? '',
      keyDevelopments: List<String>.from(json['key_developments'] ?? []),
      motherSymptoms: List<String>.from(json['mother_symptoms'] ?? []),
      tipsForParents: List<String>.from(json['tips_for_parents'] ?? []),
    );
  }

  // Helper method to get the month from week
  int get month {
    return ((week - 1) ~/ 4) + 1;
  }

  // Helper method to get week within month
  int get weekInMonth {
    return ((week - 1) % 4) + 1;
  }
}