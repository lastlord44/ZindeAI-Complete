class UserProfile {
  final String sex;
  final int age;
  final int heightCm;
  final double weightKg;
  final String goal;
  final String activity;
  final List<String> dietFlags;
  final TrainingPreferences training;

  UserProfile({
    required this.sex,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.goal,
    required this.activity,
    required this.dietFlags,
    required this.training,
  });

  Map<String, dynamic> toJson() {
    return {
      'sex': sex,
      'age': age,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'goal': goal,
      'activity': activity,
      'diet_flags': dietFlags,
      'training': training.toJson(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      sex: json['sex'] ?? 'male',
      age: json['age'] ?? 25,
      heightCm: json['height_cm'] ?? 170,
      weightKg: (json['weight_kg'] ?? 70).toDouble(),
      goal: json['goal'] ?? 'maintain',
      activity: json['activity'] ?? 'med',
      dietFlags: List<String>.from(json['diet_flags'] ?? []),
      training: TrainingPreferences.fromJson(json['training'] ?? {}),
    );
  }
}

class TrainingPreferences {
  final int daysPerWeek;
  final List<String> days;
  final String splitPreference;
  final String mode;

  TrainingPreferences({
    required this.daysPerWeek,
    required this.days,
    required this.splitPreference,
    required this.mode,
  });

  Map<String, dynamic> toJson() {
    return {
      'days_per_week': daysPerWeek,
      'days': days,
      'split_preference': splitPreference,
      'mode': mode,
    };
  }

  factory TrainingPreferences.fromJson(Map<String, dynamic> json) {
    return TrainingPreferences(
      daysPerWeek: json['days_per_week'] ?? 3,
      days: List<String>.from(json['days'] ?? ['Monday', 'Wednesday', 'Friday']),
      splitPreference: json['split_preference'] ?? 'AUTO',
      mode: json['mode'] ?? 'gym',
    );
  }
}
