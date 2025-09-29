import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
// import 'package:supabase_flutter/supabase_flutter.dart'; // Supabase API kullanıyoruz
import 'package:intl/date_symbol_data_local.dart'; // BUNU EKLE
import 'package:intl/intl.dart'; // BUNU EKLE
import 'screens/profile_screen.dart';
import 'services/api_service.dart';
import 'utils/logger.dart';

void main() async {
  Logger.info('Uygulama başlatılıyor', tag: 'Main');

  WidgetsFlutterBinding.ensureInitialized();

  // Global error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    Logger.catchError(
      details.exception,
      details.stack ?? StackTrace.empty,
      tag: 'FlutterError',
      data: {
        'library': details.library,
        'context': details.context?.toString(),
        'informationCollector': details.informationCollector?.toString(),
      },
    );
  };

  // Platform error handling
  ServicesBinding.instance.platformDispatcher.onError = (error, stack) {
    Logger.catchError(
      error,
      stack,
      tag: 'PlatformError',
    );
    return true;
  };

  // LOCALE İNİTİALİZE ET
  Logger.debug('Locale başlatılıyor', tag: 'Main', data: {
    'locale': 'tr_TR',
  });

  await initializeDateFormatting('tr_TR', null);
  Intl.defaultLocale = 'tr_TR';
  Logger.success('Locale başarıyla başlatıldı', tag: 'Main');

  // Supabase Edge Functions kullanıyoruz
  Logger.info('Supabase API kullanılıyor', tag: 'Main', data: {
    'url': 'https://uhibpbwgvnvasxlvcohr.supabase.co/functions/v1/',
  });

  Logger.success('Supabase API bağlantısı hazır', tag: 'Main');

  Logger.info('ZindeAIApp başlatılıyor', tag: 'Main');
  runApp(const ZindeAIApp());
}

class ZindeAIApp extends StatelessWidget {
  const ZindeAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    Logger.ui('ZindeAIApp build ediliyor', screen: 'ZindeAIApp');

    return MultiProvider(
      providers: [
        Provider(create: (_) => ApiService()),
      ],
      child: MaterialApp(
        title: 'ZindeAI Test',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.green,
          primaryColor: const Color(0xFF4CAF50),
          scaffoldBackgroundColor: const Color(0xFFF5F5F5),
          appBarTheme: const AppBarTheme(
            elevation: 0,
            centerTitle: true,
            backgroundColor: Color(0xFF4CAF50),
            foregroundColor: Colors.white,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        home: const ProfileScreen(),
      ),
    );
  }
}
