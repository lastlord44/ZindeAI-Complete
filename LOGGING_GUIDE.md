# ZindeAI Log Sistemi Kullanım Kılavuzu

## 🎯 Genel Bakış

ZindeAI projesine kapsamlı bir log sistemi eklenmiştir. Bu sistem sayesinde:
- Tüm hataları kolayca tespit edebilirsiniz
- Performans sorunlarını izleyebilirsiniz
- Kullanıcı etkileşimlerini takip edebilirsiniz
- API çağrılarını detaylı olarak loglayabilirsiniz

## 📁 Log Sistemi Dosyaları

```
lib/
├── utils/
│   └── logger.dart              # Ana logger sınıfı
├── widgets/
│   └── error_boundary.dart      # Error boundary widget'ı
└── screens/
    └── log_viewer_screen.dart   # Log görüntüleme ekranı
```

## 🚀 Logger Kullanımı

### Temel Log Seviyeleri

```dart
import '../utils/logger.dart';

// Debug log - Geliştirme aşamasında detaylı bilgi
Logger.debug('Debug mesajı', tag: 'MyClass', data: {'key': 'value'});

// Info log - Genel bilgilendirme
Logger.info('Bilgi mesajı', tag: 'MyClass');

// Warning log - Dikkat edilmesi gereken durumlar
Logger.warning('Uyarı mesajı', tag: 'MyClass');

// Error log - Hata durumları
Logger.error('Hata mesajı', tag: 'MyClass', error: exception, stackTrace: stackTrace);

// Success log - Başarılı işlemler
Logger.success('Başarı mesajı', tag: 'MyClass');
```

### Özel Log Türleri

```dart
// API log'ları
Logger.api('API çağrısı', tag: 'ApiService', method: 'POST', url: '/api/endpoint');

// UI log'ları
Logger.ui('Ekran geçişi', screen: 'HomeScreen', action: 'navigate');

// Database log'ları
Logger.database('Veritabanı işlemi', operation: 'insert', tag: 'DatabaseService');

// Performance log'ları
Logger.performance('İşlem tamamlandı', durationMs: 150, tag: 'MyService');
```

### Performans Ölçümü

```dart
// Performans ölçümü başlat
Logger.performanceStart('myOperation');

// İşlem yap
await someOperation();

// Performans ölçümü bitir
Logger.performanceEnd('myOperation', data: {'result': 'success'});
```

### API Çağrıları

```dart
// API çağrısı başlangıcı
Logger.apiStart('POST', '/api/endpoint', requestData: requestData);

try {
  final response = await apiCall();
  
  // API çağrısı başarılı
  Logger.apiSuccess('POST', '/api/endpoint', 
      statusCode: response.statusCode, 
      responseData: response.data);
      
} catch (e) {
  // API çağrısı başarısız
  Logger.apiError('POST', '/api/endpoint', 
      statusCode: e.statusCode, 
      error: e.message);
}
```

### Kullanıcı Etkileşimleri

```dart
// Kullanıcı etkileşimi
Logger.userAction('Buton tıklandı', screen: 'HomeScreen', data: {'buttonId': 'submit'});

// Ekran geçişi
Logger.screenTransition('HomeScreen', 'ProfileScreen');
```

## 🛡️ Error Handling

### Global Error Handling

`main.dart` dosyasında global error handling kurulmuştur:

```dart
// Flutter hataları
FlutterError.onError = (FlutterErrorDetails details) {
  Logger.catchError(details.exception, details.stack ?? StackTrace.empty);
};

// Platform hataları
PlatformDispatcher.instance.onError = (error, stack) {
  Logger.catchError(error, stack);
  return true;
};
```

### Error Boundary Widget

```dart
import '../widgets/error_boundary.dart';

// Widget'ı error boundary ile sarmalama
withErrorBoundary(
  MyWidget(),
  tag: 'MyWidget',
  fallback: ErrorWidget(),
)
```

### Async Error Handling

```dart
import '../widgets/error_boundary.dart';

// Async işlemler için error handling
final result = await AsyncErrorHandler.handle(
  () => riskyOperation(),
  tag: 'MyOperation',
  fallback: defaultValue,
  logError: true,
);
```

## 📱 Log Görüntüleme

### Log Viewer Ekranı

Ana ekrandan "Log Görüntüleyici" butonuna tıklayarak log'ları görüntüleyebilirsiniz:

