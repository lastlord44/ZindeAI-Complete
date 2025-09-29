import 'dart:convert';
import 'package:dio/dio.dart';

class SmartApiHandler {
  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: Duration(seconds: 30),
    receiveTimeout: Duration(seconds: 30),
  ));

  static const String EDGE_FUNCTION_URL =
      'https://uhibpbwgvnvasxlvcohr.supabase.co/functions/v1/zindeai-router';

  // Beslenme planı oluştur - YENİ FORMAT
  static Future<Map<String, dynamic>> generateMealPlan({
    required double calories,
    required String goal,
    required String diet,
    required int daysPerWeek,
    Map<String, dynamic>? fullProfile,
  }) async {
    try {
      print('[ZindeAI] 🍽️ Beslenme planı oluşturuluyor...');
      print('  📊 Parametreler:');
      print('  - Kalori: $calories');
      print('  - Hedef: $goal');
      print('  - Diyet: $diet');
      print('  - Gün sayısı: $daysPerWeek');

      // Request body
      final requestBody = {
        'requestType': 'nutrition',
        'userInfo': _createUserInfoString(calories, goal, diet, fullProfile),
        'profile': fullProfile ??
            {
              'weight': 70,
              'height': 175,
              'age': 30,
              'gender': 'Erkek',
              'primary_goal': goal,
              'diet_type': diet,
              'preserve_muscle': goal == 'Kilo Verme',
            },
      };

      final response = await _dio.post(
        EDGE_FUNCTION_URL,
        data: requestBody,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'apikey':
                'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVoaWJwYndndm52YXN4bHZjb2hyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzU0MDQ4NzIsImV4cCI6MjA1MDk4MDg3Mn0.8Q7Q7Q7Q7Q7Q7Q7Q7Q7Q7Q7Q7Q7Q7Q7Q7Q7Q7Q7Q',
          },
        ),
      );

      if (response.data['success'] == true) {
        final mealPlan = response.data['data'];

        // Yeni format validasyonu ve parse
        final parsedPlan = _parseNewFormatMealPlan(mealPlan);

        print('[ZindeAI] ✅ Beslenme planı başarıyla oluşturuldu');
        return parsedPlan;
      } else {
        throw Exception('Plan oluşturulamadı: ${response.data['error']}');
      }
    } catch (e, stackTrace) {
      print('[ZindeAI] ❌ ERROR [ApiService] Yemek planı oluşturma hatası');
      print(
          '  📊 Data: {calories: $calories, goal: $goal, diet: $diet, daysPerWeek: $daysPerWeek}');
      print('  💥 Error: $e');
      print('  📍 StackTrace: $stackTrace');

      // Fallback plan döndür
      return _generateFallbackMealPlan(calories, goal, diet, daysPerWeek);
    }
  }

  // Yeni format meal plan parser - DÜZELTME BURADA
  static Map<String, dynamic> _parseNewFormatMealPlan(
      Map<String, dynamic> plan) {
    try {
      // Days array kontrolü
      if (!plan.containsKey('days') || plan['days'] == null) {
        throw Exception('Plan günleri eksik');
      }

      final days = plan['days'] as List;

      // Her günü parse et ve tip dönüşümlerini düzelt
      final parsedDays = days.map((day) {
        final meals = (day['meals'] as List?)?.map((meal) {
              return {
                'name': meal['name'] ?? '',
                'time': meal['time'] ?? '',
                'description': meal['description'] ?? '',
                // STRING'DEN NUMBER'A DOĞRU DÖNÜŞÜM
                'calories': _parseNumber(meal['calories']),
                'protein': _parseNumber(meal['protein']),
                'carbs': _parseNumber(meal['carbs']),
                'fat': _parseNumber(meal['fat']),
                'ingredients': (meal['ingredients'] as List?)?.map((ing) {
                      return {
                        'name': ing['name'] ?? '',
                        'amount': ing['amount']?.toString() ?? '0',
                        'unit': ing['unit'] ?? '',
                      };
                    }).toList() ??
                    [],
              };
            }).toList() ??
            [];

        // Günlük toplamları hesapla
        double totalCalories = 0;
        double totalProtein = 0;
        double totalCarbs = 0;
        double totalFat = 0;

        for (var meal in meals) {
          totalCalories += (meal['calories'] as num).toDouble();
          totalProtein += (meal['protein'] as num).toDouble();
          totalCarbs += (meal['carbs'] as num).toDouble();
          totalFat += (meal['fat'] as num).toDouble();
        }

        return {
          'day': day['day'] ?? 'Gün',
          'meals': meals,
          'totals': day['totals'] ??
              {
                'calories': totalCalories,
                'protein': totalProtein,
                'carbs': totalCarbs,
                'fat': totalFat,
              },
        };
      }).toList();

      // Daily macros parse et
      final dailyMacros = plan['daily_macros'] ?? {};
      final parsedMacros = {
        'calories': _parseNumber(dailyMacros['calories']),
        'protein': _parseNumber(dailyMacros['protein']),
        'carbs': _parseNumber(dailyMacros['carbs']),
        'fat': _parseNumber(dailyMacros['fat']),
      };

      return {
        'plan_name': plan['plan_name'] ?? 'Beslenme Planı',
        'user_specs': plan['user_specs'] ?? {},
        'daily_macros': parsedMacros,
        'days': parsedDays,
      };
    } catch (e) {
      print('[ZindeAI] ⚠️ Parse hatası: $e');
      throw e;
    }
  }

  // YARDIMCI FONKSİYON: Güvenli number parse
  static num _parseNumber(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value;
    if (value is String) {
      // String'den number'a güvenli dönüşüm
      return num.tryParse(value) ?? 0;
    }
    return 0;
  }

  // Antrenman planı oluştur
  static Future<Map<String, dynamic>> generateWorkoutPlan({
    required String goal,
    required String level,
    required int daysPerWeek,
    Map<String, dynamic>? fullProfile,
  }) async {
    try {
      print('[ZindeAI] 💪 Antrenman planı oluşturuluyor...');
      print('  📊 Parametreler:');
      print('  - Hedef: $goal');
      print('  - Seviye: $level');
      print('  - Gün sayısı: $daysPerWeek');

      final requestBody = {
        'requestType': 'workout',
        'userInfo':
            _createWorkoutUserInfo(goal, level, daysPerWeek, fullProfile),
        'profile': fullProfile ??
            {
              'primary_goal': goal,
              'fitness_level': level,
              'workout_days': daysPerWeek,
              'preserve_muscle': goal == 'Kilo Verme',
            },
      };

      final response = await _dio.post(
        EDGE_FUNCTION_URL,
        data: requestBody,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'apikey':
                'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVoaWJwYndndm52YXN4bHZjb2hyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzU0MDQ4NzIsImV4cCI6MjA1MDk4MDg3Mn0.8Q7Q7Q7Q7Q7Q7Q7Q7Q7Q7Q7Q7Q7Q7Q7Q7Q7Q7Q7Q',
          },
        ),
      );

      if (response.data['success'] == true) {
        final workoutPlan = response.data['data'];

        // Parse workout plan
        final parsedPlan = _parseWorkoutPlan(workoutPlan);

        print('[ZindeAI] ✅ Antrenman planı başarıyla oluşturuldu');
        return parsedPlan;
      } else {
        throw Exception('Plan oluşturulamadı: ${response.data['error']}');
      }
    } catch (e, stackTrace) {
      print('[ZindeAI] ❌ ERROR [ApiService] Antrenman planı oluşturma hatası');
      print('  💥 Error: $e');
      print('  📍 StackTrace: $stackTrace');

      return _generateFallbackWorkoutPlan(goal, level, daysPerWeek);
    }
  }

  // Workout plan parser
  static Map<String, dynamic> _parseWorkoutPlan(Map<String, dynamic> plan) {
    try {
      final workouts = plan['workouts'] as List?;

      if (workouts == null) {
        throw Exception('Workout günleri eksik');
      }

      // Her workout'u parse et
      final parsedWorkouts = workouts.map((workout) {
        final exercises = (workout['exercises'] as List?)?.map((ex) {
              return {
                'name': ex['name'] ?? '',
                'sets': _parseNumber(ex['sets']).toInt(),
                'reps': ex['reps']?.toString() ?? '10',
                'rest': _parseNumber(ex['rest']).toInt(),
                'rpe': _parseNumber(ex['rpe']),
                'notes': ex['notes'] ?? '',
              };
            }).toList() ??
            [];

        return {
          'day_number': _parseNumber(workout['day_number']).toInt(),
          'day_name': workout['day_name'] ?? 'Antrenman Günü',
          'focus': workout['focus'] ?? '',
          'exercises': exercises,
        };
      }).toList();

      return {
        'plan_name': plan['plan_name'] ?? 'Antrenman Planı',
        'user_specs': plan['user_specs'] ?? {},
        'split_type': plan['split_type'] ?? '',
        'workouts': parsedWorkouts,
        'weekly_notes': plan['weekly_notes'] ?? [],
      };
    } catch (e) {
      print('[ZindeAI] ⚠️ Workout parse hatası: $e');
      throw e;
    }
  }

  // User info string oluştur
  static String _createUserInfoString(double calories, String goal, String diet,
      Map<String, dynamic>? profile) {
    final buffer = StringBuffer();

    if (profile != null) {
      buffer.writeln('İsim: ${profile['name'] ?? 'Kullanıcı'}');
      buffer.writeln('Yaş: ${profile['age'] ?? 30}');
      buffer.writeln('Cinsiyet: ${profile['gender'] ?? 'Erkek'}');
      buffer.writeln('Boy: ${profile['height'] ?? 175} cm');
      buffer.writeln('Kilo: ${profile['weight'] ?? 70} kg');
      buffer.writeln(
          'Aktivite Seviyesi: ${profile['activity_level'] ?? 'Orta Aktif'}');
    }

    buffer.writeln('Hedef: $goal');
    buffer.writeln('Günlük Kalori: ${calories.toStringAsFixed(0)}');
    buffer.writeln('Diyet Tipi: $diet');

    if (profile?['preserve_muscle'] == true) {
      buffer.writeln('Özel Durum: KAS KÜTLESİ KORUMA AKTİF');
    }

    return buffer.toString();
  }

  // Workout user info
  static String _createWorkoutUserInfo(
      String goal, String level, int days, Map<String, dynamic>? profile) {
    final buffer = StringBuffer();

    if (profile != null) {
      buffer.writeln('İsim: ${profile['name'] ?? 'Kullanıcı'}');
      buffer.writeln('Yaş: ${profile['age'] ?? 30}');
      buffer.writeln('Cinsiyet: ${profile['gender'] ?? 'Erkek'}');
      buffer.writeln('Kilo: ${profile['weight'] ?? 70} kg');
    }

    buffer.writeln('Hedef: $goal');
    buffer.writeln('Fitness Seviyesi: $level');
    buffer.writeln('Haftalık Antrenman Günü: $days');

    if (profile?['preserve_muscle'] == true) {
      buffer.writeln('Özel Durum: KAS KÜTLESİ KORUMA AKTİF');
    }

    return buffer.toString();
  }

  // Fallback meal plan
  static Map<String, dynamic> _generateFallbackMealPlan(
      double calories, String goal, String diet, int daysPerWeek) {
    print('[ZindeAI] ⚠️ Fallback plan kullanılıyor');

    // Basit makro hesaplama
    final protein = calories * 0.3 / 4; // %30 protein
    final carbs = calories * 0.4 / 4; // %40 karb
    final fat = calories * 0.3 / 9; // %30 yağ

    // 7 günlük basit plan oluştur
    final days = List.generate(7, (index) {
    final dayNames = [
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar'
    ];

      return {
        'day': dayNames[index],
        'meals': [
          {
            'name': 'Kahvaltı',
            'time': '08:00',
            'description': 'Dengeli kahvaltı',
            'calories': calories * 0.25,
            'protein': protein * 0.25,
            'carbs': carbs * 0.25,
            'fat': fat * 0.25,
            'ingredients': [
              {'name': 'Yumurta', 'amount': '2', 'unit': 'adet'},
              {'name': 'Tam buğday ekmek', 'amount': '2', 'unit': 'dilim'},
              {'name': 'Peynir', 'amount': '50', 'unit': 'gram'},
            ],
          },
          {
            'name': 'Ara Öğün',
            'time': '10:30',
            'description': 'Hafif atıştırmalık',
            'calories': calories * 0.1,
            'protein': protein * 0.1,
            'carbs': carbs * 0.1,
            'fat': fat * 0.1,
            'ingredients': [
              {'name': 'Meyve', 'amount': '1', 'unit': 'adet'},
              {'name': 'Kuruyemiş', 'amount': '20', 'unit': 'gram'},
            ],
          },
          {
            'name': 'Öğle Yemeği',
            'time': '13:00',
            'description': 'Ana öğün',
            'calories': calories * 0.35,
            'protein': protein * 0.35,
            'carbs': carbs * 0.35,
            'fat': fat * 0.35,
            'ingredients': [
              {'name': 'Tavuk göğsü', 'amount': '150', 'unit': 'gram'},
              {'name': 'Pirinç', 'amount': '100', 'unit': 'gram'},
              {'name': 'Salata', 'amount': '200', 'unit': 'gram'},
            ],
          },
          {
            'name': 'Ara Öğün',
            'time': '16:00',
            'description': 'Protein atıştırmalığı',
            'calories': calories * 0.1,
            'protein': protein * 0.1,
            'carbs': carbs * 0.1,
            'fat': fat * 0.1,
            'ingredients': [
              {'name': 'Yoğurt', 'amount': '150', 'unit': 'gram'},
              {'name': 'Granola', 'amount': '30', 'unit': 'gram'},
            ],
          },
          {
            'name': 'Akşam Yemeği',
            'time': '19:00',
            'description': 'Hafif akşam öğünü',
            'calories': calories * 0.2,
            'protein': protein * 0.2,
            'carbs': carbs * 0.2,
            'fat': fat * 0.2,
            'ingredients': [
              {'name': 'Balık', 'amount': '120', 'unit': 'gram'},
              {'name': 'Sebze', 'amount': '250', 'unit': 'gram'},
              {'name': 'Zeytinyağı', 'amount': '10', 'unit': 'ml'},
            ],
          },
        ],
        'totals': {
          'calories': calories,
          'protein': protein,
          'carbs': carbs,
          'fat': fat,
        },
      };
    });

    return {
      'plan_name': 'Temel Beslenme Planı',
      'user_specs': {
        'goal': goal,
        'diet_type': diet,
      },
      'daily_macros': {
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
      },
      'days': days.take(daysPerWeek).toList(),
    };
  }

  // Fallback workout plan
  static Map<String, dynamic> _generateFallbackWorkoutPlan(
    String goal,
    String level,
    int daysPerWeek,
  ) {
    print('[ZindeAI] ⚠️ Fallback workout planı kullanılıyor');

    // Basit split belirle
    String splitType = daysPerWeek <= 3
        ? 'Full Body'
        : daysPerWeek == 4
            ? 'Upper/Lower'
            : 'Push/Pull/Legs';

    // Workouts oluştur
    final workouts = List.generate(daysPerWeek, (index) {
      List<Map<String, dynamic>> exercises = [];
      String dayName = '';
      String focus = '';

      if (splitType == 'Full Body') {
        dayName = 'Full Body ${index + 1}';
        focus = 'Tüm vücut';
        exercises = [
          {'name': 'Squat', 'sets': 4, 'reps': '8-10', 'rest': 180, 'rpe': 7},
          {
            'name': 'Bench Press',
            'sets': 4,
            'reps': '8-10',
            'rest': 180,
            'rpe': 7
          },
          {
            'name': 'Barbell Row',
            'sets': 4,
            'reps': '8-10',
            'rest': 120,
            'rpe': 7
          },
          {
            'name': 'Overhead Press',
            'sets': 3,
            'reps': '10-12',
            'rest': 120,
            'rpe': 6
          },
          {
            'name': 'Romanian Deadlift',
            'sets': 3,
            'reps': '10-12',
            'rest': 120,
            'rpe': 6
          },
        ];
      } else if (splitType == 'Upper/Lower') {
        if (index % 2 == 0) {
          dayName = 'Upper ${(index ~/ 2) + 1}';
          focus = 'Üst vücut';
          exercises = [
            {
              'name': 'Bench Press',
              'sets': 4,
              'reps': '6-8',
              'rest': 180,
              'rpe': 8
            },
            {
              'name': 'Pull-up',
              'sets': 4,
              'reps': '6-10',
              'rest': 120,
              'rpe': 7
            },
            {
              'name': 'Dumbbell Press',
          'sets': 3,
              'reps': '8-12',
              'rest': 90,
              'rpe': 7
            },
            {
              'name': 'Cable Row',
          'sets': 3,
              'reps': '10-12',
              'rest': 90,
              'rpe': 6
            },
            {
              'name': 'Lateral Raise',
          'sets': 3,
              'reps': '12-15',
          'rest': 60,
              'rpe': 6
        },
      ];
    } else {
          dayName = 'Lower ${((index - 1) ~/ 2) + 1}';
          focus = 'Alt vücut';
          exercises = [
            {'name': 'Squat', 'sets': 4, 'reps': '6-8', 'rest': 180, 'rpe': 8},
            {
              'name': 'Romanian Deadlift',
              'sets': 4,
              'reps': '8-10',
              'rest': 120,
              'rpe': 7
            },
            {
              'name': 'Leg Press',
              'sets': 3,
              'reps': '10-12',
              'rest': 90,
              'rpe': 7
            },
            {
              'name': 'Leg Curl',
              'sets': 3,
              'reps': '10-12',
              'rest': 60,
              'rpe': 6
            },
            {
              'name': 'Calf Raise',
              'sets': 3,
              'reps': '12-15',
              'rest': 60,
              'rpe': 6
            },
          ];
        }
      } else {
        // PPL
        final pplCycle = index % 3;
        if (pplCycle == 0) {
          dayName = 'Push ${(index ~/ 3) + 1}';
          focus = 'Göğüs, omuz, triceps';
          exercises = [
        {
          'name': 'Bench Press',
          'sets': 4,
              'reps': '6-8',
              'rest': 180,
              'rpe': 8
            },
            {
              'name': 'Overhead Press',
              'sets': 4,
              'reps': '8-10',
              'rest': 120,
              'rpe': 7
            },
            {
              'name': 'Incline Dumbbell Press',
              'sets': 3,
          'reps': '8-12',
          'rest': 90,
              'rpe': 7
            },
            {
              'name': 'Lateral Raise',
              'sets': 3,
              'reps': '12-15',
              'rest': 60,
              'rpe': 6
            },
            {
              'name': 'Tricep Extension',
              'sets': 3,
              'reps': '10-12',
              'rest': 60,
              'rpe': 6
            },
          ];
        } else if (pplCycle == 1) {
          dayName = 'Pull ${(index ~/ 3) + 1}';
          focus = 'Sırt, biceps';
          exercises = [
            {
              'name': 'Deadlift',
              'sets': 4,
              'reps': '5-6',
              'rest': 240,
              'rpe': 8
            },
            {
              'name': 'Pull-up',
          'sets': 4,
              'reps': '6-10',
              'rest': 120,
              'rpe': 7
            },
            {
              'name': 'Barbell Row',
              'sets': 3,
              'reps': '8-10',
          'rest': 90,
              'rpe': 7
            },
            {
              'name': 'Face Pull',
              'sets': 3,
              'reps': '12-15',
              'rest': 60,
              'rpe': 6
            },
            {
              'name': 'Barbell Curl',
          'sets': 3,
              'reps': '10-12',
              'rest': 60,
              'rpe': 6
            },
          ];
        } else {
          dayName = 'Legs ${(index ~/ 3) + 1}';
          focus = 'Bacak, kalça';
          exercises = [
            {'name': 'Squat', 'sets': 4, 'reps': '6-8', 'rest': 180, 'rpe': 8},
            {
              'name': 'Romanian Deadlift',
              'sets': 4,
              'reps': '8-10',
          'rest': 120,
              'rpe': 7
            },
            {
              'name': 'Leg Press',
              'sets': 3,
              'reps': '10-12',
              'rest': 90,
              'rpe': 7
            },
            {
              'name': 'Leg Curl',
              'sets': 3,
              'reps': '10-12',
              'rest': 60,
              'rpe': 6
            },
            {
              'name': 'Walking Lunge',
              'sets': 3,
              'reps': '10-12',
              'rest': 60,
              'rpe': 6
        },
      ];
    }
  }

      return {
        'day_number': index + 1,
        'day_name': dayName,
        'focus': focus,
        'exercises': exercises,
      };
    });

    return {
      'plan_name': '$daysPerWeek Günlük $level Antrenman Programı',
      'user_specs': {
        'goal': goal,
        'fitness_level': level,
        'workout_days': daysPerWeek,
      },
      'split_type': splitType,
      'workouts': workouts,
      'weekly_notes': [
        'Her antrenmandan önce 5-10 dakika ısınma yapın',
        'Form ve tekniğe odaklanın',
        'İlerleme kaydı tutun',
        'Dinlenme günlerinde hafif aktivite yapın',
      ],
    };
  }
}
