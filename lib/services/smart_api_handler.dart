// lib/services/smart_api_handler.dart

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'validation_service.dart';
import '../models/meal_plan.dart';
import '../models/workout_plan.dart';

/// Akıllı API Handler - Gemini öncelikli, Groq fallback
class SmartApiHandler {
  static final SmartApiHandler _instance = SmartApiHandler._internal();
  factory SmartApiHandler() => _instance;
  SmartApiHandler._internal();

  late Dio _dio;
  final ValidationService _validator = ValidationService();

  // API İstatistikleri
  final Map<String, int> _apiStats = {
    'gemini_success': 0,
    'gemini_failed': 0,
    'groq_success': 0,
    'groq_failed': 0,
    'total_requests': 0,
  };

  // Supabase client
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Handler'ı başlat
  Future<void> initialize() async {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Log interceptor ekle
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: false, // Response body çok uzun olabilir
      error: true,
    ));

    debugPrint('🚀 Smart API Handler başlatıldı');
  }

  /// Yemek planı oluştur - Akıllı fallback sistemi
  Future<MealPlan> createMealPlan({
    required int calories,
    required String goal,
    String diet = 'balanced',
    int daysPerWeek = 7,
    Map<String, dynamic>? preferences,
  }) async {
    _apiStats['total_requests'] = (_apiStats['total_requests'] ?? 0) + 1;

    // Input validasyonu yapılıyor
    _validator.validateAndCleanProfileData({
      'userId': 'current_user',
      'age': 30,
      'gender': 'Erkek',
      'weight': 70.0,
      'height': 175.0,
      'activityLevel': 'Orta',
      'fitnessLevel': 'Orta',
      'goal': goal,
    });

    final requestData = {
      'requestType': 'plan',
      'calories': calories,
      'goal': goal,
      'diet': diet,
      'daysPerWeek': 7, // Her zaman 7 gün
      'preferences': preferences ?? {},
    };

    try {
      // Önce Supabase Edge Function'ı dene
      final response = await _dio.post(
        'https://uhibpbwgvnvasxlvcohr.supabase.co/functions/v1/zindeai-router',
        data: requestData,
        options: Options(
          headers: {
            'Authorization':
                'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVoaWJwYndndm52YXN4bHZjb2hyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg1Mjg2MDMsImV4cCI6MjA3NDEwNDYwM30.kZLLAiRyWuFsr-Lb8qzR7KXoSoH_7AVtgEkK9sZEGj8',
            'apikey':
                'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVoaWJwYndndm52YXN4bHZjb2hyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg1Mjg2MDMsImV4cCI6MjA3NDEwNDYwM30.kZLLAiRyWuFsr-Lb8qzR7KXoSoH_7AVtgEkK9sZEGj8',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final mealPlan = MealPlan.fromJson(response.data);

        // Plan validasyonu
        if (_validator.validateMealPlan(response.data)) {
          debugPrint('✅ Supabase Edge Function başarılı');
          await _logApiCall('supabase_success', requestData, response.data);
          return mealPlan;
        } else {
          debugPrint('⚠️ Plan validasyonu başarısız, fallback deneniyor');
        }
      }
    } catch (e) {
      debugPrint('❌ Supabase Edge Function hatası: $e');
      await _logApiCall(
          'supabase_failed', requestData, {'error': e.toString()});
    }

    // Fallback: Yedek plan oluştur
    debugPrint('🔄 Fallback plan oluşturuluyor...');
    return _createFallbackMealPlan(calories, goal, diet);
  }

  /// Antrenman planı oluştur - Akıllı fallback sistemi
  Future<WorkoutPlan> createWorkoutPlan({
    required String userId,
    required int age,
    required String gender,
    required double weight,
    required double height,
    required String fitnessLevel,
    required String goal,
    required String mode,
    required int daysPerWeek,
    String? preferredSplit,
    List<String>? equipment,
    List<String>? injuries,
    int? timePerSession,
  }) async {
    _apiStats['total_requests'] = (_apiStats['total_requests'] ?? 0) + 1;

    // Input validasyonu yapılıyor
    _validator.validateAndCleanProfileData({
      'userId': userId,
      'age': age,
      'gender': gender,
      'weight': weight,
      'height': height,
      'activityLevel': 'Orta',
      'fitnessLevel': fitnessLevel,
      'goal': goal,
    });

    final requestData = {
      'requestType': 'antrenman',
      'userId': userId,
      'age': age,
      'gender': gender,
      'weight': weight,
      'height': height,
      'fitnessLevel': fitnessLevel,
      'goal': goal,
      'mode': mode,
      'daysPerWeek': daysPerWeek,
      'preferredSplit': preferredSplit,
      'equipment': equipment,
      'injuries': injuries,
      'timePerSession': timePerSession,
    };

    try {
      // Önce Supabase Edge Function'ı dene
      final response = await _dio.post(
        'https://uhibpbwgvnvasxlvcohr.supabase.co/functions/v1/zindeai-router',
        data: requestData,
        options: Options(
          headers: {
            'Authorization':
                'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVoaWJwYndndm52YXN4bHZjb2hyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg1Mjg2MDMsImV4cCI6MjA3NDEwNDYwM30.kZLLAiRyWuFsr-Lb8qzR7KXoSoH_7AVtgEkK9sZEGj8',
            'apikey':
                'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVoaWJwYndndm52YXN4bHZjb2hyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg1Mjg2MDMsImV4cCI6MjA3NDEwNDYwM30.kZLLAiRyWuFsr-Lb8qzR7KXoSoH_7AVtgEkK9sZEGj8',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final workoutPlan = WorkoutPlan.fromJson(response.data);
        debugPrint('✅ Supabase Edge Function başarılı');
        await _logApiCall('supabase_success', requestData, response.data);
        return workoutPlan;
      }
    } catch (e) {
      debugPrint('❌ Supabase Edge Function hatası: $e');
      await _logApiCall(
          'supabase_failed', requestData, {'error': e.toString()});
    }

    // Fallback: Yedek plan oluştur
    debugPrint('🔄 Fallback antrenman planı oluşturuluyor...');
    return _createFallbackWorkoutPlan(userId, age, gender, weight, height,
        fitnessLevel, goal, mode, daysPerWeek);
  }

  /// Yedek yemek planı oluştur
  MealPlan _createFallbackMealPlan(int calories, String goal, String diet) {
    final dayNames = [
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar'
    ];
    final meals = ['Kahvaltı', 'Öğle Yemeği', 'Akşam Yemeği', 'Ara Öğün'];

    final weeklyPlan = dayNames
        .map((day) => {
              'day': day,
              'meals': meals
                  .map((meal) => {
                        'mealName': meal,
                        'type': meal.toLowerCase().replaceAll(' ', '_'),
                        'calories': (calories / 4).round(),
                        'items': _getFallbackMealItems(meal)
                            .map((item) => {
                                  'itemName': item,
                                  'quantity': 100,
                                  'unit': 'gram',
                                  'calories': 200,
                                  'protein': 10,
                                  'carbs': 20,
                                  'fat': 5,
                                })
                            .toList(),
                        'notes':
                            'Yedek plan - API servisi geçici olarak kullanılamıyor',
                      })
                  .toList(),
            })
        .toList();

    return MealPlan(
      planTitle: 'Yedek Beslenme Planı',
      summary:
          'API servisi geçici olarak kullanılamıyor. Temel beslenme planı.',
      dailyPlan: weeklyPlan.map((day) => DailyPlan.fromJson(day)).toList(),
    );
  }

  /// Yedek antrenman planı oluştur
  WorkoutPlan _createFallbackWorkoutPlan(
      String userId,
      int age,
      String gender,
      double weight,
      double height,
      String fitnessLevel,
      String goal,
      String mode,
      int daysPerWeek) {
    final dayNames = [
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar'
    ];

    final days = dayNames
        .take(daysPerWeek)
        .map((day) => {
              'day': day,
              'focus': _getFallbackFocus(day, daysPerWeek),
              'exercises': _getFallbackExercises(fitnessLevel, mode),
              'warmup': '5 dakika hafif kardio',
              'cooldown': '5 dakika esneme',
              'totalTime': 45,
            })
        .toList();

    return WorkoutPlan(
      userId: userId,
      weekNumber: 1,
      splitType: _getSplitType(daysPerWeek),
      mode: mode,
      goal: goal,
      days: days.map((day) => WorkoutDay.fromJson(day)).toList(),
      progressionNotes:
          'Yedek plan - API servisi geçici olarak kullanılamıyor. Her hafta ağırlığı artırın.',
    );
  }

  /// Yedek yemek öğeleri
  List<String> _getFallbackMealItems(String meal) {
    switch (meal) {
      case 'Kahvaltı':
        return ['Yumurta', 'Peynir', 'Ekmek', 'Domates'];
      case 'Öğle Yemeği':
        return ['Tavuk Göğsü', 'Pilav', 'Salata'];
      case 'Akşam Yemeği':
        return ['Balık', 'Sebze Yemeği', 'Yoğurt'];
      case 'Ara Öğün':
        return ['Meyve', 'Badem'];
      default:
        return ['Sağlıklı Seçenek'];
    }
  }

  /// Yedek antrenman odak noktası
  String _getFallbackFocus(String day, int daysPerWeek) {
    if (daysPerWeek <= 3) {
      return 'Full Body';
    } else if (daysPerWeek <= 4) {
      return day == 'Pazartesi' || day == 'Perşembe'
          ? 'Üst Vücut'
          : 'Alt Vücut';
    } else {
      final focuses = [
        'Göğüs-Triceps',
        'Sırt-Biceps',
        'Bacak',
        'Omuz',
        'Kardio'
      ];
      final dayIndex =
          ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma'].indexOf(day);
      return dayIndex >= 0 ? focuses[dayIndex] : 'Genel Antrenman';
    }
  }

  /// Yedek egzersizler
  List<Map<String, dynamic>> _getFallbackExercises(
      String fitnessLevel, String mode) {
    if (mode == 'ev') {
      return [
        {
          'name': 'Push-up',
          'sets': 3,
          'reps': '10-15',
          'rest': 60,
          'notes': 'Ev antrenmanı'
        },
        {
          'name': 'Squat',
          'sets': 3,
          'reps': '15-20',
          'rest': 60,
          'notes': 'Ev antrenmanı'
        },
        {
          'name': 'Plank',
          'sets': 3,
          'reps': '30s',
          'rest': 60,
          'notes': 'Ev antrenmanı'
        },
      ];
    } else {
      return [
        {
          'name': 'Bench Press',
          'sets': 4,
          'reps': '8-12',
          'rest': 90,
          'notes': 'Spor salonu'
        },
        {
          'name': 'Squat',
          'sets': 4,
          'reps': '8-12',
          'rest': 90,
          'notes': 'Spor salonu'
        },
        {
          'name': 'Deadlift',
          'sets': 3,
          'reps': '5-8',
          'rest': 120,
          'notes': 'Spor salonu'
        },
      ];
    }
  }

  /// Split tipi belirle
  String _getSplitType(int daysPerWeek) {
    if (daysPerWeek <= 3) return 'Full Body';
    if (daysPerWeek <= 4) return 'Upper/Lower';
    return 'Push/Pull/Legs';
  }

  /// API çağrısını logla
  Future<void> _logApiCall(
      String status, Map<String, dynamic> request, dynamic response) async {
    try {
      await _supabase.from('api_logs').insert({
        'status': status,
        'request_data': request,
        'response_data': response,
        'timestamp': DateTime.now().toIso8601String(),
        'user_id': _supabase.auth.currentUser?.id,
      });
    } catch (e) {
      debugPrint('⚠️ API log kaydedilemedi: $e');
    }
  }

  /// API istatistiklerini al
  Map<String, dynamic> getStats() {
    return {
      ..._apiStats,
      'success_rate': (_apiStats['total_requests'] ?? 0) > 0
          ? (((_apiStats['gemini_success'] ?? 0) +
                      (_apiStats['groq_success'] ?? 0)) /
                  (_apiStats['total_requests'] ?? 1) *
                  100)
              .toStringAsFixed(1)
          : '0.0',
    };
  }

  /// İstatistikleri sıfırla
  void resetStats() {
    _apiStats.clear();
    _apiStats.addAll({
      'gemini_success': 0,
      'gemini_failed': 0,
      'groq_success': 0,
      'groq_failed': 0,
      'total_requests': 0,
    });
  }
}
