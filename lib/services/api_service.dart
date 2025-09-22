import 'package:dio/dio.dart';
import 'dart:convert';
import '../models/meal_plan.dart';
import '../models/workout_plan.dart';
import '../models/health_status.dart';
import '../models/exercise.dart';

class ApiService {
  static const String baseUrl =
      'https://uhibpbwgvnvasxlvcohr.supabase.co/functions/v1';
  final Dio _dio;

  ApiService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 30),
            headers: {
              'Content-Type': 'application/json',
              // Bu iki satır Supabase için zorunludur
              'Authorization':
                  'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVoaWJwYndndm52YXN4bHZjb2hyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg1Mjg2MDMsImV4cCI6MjA3NDEwNDYwM30.kZLLAiRyWuFsr-Lb8qzR7KXoSoH_7AVtgEkK9sZEGj8',
              'apikey':
                  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVoaWJwYndndm52YXN4bHZjb2hyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg1Mjg2MDMsImV4cCI6MjA3NDEwNDYwM30.kZLLAiRyWuFsr-Lb8qzR7KXoSoH_7AVtgEkK9sZEGj8',
            },
          ),
        ) {
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ));
  }

  // 1. Yemek Planı Oluştur
  Future<MealPlan> createMealPlan({
    required int calories,
    required String goal,
    String diet = 'balanced',
    int daysPerWeek = 7,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      print('Creating meal plan:');
      print('Calories: $calories');
      print('Goal: $goal');
      print('Diet: $diet');
      print('Days: $daysPerWeek');
      print('Preferences: $preferences');

      final response = await _dio.post('/zindeai-router', data: {
        'type': 'meal-plan',
        'calories': calories,
        'goal': goal,
        'diet': diet,
        'daysPerWeek': daysPerWeek,
        'preferences': preferences ?? {},
      });

      print('Response status: ${response.statusCode}');
      print('Response type: ${response.data.runtimeType}');
      print('Response data: ${response.data}');

      // Artık temizleme yok, çünkü cevap zaten temiz!
      return MealPlan.fromJson(response.data);
    } on DioException catch (e) {
      print('API Error: ${e.response?.statusCode}');
      print('Error data: ${e.response?.data}');
      throw _handleError(e);
    } catch (e) {
      print('Unexpected error: $e');
      throw 'Beklenmeyen hata: $e';
    }
  }

  // 2. Antrenman Planı Oluştur
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
    try {
      final response = await _dio.post('/zindeai-router', data: {
        'type': 'workout-plan',
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

      // Artık temizleme yok, çünkü cevap zaten temiz!
      return WorkoutPlan.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 3. Sağlık Kontrolü
  Future<HealthStatus> checkHealth() async {
    try {
      final response = await _dio.get('/health');
      return HealthStatus.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 4. GIF URL Al
  String getGifUrl(String exerciseId) {
    return '$baseUrl/gif/$exerciseId';
  }

  // 5. Adaptive Media URL Al
  String getMediaUrl(String exerciseId, {String format = 'gif'}) {
    return '$baseUrl/media/$exerciseId?format=$format';
  }

  // 6. Egzersiz Metadata Al
  Future<ExerciseMetadata> getExerciseMetadata(String exerciseId) async {
    try {
      final response = await _dio.get('/exercise/$exerciseId/meta');
      return ExerciseMetadata.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 7. Batch Egzersiz Kontrolü
  Future<BatchCheckResult> checkExercises(List<String> exerciseIds) async {
    try {
      final response = await _dio.post('/exercises/check', data: {
        'exerciseIds': exerciseIds,
      });
      return BatchCheckResult.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout) {
      return 'Bağlantı zaman aşımına uğradı';
    } else if (error.type == DioExceptionType.receiveTimeout) {
      return 'Yanıt zaman aşımına uğradı';
    } else if (error.type == DioExceptionType.connectionError) {
      return 'İnternet bağlantınızı kontrol edin';
    } else if (error.response != null) {
      final statusCode = error.response?.statusCode;
      final message =
          error.response?.data['message'] ?? error.response?.data['error'];
      return '$statusCode: ${message ?? 'Bir hata oluştu'}';
    }
    return 'Beklenmeyen bir hata oluştu';
  }
}
