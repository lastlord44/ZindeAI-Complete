import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Kapsamlı Log Sistemi
/// Tüm uygulama boyunca tutarlı log'lar için kullanılır
class Logger {
  static const String _appName = 'ZindeAI';
  
  // Log seviyeleri
  static const String _levelDebug = '🐛 DEBUG';
  static const String _levelInfo = 'ℹ️ INFO';
  static const String _levelWarning = '⚠️ WARNING';
  static const String _levelError = '❌ ERROR';
  static const String _levelSuccess = '✅ SUCCESS';
  static const String _levelApi = '🌐 API';
  static const String _levelDatabase = '🗄️ DATABASE';
  static const String _levelUI = '🎨 UI';
  static const String _levelAuth = '🔐 AUTH';
  static const String _levelPerformance = '⚡ PERFORMANCE';

  /// Debug log - Geliştirme aşamasında detaylı bilgi
  static void debug(String message, {String? tag, Map<String, dynamic>? data}) {
    _log(_levelDebug, message, tag: tag, data: data);
  }

  /// Info log - Genel bilgilendirme
  static void info(String message, {String? tag, Map<String, dynamic>? data}) {
    _log(_levelInfo, message, tag: tag, data: data);
  }

  /// Warning log - Dikkat edilmesi gereken durumlar
  static void warning(String message, {String? tag, Map<String, dynamic>? data}) {
    _log(_levelWarning, message, tag: tag, data: data);
  }

  /// Error log - Hata durumları
  static void error(String message, {String? tag, Map<String, dynamic>? data, Object? error, StackTrace? stackTrace}) {
    _log(_levelError, message, tag: tag, data: data, error: error, stackTrace: stackTrace);
  }

  /// Success log - Başarılı işlemler
  static void success(String message, {String? tag, Map<String, dynamic>? data}) {
    _log(_levelSuccess, message, tag: tag, data: data);
  }

  /// API log - API çağrıları ve yanıtları
  static void api(String message, {String? tag, Map<String, dynamic>? data, String? method, String? url, int? statusCode}) {
    final apiData = <String, dynamic>{
      if (method != null) 'method': method,
      if (url != null) 'url': url,
      if (statusCode != null) 'statusCode': statusCode,
      if (data != null) ...data,
    };
    _log(_levelApi, message, tag: tag, data: apiData.isNotEmpty ? apiData : null);
  }

  /// Database log - Veritabanı işlemleri
  static void database(String message, {String? tag, Map<String, dynamic>? data, String? operation}) {
    final dbData = <String, dynamic>{
      if (operation != null) 'operation': operation,
      if (data != null) ...data,
    };
    _log(_levelDatabase, message, tag: tag, data: dbData.isNotEmpty ? dbData : null);
  }

  /// UI log - Kullanıcı arayüzü işlemleri
  static void ui(String message, {String? tag, Map<String, dynamic>? data, String? screen, String? action}) {
    final uiData = <String, dynamic>{
      if (screen != null) 'screen': screen,
      if (action != null) 'action': action,
      if (data != null) ...data,
    };
    _log(_levelUI, message, tag: tag, data: uiData.isNotEmpty ? uiData : null);
  }

  /// Auth log - Kimlik doğrulama işlemleri
  static void auth(String message, {String? tag, Map<String, dynamic>? data, String? action}) {
    final authData = <String, dynamic>{
      if (action != null) 'action': action,
      if (data != null) ...data,
    };
    _log(_levelAuth, message, tag: tag, data: authData.isNotEmpty ? authData : null);
  }

  /// Performance log - Performans ölçümleri
  static void performance(String message, {String? tag, Map<String, dynamic>? data, int? durationMs}) {
    final perfData = <String, dynamic>{
      if (durationMs != null) 'durationMs': durationMs,
      if (data != null) ...data,
    };
    _log(_levelPerformance, message, tag: tag, data: perfData.isNotEmpty ? perfData : null);
  }

