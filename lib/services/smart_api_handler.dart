// lib/services/smart_api_handler.dart

import 'dart:convert';
import 'package:dio/dio.dart';
// import 'package:supabase_flutter/supabase_flutter.dart'; // Supabase API kullanıyoruz
import 'validation_service.dart';
import '../models/meal_plan.dart';
import '../models/workout_plan.dart';
import '../utils/logger.dart';

/// Akıllı API Handler - Sadece Gemini kullanır
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
    'total_requests': 0,
  };

  // Supabase Edge Functions kullanıyoruz

  /// Handler'ı başlat
  Future<void> initialize() async {
    Logger.info('SmartApiHandler başlatılıyor', tag: 'SmartApiHandler', data: {
      'connectTimeout': '30s',
      'receiveTimeout': '60s',
    });

    _dio = Dio(BaseOptions(
      baseUrl: 'https://uhibpbwgvnvasxlvcohr.supabase.co/functions/v1/',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'apikey':
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVoaWJwYndndm52YXN4bHZjb2hyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzU0MDQ4NzIsImV4cCI6MjA1MDk4MDg3Mn0.8Q7Q7Q7Q7Q7Q7Q7Q7Q7Q7Q7Q7Q7Q7Q7Q7Q7Q7Q7Q',
      },
    ));

    // Log interceptor ekle
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: false, // Response body çok uzun olabilir
      error: true,
    ));

    Logger.success('Smart API Handler başarıyla başlatıldı',
        tag: 'SmartApiHandler');
  }

  /// API bağlantısını test et
  Future<void> testApiConnection() async {
    Logger.info('API bağlantısı test ediliyor', tag: 'SmartApiHandler');

    try {
      Logger.debug('Supabase API test çağrısı yapılıyor',
          tag: 'SmartApiHandler');

      // Supabase API kullan
      final response = await _dio.post(
        'zindeai-router',
        data: {
          'planType': 'meal',
          'goal': 'test',
          'age': 25,
          'sex': 'male',
          'weight_kg': 70,
          'height_cm': 175,
          'activity_level': 'moderate',
          'diet': 'balanced',
          'daysOfWeek': 1
        },
      );

      Logger.debug('API test yanıtı alındı', tag: 'SmartApiHandler', data: {
        'status': response.statusCode,
        'data': response.data,
      });

      if (response.statusCode == 200) {
        Logger.success('API bağlantı testi başarılı', tag: 'SmartApiHandler');
      } else {
        Logger.warning('API bağlantı testi başarısız',
            tag: 'SmartApiHandler',
            data: {
              'status': response.statusCode,
              'data': response.data,
            });
      }
    } catch (e) {
      Logger.error('API bağlantı testi hatası',
          tag: 'SmartApiHandler', data: {'error': e.toString()});
    }
  }

  /// Yemek planı oluştur - Akıllı fallback sistemi
  Future<MealPlan> createMealPlan({
    required int calories,
    required String goal,
    String diet = 'balanced',
    int daysPerWeek = 7,
    Map<String, dynamic>? preferences,
    // Profil bilgileri
    int? age,
    String? sex,
    double? weight,
    double? height,
    String? activity,
  }) async {
    Logger.performanceStart('createMealPlan');
    Logger.info('Yemek planı oluşturma başlatılıyor',
        tag: 'SmartApiHandler',
        data: {
          'calories': calories,
          'goal': goal,
          'diet': diet,
          'daysPerWeek': daysPerWeek,
          'preferences': preferences,
        });

    _apiStats['total_requests'] = (_apiStats['total_requests'] ?? 0) + 1;

    // Input validasyonu yapılıyor
    Logger.debug('Input validasyonu başlıyor', tag: 'SmartApiHandler');
    try {
      _validator.validateAndCleanProfileData({
        'userId': 'user_${DateTime.now().millisecondsSinceEpoch}',
        'age': 30,
        'gender': 'Erkek',
        'weight': 70.0,
        'height': 175.0,
        'activityLevel': 'Orta',
        'fitnessLevel': 'Orta',
        'goal': goal,
      });
      Logger.success('Input validasyonu tamamlandı', tag: 'SmartApiHandler');
    } catch (e) {
      Logger.warning('Input validasyonu hatası',
          tag: 'SmartApiHandler', data: {'error': e.toString()});
    }

    final requestData = {
      'planType': 'meal', // Backend için planType ekle
      'calories': calories,
      'goal': goal,
      'diet': diet,
      'daysPerWeek': 7, // Her zaman 7 gün
      'preferences': preferences ?? {},
      // Profil bilgileri
      'age': age ?? 25,
      'sex': sex ?? 'erkek',
      'weight': weight ?? 70.0,
      'height': height ?? 175.0,
      'activity': activity ?? 'orta',
    };

    try {
      // Önce Supabase API'ı dene
      Logger.debug('Supabase API çağrısı yapılıyor',
          tag: 'SmartApiHandler',
          data: {
            'function': 'zindeai-router',
            'requestData': requestData,
          });

      print('=== FLUTTER API ÇAĞRISI BAŞLADI ===');
      print('Request data: ${jsonEncode(requestData)}');
      print('Base URL: ${_dio.options.baseUrl}');
      print('Headers: ${_dio.options.headers}');

      // Supabase API kullan
      final response = await _dio.post(
        'zindeai-router',
        data: requestData,
      );

      print('=== FLUTTER API RESPONSE ALINDI ===');
      print('Response status: ${response.statusCode}');
      print('Response data: ${response.data}');

      Logger.debug('Supabase API yanıtı alındı', tag: 'SmartApiHandler', data: {
        'status': response.statusCode,
        'hasData': response.data != null,
      });

      if (response.statusCode == 200 && response.data != null) {
        // Backend'den gelen response formatını kontrol et
        Logger.debug('Backend response formatı kontrol ediliyor',
            tag: 'SmartApiHandler',
            data: {
              'responseKeys': response.data.keys.toList(),
              'hasSuccess': response.data.containsKey('success'),
              'hasData': response.data.containsKey('data'),
            });

        // TIP KONTROLÜ VE DÖNÜŞTÜRME
        dynamic responseData = response.data;

        // 1. String ise JSON parse et
        if (responseData is String) {
          try {
            responseData = jsonDecode(responseData);
            print('✅ String response JSON\'a parse edildi');
          } catch (e) {
            print('❌ JSON parse hatası: $e');
            throw Exception('Invalid JSON response: $responseData');
          }
        }

        // 2. Map değilse hata fırlat
        if (responseData is! Map<String, dynamic>) {
          print('❌ Response Map değil: ${responseData.runtimeType}');

          // Eğer data field'ı varsa onu kullan
          if (responseData is Map && responseData.containsKey('data')) {
            responseData = responseData['data'];
          } else {
            throw Exception('Invalid response format');
          }
        }

        Map<String, dynamic> actualMealData =
            responseData as Map<String, dynamic>;

        Logger.debug('Meal plan data parse ediliyor',
            tag: 'SmartApiHandler',
            data: {
              'actualDataKeys': actualMealData.keys.toList(),
              'weeklyPlan': actualMealData['weeklyPlan'],
              'weeklyPlanType':
                  actualMealData['weeklyPlan']?.runtimeType.toString(),
              'weeklyPlanCount': actualMealData['weeklyPlan']?.length,
            });

        final mealPlan = MealPlan.fromJson(actualMealData);

        // Plan validasyonu
        Logger.debug('Meal plan validasyonu yapılıyor', tag: 'SmartApiHandler');
        if (_validator.validateMealPlan(actualMealData)) {
          Logger.success('Gemini ile yemek planı başarıyla oluşturuldu',
              tag: 'SmartApiHandler',
              data: {
                'planTitle': mealPlan.planTitle,
                'dailyPlanCount': mealPlan.dailyPlan.length,
              });

          await _logApiCall('nodejs_success', requestData, response.data);

          Logger.performanceEnd('createMealPlan', data: {
            'method': 'gemini',
            'calories': calories,
            'goal': goal,
            'diet': diet,
          });

          return mealPlan;
        } else {
          Logger.warning('Meal plan validasyonu başarısız',
              tag: 'SmartApiHandler');
          throw Exception('Meal plan validasyonu başarısız');
        }
      } else {
        Logger.warning('Supabase API başarısız yanıt',
            tag: 'SmartApiHandler',
            data: {
              'status': response.statusCode,
              'data': response.data,
            });
        throw Exception('Supabase API başarısız yanıt: ${response.statusCode}');
      }
    } catch (e) {
      print('=== FLUTTER API HATASI ===');
      print('Error type: ${e.runtimeType}');
      print('Error message: ${e.toString()}');
      print('Request data: ${jsonEncode(requestData)}');

      Logger.error('Supabase API hatası', tag: 'SmartApiHandler', data: {
        'error': e.toString(),
        'requestData': requestData,
      });

      await _logApiCall('nodejs_failed', requestData, {'error': e.toString()});

      // Hata durumunda exception fırlat
      Logger.error('Yemek planı oluşturulamadı', tag: 'SmartApiHandler', data: {
        'calories': calories,
        'goal': goal,
        'diet': diet,
        'error': e.toString(),
      });

      throw Exception('Yemek planı oluşturulamadı: ${e.toString()}');
    }
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
    Logger.performanceStart('createWorkoutPlan');
    Logger.info('Antrenman planı oluşturma başlatılıyor',
        tag: 'SmartApiHandler',
        data: {
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
        });

    _apiStats['total_requests'] = (_apiStats['total_requests'] ?? 0) + 1;

    // Input validasyonu yapılıyor
    Logger.debug('Input validasyonu başlıyor', tag: 'SmartApiHandler');
    try {
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
      Logger.success('Input validasyonu tamamlandı', tag: 'SmartApiHandler');
    } catch (e) {
      Logger.warning('Input validasyonu hatası',
          tag: 'SmartApiHandler', data: {'error': e.toString()});
    }

    final requestData = {
      'planType': 'workout', // Backend için planType ekle
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
      // Önce Supabase API'ı dene
      Logger.debug('Supabase API çağrısı yapılıyor',
          tag: 'SmartApiHandler',
          data: {
            'function': 'zindeai-router',
            'requestData': requestData,
          });

      print('=== FLUTTER API ÇAĞRISI BAŞLADI ===');
      print('Request data: ${jsonEncode(requestData)}');
      print('Base URL: ${_dio.options.baseUrl}');
      print('Headers: ${_dio.options.headers}');

      // Supabase API kullan
      final response = await _dio.post(
        'zindeai-router',
        data: requestData,
      );

      print('=== FLUTTER API RESPONSE ALINDI ===');
      print('Response status: ${response.statusCode}');
      print('Response data: ${response.data}');

      Logger.debug('Supabase API yanıtı alındı', tag: 'SmartApiHandler', data: {
        'status': response.statusCode,
        'hasData': response.data != null,
      });

      if (response.statusCode == 200 && response.data != null) {
        // Response data'yı güvenli şekilde parse et
        Map<String, dynamic> actualWorkoutData;
        if (response.data is Map<String, dynamic>) {
          actualWorkoutData = response.data as Map<String, dynamic>;
        } else if (response.data is String) {
          actualWorkoutData =
              Map<String, dynamic>.from(jsonDecode(response.data as String));
        } else {
          final dataString = response.data.toString();
          actualWorkoutData = Map<String, dynamic>.from(jsonDecode(dataString));
        }

        Logger.debug('Workout plan data parse ediliyor',
            tag: 'SmartApiHandler',
            data: {
              'dataKeys': actualWorkoutData.keys.toList(),
              'hasData': actualWorkoutData.containsKey('data'),
              'dataContent':
                  actualWorkoutData['data']?.toString().substring(0, 200),
            });

        // API yanıtı data içinde, onu parse et
        final workoutData =
            actualWorkoutData['data'] as Map<String, dynamic>? ??
                actualWorkoutData;
        final workoutPlan = WorkoutPlan.fromJson(workoutData);

        Logger.success('Gemini ile antrenman planı başarıyla oluşturuldu',
            tag: 'SmartApiHandler',
            data: {
              'userId': userId,
              'weekNumber': workoutPlan.weekNumber,
              'splitType': workoutPlan.splitType,
              'mode': workoutPlan.mode,
              'daysCount': workoutPlan.days.length,
            });

        await _logApiCall('nodejs_success', requestData, response.data);

        Logger.performanceEnd('createWorkoutPlan', data: {
          'method': 'gemini',
          'userId': userId,
          'goal': goal,
          'mode': mode,
          'daysPerWeek': daysPerWeek,
        });

        return workoutPlan;
      } else {
        Logger.warning('Supabase API başarısız yanıt',
            tag: 'SmartApiHandler',
            data: {
              'status': response.statusCode,
              'data': response.data,
            });
        throw Exception('Supabase API başarısız yanıt: ${response.statusCode}');
      }
    } catch (e) {
      print('=== FLUTTER API HATASI ===');
      print('Error type: ${e.runtimeType}');
      print('Error message: ${e.toString()}');
      print('Request data: ${jsonEncode(requestData)}');

      Logger.error('Supabase API hatası', tag: 'SmartApiHandler', data: {
        'error': e.toString(),
        'requestData': requestData,
      });

      await _logApiCall('nodejs_failed', requestData, {'error': e.toString()});

      // Hata durumunda exception fırlat
      Logger.error('Antrenman planı oluşturulamadı',
          tag: 'SmartApiHandler',
          data: {
            'userId': userId,
            'goal': goal,
            'mode': mode,
            'daysPerWeek': daysPerWeek,
            'error': e.toString(),
          });

      throw Exception('Antrenman planı oluşturulamadı: ${e.toString()}');
    }
  }

  /// Yedek yemek planı oluştur - KALDIRILDI
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

  /// Yedek antrenman planı oluştur - KALDIRILDI
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
      Logger.debug('API çağrısı loglanıyor', tag: 'SmartApiHandler', data: {
        'status': status,
        'requestKeys': request.keys.toList(),
        'responseType': response.runtimeType.toString(),
      });

      // Status string'ini integer'a çevir (şu an kullanılmıyor)
      // int statusCode = 200; // Default success
      // if (status == 'nodejs_failed') {
      //   statusCode = 500;
      // } else if (status == 'nodejs_success') {
      //   statusCode = 200;
      // }

      // API log kaydetmeyi geçici olarak devre dışı bırak
      // await _supabase.from('api_logs').insert({
      //   'status_code': statusCode,
      //   'requests': request,
      //   'responses': response,
      //   'user_id': _supabase.auth.currentUser?.id,
      // });

      Logger.success('API çağrısı başarıyla loglandı', tag: 'SmartApiHandler');
    } catch (e) {
      // Tablo yoksa sessizce devam et, sadece debug'da göster
      Logger.warning('API log tablosu bulunamadı, log kaydedilmedi',
          tag: 'SmartApiHandler', data: {'error': e.toString()});
    }
  }

  /// API istatistiklerini al
  Map<String, dynamic> getStats() {
    final stats = {
      ..._apiStats,
      'success_rate': (_apiStats['total_requests'] ?? 0) > 0
          ? (((_apiStats['gemini_success'] ?? 0) + 0) /
                  (_apiStats['total_requests'] ?? 1) *
                  100)
              .toStringAsFixed(1)
          : '0.0',
    };

    Logger.debug('API istatistikleri alındı',
        tag: 'SmartApiHandler', data: stats);
    return stats;
  }

  /// İstatistikleri sıfırla
  void resetStats() {
    Logger.info('API istatistikleri sıfırlanıyor',
        tag: 'SmartApiHandler',
        data: {
          'previousStats': _apiStats,
        });

    _apiStats.clear();
    _apiStats.addAll({
      'gemini_success': 0,
      'gemini_failed': 0,
      'total_requests': 0,
    });

    Logger.success('API istatistikleri başarıyla sıfırlandı',
        tag: 'SmartApiHandler');
  }
}
