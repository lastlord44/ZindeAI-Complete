import 'package:dio/dio.dart';
import '../models/health_status.dart';
import '../models/exercise.dart';
import '../utils/logger.dart';
import 'smart_api_handler.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3002/api';
  final Dio _dio;

  ApiService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 30),
            headers: {
              'Content-Type': 'application/json',
              // Supabase API için basit header'lar
            },
          ),
        ) {
    Logger.info('ApiService başlatılıyor', tag: 'ApiService', data: {
      'baseUrl': baseUrl,
      'connectTimeout': '10s',
      'receiveTimeout': '30s',
    });

    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ));

    // Smart handler'ı başlat
    // SmartApiHandler zaten initialize edilmiş

    Logger.success('ApiService başarıyla başlatıldı', tag: 'ApiService');
  }

  // 1. Yemek Planı Oluştur - Smart Handler kullan
  Future<Map<String, dynamic>> createMealPlan({
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
    Logger.info('Yemek planı oluşturma isteği alındı',
        tag: 'ApiService',
        data: {
          'calories': calories,
          'goal': goal,
          'diet': diet,
          'daysPerWeek': daysPerWeek,
          'preferences': preferences,
        });

    try {
      Logger.debug('Smart API Handler ile yemek planı oluşturuluyor',
          tag: 'ApiService');

      // Smart handler kullan
      final mealPlan = await SmartApiHandler.generateMealPlan(
        calories: calories.toDouble(),
        goal: goal,
        diet: diet,
        daysPerWeek: daysPerWeek,
        fullProfile: {
          'age': age,
          'gender': sex,
          'weight': weight,
          'height': height,
          'activity_level': activity,
        },
      );

      Logger.success('Yemek planı başarıyla oluşturuldu',
          tag: 'ApiService',
          data: {
            'planTitle': mealPlan['plan_name'],
            'dailyPlanCount': mealPlan['days']?.length ?? 0,
          });

      Logger.performanceEnd('createMealPlan', data: {
        'calories': calories,
        'goal': goal,
        'diet': diet,
      });

      return mealPlan;
    } catch (e, stackTrace) {
      Logger.error('Yemek planı oluşturma hatası',
          tag: 'ApiService',
          error: e,
          stackTrace: stackTrace,
          data: {
            'calories': calories,
            'goal': goal,
            'diet': diet,
            'daysPerWeek': daysPerWeek,
          });

      Logger.performanceEnd('createMealPlan', data: {
        'error': e.toString(),
        'calories': calories,
        'goal': goal,
        'diet': diet,
      });

      throw 'Yemek planı oluşturulamadı: $e';
    }
  }

  // 2. Antrenman Planı Oluştur - Smart Handler kullan
  Future<Map<String, dynamic>> createWorkoutPlan({
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
    Logger.info('Antrenman planı oluşturma isteği alındı',
        tag: 'ApiService',
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

    try {
      Logger.debug('Smart API Handler ile antrenman planı oluşturuluyor',
          tag: 'ApiService');

      // Smart handler kullan
      final workoutPlan = await SmartApiHandler.generateWorkoutPlan(
        goal: goal,
        daysPerWeek: daysPerWeek,
        level: fitnessLevel,
        fullProfile: {
          'age': age,
          'gender': gender,
          'weight': weight,
          'height': height,
          'fitness_level': fitnessLevel,
        },
      );

      Logger.success('Antrenman planı başarıyla oluşturuldu',
          tag: 'ApiService',
          data: {
            'userId': userId,
            'planName': workoutPlan['plan_name'],
            'splitType': workoutPlan['split_type'],
            'daysCount': workoutPlan['weekly_schedule']?.length ?? 0,
          });

      Logger.performanceEnd('createWorkoutPlan', data: {
        'userId': userId,
        'goal': goal,
        'mode': mode,
        'daysPerWeek': daysPerWeek,
      });

      return workoutPlan;
    } catch (e, stackTrace) {
      Logger.error('Antrenman planı oluşturma hatası',
          tag: 'ApiService',
          error: e,
          stackTrace: stackTrace,
          data: {
            'userId': userId,
            'age': age,
            'gender': gender,
            'goal': goal,
            'mode': mode,
            'daysPerWeek': daysPerWeek,
          });

      Logger.performanceEnd('createWorkoutPlan', data: {
        'error': e.toString(),
        'userId': userId,
        'goal': goal,
        'mode': mode,
        'daysPerWeek': daysPerWeek,
      });

      throw 'Antrenman planı oluşturulamadı: $e';
    }
  }

  // 3. Sağlık Kontrolü
  Future<HealthStatus> checkHealth() async {
    Logger.apiStart('GET', '/health');

    try {
      final response = await _dio.get('/health');

      Logger.apiSuccess('GET', '/health',
          statusCode: response.statusCode, responseData: response.data);

      final healthStatus = HealthStatus.fromJson(response.data);

      Logger.success('Sağlık kontrolü başarılı', tag: 'ApiService', data: {
        'status': healthStatus.status,
        'message': healthStatus.message,
      });

      return healthStatus;
    } on DioException catch (e) {
      Logger.apiError('GET', '/health',
          statusCode: e.response?.statusCode,
          error: e.message,
          responseData: e.response?.data);

      final errorMessage = _handleError(e);
      Logger.error('Sağlık kontrolü hatası', tag: 'ApiService', error: e);
      throw errorMessage;
    } catch (e, stackTrace) {
      Logger.error('Sağlık kontrolü beklenmeyen hatası',
          tag: 'ApiService', error: e, stackTrace: stackTrace);
      throw 'Sağlık kontrolü yapılamadı: $e';
    }
  }

  // 4. GIF URL Al
  String getGifUrl(String exerciseId) {
    final url = '$baseUrl/gif/$exerciseId';
    Logger.debug('GIF URL oluşturuldu', tag: 'ApiService', data: {
      'exerciseId': exerciseId,
      'url': url,
    });
    return url;
  }

  // 5. Adaptive Media URL Al
  String getMediaUrl(String exerciseId, {String format = 'gif'}) {
    final url = '$baseUrl/media/$exerciseId?format=$format';
    Logger.debug('Media URL oluşturuldu', tag: 'ApiService', data: {
      'exerciseId': exerciseId,
      'format': format,
      'url': url,
    });
    return url;
  }

  // 6. Egzersiz Metadata Al
  Future<ExerciseMetadata> getExerciseMetadata(String exerciseId) async {
    Logger.apiStart('GET', '/exercise/$exerciseId/meta');

    try {
      final response = await _dio.get('/exercise/$exerciseId/meta');

      Logger.apiSuccess('GET', '/exercise/$exerciseId/meta',
          statusCode: response.statusCode, responseData: response.data);

      final metadata = ExerciseMetadata.fromJson(response.data);

      Logger.success('Egzersiz metadata alındı', tag: 'ApiService', data: {
        'exerciseId': exerciseId,
        'metadata': metadata.toJson(),
      });

      return metadata;
    } on DioException catch (e) {
      Logger.apiError('GET', '/exercise/$exerciseId/meta',
          statusCode: e.response?.statusCode,
          error: e.message,
          responseData: e.response?.data);

      final errorMessage = _handleError(e);
      Logger.error('Egzersiz metadata alma hatası',
          tag: 'ApiService', error: e);
      throw errorMessage;
    } catch (e, stackTrace) {
      Logger.error('Egzersiz metadata beklenmeyen hatası',
          tag: 'ApiService', error: e, stackTrace: stackTrace);
      throw 'Egzersiz metadata alınamadı: $e';
    }
  }

  // 7. Batch Egzersiz Kontrolü
  Future<BatchCheckResult> checkExercises(List<String> exerciseIds) async {
    Logger.apiStart('POST', '/exercises/check', requestData: {
      'exerciseIds': exerciseIds,
    });

    try {
      final response = await _dio.post('/exercises/check', data: {
        'exerciseIds': exerciseIds,
      });

      Logger.apiSuccess('POST', '/exercises/check',
          statusCode: response.statusCode, responseData: response.data);

      final result = BatchCheckResult.fromJson(response.data);

      Logger.success('Batch egzersiz kontrolü tamamlandı',
          tag: 'ApiService',
          data: {
            'exerciseIdsCount': exerciseIds.length,
            'exerciseIds': exerciseIds,
            'result': result.toJson(),
          });

      return result;
    } on DioException catch (e) {
      Logger.apiError('POST', '/exercises/check',
          statusCode: e.response?.statusCode,
          error: e.message,
          responseData: e.response?.data);

      final errorMessage = _handleError(e);
      Logger.error('Batch egzersiz kontrolü hatası',
          tag: 'ApiService', error: e);
      throw errorMessage;
    } catch (e, stackTrace) {
      Logger.error('Batch egzersiz kontrolü beklenmeyen hatası',
          tag: 'ApiService', error: e, stackTrace: stackTrace);
      throw 'Batch egzersiz kontrolü yapılamadı: $e';
    }
  }

  String _handleError(DioException error) {
    String errorMessage;

    if (error.type == DioExceptionType.connectionTimeout) {
      errorMessage = 'Bağlantı zaman aşımına uğradı';
      Logger.warning('API bağlantı zaman aşımı', tag: 'ApiService', data: {
        'errorType': 'connectionTimeout',
        'url': error.requestOptions.uri.toString(),
      });
    } else if (error.type == DioExceptionType.receiveTimeout) {
      errorMessage = 'Yanıt zaman aşımına uğradı';
      Logger.warning('API yanıt zaman aşımı', tag: 'ApiService', data: {
        'errorType': 'receiveTimeout',
        'url': error.requestOptions.uri.toString(),
      });
    } else if (error.type == DioExceptionType.connectionError) {
      errorMessage = 'İnternet bağlantınızı kontrol edin';
      Logger.warning('API bağlantı hatası', tag: 'ApiService', data: {
        'errorType': 'connectionError',
        'url': error.requestOptions.uri.toString(),
      });
    } else if (error.response != null) {
      final statusCode = error.response?.statusCode;
      final message =
          error.response?.data['message'] ?? error.response?.data['error'];
      errorMessage = '$statusCode: ${message ?? 'Bir hata oluştu'}';

      Logger.error('API HTTP hatası', tag: 'ApiService', data: {
        'statusCode': statusCode,
        'url': error.requestOptions.uri.toString(),
        'responseData': error.response?.data,
        'message': message,
      });
    } else {
      errorMessage = 'Beklenmeyen bir hata oluştu';
      Logger.error('API beklenmeyen hatası', tag: 'ApiService', data: {
        'errorType': error.type.toString(),
        'url': error.requestOptions.uri.toString(),
        'message': error.message,
      });
    }

    return errorMessage;
  }
}