  /// Ana log fonksiyonu
  static void _log(String level, String message, {
    String? tag,
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    // final timestamp = DateFormat('HH:mm:ss.SSS').format(DateTime.now());
    final tagStr = tag != null ? '[$tag]' : '';
    final logMessage = '[$_appName] $level $tagStr $message';
    
    // Debug mode'da detaylı log
    if (kDebugMode) {
      print(logMessage);
      
      if (data != null && data.isNotEmpty) {
        print('  📊 Data: $data');
      }
      
      if (error != null) {
        print('  💥 Error: $error');
      }
      
      if (stackTrace != null) {
        print('  📍 StackTrace: $stackTrace');
      }
    }
    
    // Developer log (Flutter Inspector'da görünür)
    developer.log(
      message,
      name: '$_appName.$level',
      time: DateTime.now(),
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// API çağrısı başlangıcı
  static void apiStart(String method, String url, {Map<String, dynamic>? requestData}) {
    api('API çağrısı başlatıldı', 
        method: method, 
        url: url, 
        data: requestData);
  }

  /// API çağrısı başarılı
  static void apiSuccess(String method, String url, {int? statusCode, Map<String, dynamic>? responseData}) {
    api('API çağrısı başarılı', 
        method: method, 
        url: url, 
        statusCode: statusCode,
        data: responseData);
  }

  /// API çağrısı başarısız
  static void apiError(String method, String url, {int? statusCode, String? error, Map<String, dynamic>? responseData}) {
    api('API çağrısı başarısız', 
        method: method, 
        url: url, 
        statusCode: statusCode,
        data: {
          'error': error,
          if (responseData != null) ...responseData,
        });
  }

  /// Ekran geçişi
  static void screenTransition(String fromScreen, String toScreen, {Map<String, dynamic>? data}) {
    ui('Ekran geçişi', 
        screen: toScreen, 
        data: {
          'from': fromScreen,
          'to': toScreen,
          if (data != null) ...data,
        });
  }

  /// Kullanıcı etkileşimi
  static void userAction(String action, {String? screen, Map<String, dynamic>? data}) {
    ui('Kullanıcı etkileşimi', 
        screen: screen, 
        action: action, 
        data: data);
  }

  /// Performans ölçümü başlat
  static DateTime _performanceStartTime = DateTime.now();
  
  static void performanceStart(String operation) {
    _performanceStartTime = DateTime.now();
    performance('Performans ölçümü başlatıldı', tag: operation);
  }
  
  static void performanceEnd(String operation, {Map<String, dynamic>? data}) {
    final duration = DateTime.now().difference(_performanceStartTime);
    performance('Performans ölçümü tamamlandı', 
        tag: operation, 
        durationMs: duration.inMilliseconds,
        data: data);
  }

  /// Exception yakalama
  static void catchError(Object error, StackTrace stackTrace, {String? tag, Map<String, dynamic>? data}) {
    _log(_levelError, 'Exception yakalandı', 
        tag: tag, 
        error: error, 
        stackTrace: stackTrace, 
        data: data);
  }

  /// Network durumu
  static void networkStatus(String status, {Map<String, dynamic>? data}) {
    api('Network durumu: $status', data: data);
  }

  /// Cache işlemleri
  static void cache(String operation, {String? key, Map<String, dynamic>? data}) {
    database('Cache işlemi: $operation', 
        operation: operation, 
        data: {
          if (key != null) 'key': key,
          if (data != null) ...data,
        });
  }

  /// Validation hataları
  static void validation(String field, String error, {Map<String, dynamic>? data}) {
    warning('Validation hatası: $field - $error', data: data);
  }

  /// Business logic hataları
  static void businessLogic(String operation, String error, {Map<String, dynamic>? data}) {
    _log(_levelError, 'Business logic hatası: $operation - $error', data: data);
  }
}