- **Filtreleme**: Log seviyesine göre filtreleme
- **Arama**: Log içeriğinde arama
- **Kopyalama**: Log'ları panoya kopyalama
- **Otomatik kaydırma**: Yeni log'ları otomatik gösterme

### Log Seviyeleri

- 🐛 **DEBUG**: Geliştirme aşamasında detaylı bilgi
- ℹ️ **INFO**: Genel bilgilendirme
- ⚠️ **WARNING**: Dikkat edilmesi gereken durumlar
- ❌ **ERROR**: Hata durumları
- ✅ **SUCCESS**: Başarılı işlemler
- 🌐 **API**: API çağrıları ve yanıtları
- 🗄️ **DATABASE**: Veritabanı işlemleri
- 🎨 **UI**: Kullanıcı arayüzü işlemleri
- 🔐 **AUTH**: Kimlik doğrulama işlemleri
- ⚡ **PERFORMANCE**: Performans ölçümleri

## 🔧 Backend Log'ları

### Supabase Edge Functions

Backend'de de kapsamlı log'lar eklenmiştir:

```typescript
// Timestamp ile log
const timestamp = new Date().toISOString();
console.log(`[${timestamp}] === FUNCTION CALLED ===`);

// Detaylı error logging
console.error(`[${timestamp}] Error type: ${error.constructor.name}`);
console.error(`[${timestamp}] Error message: ${error.message}`);
console.error(`[${timestamp}] Error stack: ${error.stack}`);
```

### Log Formatı

Tüm log'lar şu formatta yazılır:
```
[HH:mm:ss.SSS] [ZindeAI] LEVEL [TAG] MESSAGE
```

## 📊 Log İstatistikleri

### API İstatistikleri

SmartApiHandler'da API istatistikleri tutulur:

```dart
final stats = smartApiHandler.getStats();
// {
//   'total_requests': 10,
//   'gemini_success': 8,
//   'gemini_failed': 2,
//   'success_rate': '80.0'
// }
```

## 🎯 En İyi Uygulamalar

### 1. Tag Kullanımı
Her log'da anlamlı bir tag kullanın:
```dart
Logger.info('İşlem başladı', tag: 'UserService');
```

### 2. Data Parametresi
Önemli bilgileri data parametresinde geçin:
```dart
Logger.info('Kullanıcı girişi', tag: 'AuthService', data: {
  'userId': userId,
  'method': 'email',
});
```

### 3. Error Handling
Tüm try-catch bloklarında log kullanın:
```dart
try {
  await riskyOperation();
} catch (e, stackTrace) {
  Logger.error('İşlem başarısız', tag: 'MyService', error: e, stackTrace: stackTrace);
}
```

### 4. Performance Monitoring
Yavaş işlemlerde performans ölçümü yapın:
```dart
Logger.performanceStart('databaseQuery');
await database.query();
Logger.performanceEnd('databaseQuery');
```

## 🚨 Hata Ayıklama

### Yaygın Hatalar

1. **API Bağlantı Hataları**
   - Log'larda "API bağlantı hatası" arayın
   - Network durumunu kontrol edin

2. **Validation Hataları**
   - Log'larda "VALIDATION" arayın
   - Input verilerini kontrol edin

3. **Performance Sorunları**
   - Log'larda "PERFORMANCE" arayın
   - Yavaş işlemleri tespit edin

### Log Analizi

1. **Hata Sıklığı**: Aynı hatanın tekrar edip etmediğini kontrol edin
2. **Zaman Analizi**: Hataların ne zaman oluştuğunu analiz edin
3. **Kullanıcı Etkileşimi**: Hangi aksiyonların hata verdiğini tespit edin

## 📈 Gelecek Geliştirmeler

- [ ] Log'ları dosyaya kaydetme
- [ ] Remote log gönderimi
- [ ] Log analiz dashboard'u
- [ ] Otomatik hata raporlama
- [ ] Performance metrikleri

## 🤝 Katkıda Bulunma

Log sistemi sürekli geliştirilmektedir. Yeni özellikler veya iyileştirmeler için:

1. Logger sınıfına yeni metodlar ekleyin
2. Error boundary'yi genişletin
3. Log viewer'a yeni filtreler ekleyin
4. Backend log'larını iyileştirin

---

**Not**: Bu log sistemi development ve debugging amaçlıdır. Production'da log seviyelerini ayarlayın ve hassas bilgileri loglamayın.







