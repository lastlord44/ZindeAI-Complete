import 'package:dio/dio.dart';
import 'hybrid_meal_ai.dart';

class ApiService {
  static const String supabaseUrl = 'https://uhibpbwgvnvasxlvcohr.supabase.co';
  static const String supabaseKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVoaWJwYndndm52YXN4bHZjb2hyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzU0MDQ4NzIsImV4cCI6MjA1MDk4MDg3Mn0.8Q7Q7Q7Q7Q7Q7Q7Q7Q7Q7Q7Q7Q7Q7Q7Q7Q7Q7Q7Q';

  final Dio theDio;
  late final HybridMealAI _hybridMealAI;

  ApiService() : theDio = Dio() {
    theDio.options = BaseOptions(
      baseUrl: supabaseUrl,
      headers: {
        'Authorization': 'Bearer $supabaseKey',
        'Content-Type': 'application/json',
      },
      connectTimeout: Duration(seconds: 60),
      receiveTimeout: Duration(seconds: 60),
    );

    // Hibrit AI'yi başlat
    _hybridMealAI = HybridMealAI(
      dio: theDio,
      supabaseUrl: supabaseUrl,
    );
  }

  // BESLENME PLANI İÇİN - HİBRİT SİSTEM
  Future<Map<String, dynamic>> generateMealPlan(
      Map<String, dynamic> userProfile) async {
    print('🤖 Hibrit sistem ile beslenme planı isteniyor: $userProfile');

    // Hibrit AI'yi kullan
    final result = await _hybridMealAI.generateMealPlan(
      userProfile: userProfile,
    );

    print(
        '📊 Hibrit sonuç: ${result['source']}, fallback: ${result['fallback']}');

    // Fallback durumu varsa ek bilgi ver
    if (result['fallback'] == true) {
      print('⚠️ Offline mod aktif - Local database kullanılıyor');
    }

    // Gemini formatında döndür (UI uyumlu)
    return {
      'plan': result['plan'],
      'isFallback': result['fallback'] ?? false,
      'fallbackMessage': result['fallback_message'],
      'source': result['source'],
    };
  }

  // ANTRENMAN PLANI İÇİN
  Future<Map<String, dynamic>> generateWorkoutPlan(
      Map<String, dynamic> userProfile) async {
    try {
      print('Antrenman planı isteniyor: $userProfile');

      final response = await theDio.post(
        '/functions/v1/zindeai-router',
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
