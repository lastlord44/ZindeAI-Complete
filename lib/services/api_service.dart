import 'package:dio/dio.dart';

class ApiService {
  static const String supabaseUrl = 'https://uhibpbwgvnvasxlvcohr.supabase.co';
  static const String supabaseKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVoaWJwYndndm52YXN4bHZjb2hyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzU0MDQ4NzIsImV4cCI6MjA1MDk4MDg3Mn0.8Q7Q7Q7Q7Q7Q7Q7Q7Q7Q7Q7Q7Q7Q7Q7Q7Q7Q7Q7Q';

  final Dio _dio;

  ApiService() : _dio = Dio() {
    _dio.options = BaseOptions(
      baseUrl: '$supabaseUrl/functions/v1',
      headers: {
        'Authorization': 'Bearer $supabaseKey',
        'Content-Type': 'application/json',
      },
      connectTimeout: Duration(seconds: 60),
      receiveTimeout: Duration(seconds: 60),
    );
  }

  // BESLENME PLANI İÇİN
  Future<Map<String, dynamic>> generateMealPlan(
      Map<String, dynamic> userProfile) async {
    try {
      print('Beslenme planı isteniyor: $userProfile');

      final response = await _dio.post(
        '/zindeai-router',
        data: {
          'requestType': 'plan', // Edge function'daki requestType
          'data': userProfile, // Edge function'daki data
        },
      );

      print('API Response: ${response.data}');

      if (response.data['success'] == true && response.data['plan'] != null) {
        return response.data['plan']; // Direkt plan objesini döndür
      } else {
        throw Exception('Beslenme planı oluşturulamadı');
      }
    } on DioException catch (e) {
      print('API Hatası: ${e.response?.data}');
      throw Exception('Beslenme planı hatası: ${e.message}');
    }
  }

  // ANTRENMAN PLANI İÇİN
  Future<Map<String, dynamic>> generateWorkoutPlan(
      Map<String, dynamic> userProfile) async {
    try {
      print('Antrenman planı isteniyor: $userProfile');

      final response = await _dio.post(
        '/zindeai-router',
        data: {
          'requestType': 'antrenman', // Edge function'daki requestType
          'data': userProfile, // Edge function'daki data
        },
      );

      print('API Response: ${response.data}');

      if (response.data['success'] == true &&
          response.data['antrenman'] != null) {
        return response.data['antrenman']; // Direkt antrenman objesini döndür
      } else {
        throw Exception('Antrenman planı oluşturulamadı');
      }
    } on DioException catch (e) {
      print('API Hatası: ${e.response?.data}');
      throw Exception('Antrenman planı hatası: ${e.message}');
    }
  }
}
