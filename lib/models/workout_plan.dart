import '../utils/json_parser.dart';

class WorkoutPlan {
  final String userId;
  final int weekNumber;
  final String splitType;
  final String mode;
  final String goal;
  final List<WorkoutDay> days;
  final String progressionNotes;
  final String? nextWeekAdjustment;

  WorkoutPlan({
    required this.userId,
    required this.weekNumber,
    required this.splitType,
    required this.mode,
    required this.goal,
    required this.days,
    required this.progressionNotes,
    this.nextWeekAdjustment,
  });

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) {
    // API'den gelen format: {"workouts": [{"day": 1, "type": "...", "exercises": [...]}]}
    List<WorkoutDay> days = [];

    if (json.containsKey('workouts') && json['workouts'] is List) {
      // API'nin mevcut formatı: "workouts": [...]
      days = (json['workouts'] as List<dynamic>)
          .map((e) => WorkoutDay.fromJson(e as Map<String, dynamic>))
          .toList();
    } else if (json.containsKey('days') &&
        json['days'] is Map<String, dynamic>) {
      // Backend'den gelen format: {"days": {"Pazartesi": {...}, "Salı": {...}}}
      final daysMap = json['days'] as Map<String, dynamic>;
      days = daysMap.entries.map((entry) {
        final dayData = entry.value as Map<String, dynamic>;
        return WorkoutDay.fromJson({
          'day': entry.key,
          'focus': dayData['focus'] ?? 'Genel Antrenman',
          'exercises': dayData['exercises'] ?? [],
          'warmup': dayData['warmup'],
          'cooldown': dayData['cooldown'],
          'totalTime': dayData['totalTime'],
        });
      }).toList();
    } else if (json.containsKey('days') && json['days'] is List) {
      // Eski format: {"days": [{"day": "Pazartesi", ...}]}
      days = safeParseList(json['days'], (day) => WorkoutDay.fromJson(day));
    }

    return WorkoutPlan(
      userId: safeParseString(json['userId']),
      weekNumber: safeParseInt(json['weekNumber'], defaultValue: 1),
      splitType: safeParseString(json['splitType'], defaultValue: 'Full Body'),
      mode: safeParseString(json['mode'], defaultValue: 'gym'),
      goal: safeParseString(json['goal']),
      days: days,
      progressionNotes: safeParseString(json['progressionNotes']),
      nextWeekAdjustment: json['nextWeekAdjustment']?.toString(),
    );
  }
}

class WorkoutDay {
  final String day;
  final String focus;
  final List<Exercise> exercises;
  final String? warmup;
  final String? cooldown;
  final int? totalTime;

  WorkoutDay({
    required this.day,
    required this.focus,
    required this.exercises,
    this.warmup,
    this.cooldown,
    this.totalTime,
  });

  factory WorkoutDay.fromJson(Map<String, dynamic> json) {
    return WorkoutDay(
      day: json['day']?.toString() ?? 'Antrenman Günü',
      focus: json['type'] as String? ??
          json['focus'] as String? ??
          'Genel Antrenman',
      exercises:
          safeParseList(json['exercises'], (ex) => Exercise.fromJson(ex)),
      warmup: json['warmup']?.toString(),
      cooldown: json['cooldown']?.toString(),
      totalTime:
          json['totalTime'] != null ? safeParseInt(json['totalTime']) : null,
    );
  }
}

class Exercise {
  final String name;
  final String targetMuscle;
  final int sets;
  final String reps;
  final int rest;
  final String? tempo;
  final String? weight;
  final String? gif;
  final String? notes;
  final String? exerciseId; // YENİ: Egzersiz ID'si
  final String? rpe; // YENİ: RPE değeri

  Exercise({
    required this.name,
    required this.targetMuscle,
    required this.sets,
    required this.reps,
    required this.rest,
    this.tempo,
    this.weight,
    this.gif,
    this.notes,
    this.exerciseId, // YENİ
    this.rpe, // YENİ
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      name: safeParseString(json['name'], defaultValue: 'Bilinmeyen Egzersiz'),
      targetMuscle: safeParseString(json['targetMuscle']),
      sets: safeParseInt(json['sets'], defaultValue: 3),
      reps: safeParseString(json['reps'], defaultValue: '10'),
      rest: safeParseInt(json['rest'], defaultValue: 60),
      tempo: json['tempo']?.toString(),
      weight: json['weight']?.toString(),
      gif: json['gif']?.toString(),
      notes: json['notes']?.toString(),
      exerciseId: json['exerciseId']?.toString(),
      rpe: json['rpe']?.toString(),
    );
  }
}
