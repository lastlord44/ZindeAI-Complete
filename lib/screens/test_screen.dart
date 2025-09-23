// lib/screens/test_screen.dart

import 'package:flutter/material.dart';
import '../services/smart_api_handler.dart';
import '../services/validation_service.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final SmartApiHandler _apiHandler = SmartApiHandler();
  final ValidationService _validator = ValidationService();

  List<TestResult> _testResults = [];
  bool _isRunning = false;
  String _currentTest = '';

  @override
  void initState() {
    super.initState();
    _initializeApiHandler();
  }

  Future<void> _initializeApiHandler() async {
    await _apiHandler.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧪 ZindeAI Test Sistemi'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Test Butonları
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isRunning ? null : () => _runAllTests(),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Tüm Testleri Çalıştır'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _testApiConnection,
                        icon: const Icon(Icons.api),
                        label: const Text('API Test'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _isRunning ? null : () => _runMealPlanTests(),
                  icon: const Icon(Icons.restaurant),
                  label: const Text('Yemek Planı Testleri'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isRunning ? null : () => _runWorkoutTests(),
                  icon: const Icon(Icons.fitness_center),
                  label: const Text('Antrenman Testleri'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isRunning ? null : () => _runValidationTests(),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Validasyon Testleri'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _clearResults,
                  icon: const Icon(Icons.clear),
                  label: const Text('Temizle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // API İstatistikleri
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📊 API İstatistikleri',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<Map<String, dynamic>>(
                      future: Future.value(_apiHandler.getStats()),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final stats = snapshot.data!;
                          return Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                      'Toplam İstek: ${stats['total_requests']}'),
                                  Text(
                                      'Başarı Oranı: %${stats['success_rate']}'),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                      'Supabase Başarılı: ${stats['gemini_success']}'),
                                  Text(
                                      'Supabase Başarısız: ${stats['gemini_failed']}'),
                                ],
                              ),
                            ],
                          );
                        }
                        return const Text('İstatistikler yükleniyor...');
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Test Durumu
            if (_isRunning)
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Test çalışıyor: $_currentTest',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Test Sonuçları
            Expanded(
              child: Card(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '📋 Test Sonuçları',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text('${_testResults.length} test'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _testResults.length,
                        itemBuilder: (context, index) {
                          final result = _testResults[index];
                          return ListTile(
                            leading: Icon(
                              result.success ? Icons.check_circle : Icons.error,
                              color: result.success ? Colors.green : Colors.red,
                            ),
                            title: Text(result.testName),
                            subtitle: Text(result.description),
                            trailing: Text(
                              '${result.duration}ms',
                              style: TextStyle(
                                color: result.duration > 5000
                                    ? Colors.red
                                    : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onTap: () => _showTestDetails(result),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runAllTests() async {
    setState(() {
      _isRunning = true;
      _testResults.clear();
    });

    await _runMealPlanTests();
    await _runWorkoutTests();
    await _runValidationTests();

    setState(() {
      _isRunning = false;
    });
  }

  Future<void> _runMealPlanTests() async {
    final tests = [
      _TestScenario('Normal Yemek Planı', '2000 kalori, kilo verme hedefi',
          () async {
        return await _apiHandler.createMealPlan(
          calories: 2000,
          goal: 'Kilo Verme',
          diet: 'balanced',
        );
      }),
      _TestScenario('Min Kalori', '1200 kalori, minimum değer', () async {
        return await _apiHandler.createMealPlan(
          calories: 1200,
          goal: 'Kilo Verme',
        );
      }),
      _TestScenario('Max Kalori', '4000 kalori, maksimum değer', () async {
        return await _apiHandler.createMealPlan(
          calories: 4000,
          goal: 'Kilo Alma',
        );
      }),
      _TestScenario('Kilo Alma Hedefi', '2500 kalori, kilo alma', () async {
        return await _apiHandler.createMealPlan(
          calories: 2500,
          goal: 'Kilo Alma',
        );
      }),
      _TestScenario('Kas Yapma Hedefi', '2200 kalori, kas yapma', () async {
        return await _apiHandler.createMealPlan(
          calories: 2200,
          goal: 'Kas Yapma',
        );
      }),
    ];

    await _runTestScenarios(tests, 'Yemek Planı');
  }

  Future<void> _runWorkoutTests() async {
    final tests = [
      _TestScenario('Başlangıç Seviye', '3 gün, ev antrenmanı', () async {
        return await _apiHandler.createWorkoutPlan(
          userId: 'test_user',
          age: 25,
          gender: 'Erkek',
          weight: 70.0,
          height: 175.0,
          fitnessLevel: 'Başlangıç',
          goal: 'Sağlıklı Yaşam',
          mode: 'ev',
          daysPerWeek: 3,
        );
      }),
      _TestScenario('İleri Seviye', '5 gün, spor salonu', () async {
        return await _apiHandler.createWorkoutPlan(
          userId: 'test_user',
          age: 30,
          gender: 'Kadın',
          weight: 60.0,
          height: 165.0,
          fitnessLevel: 'İleri',
          goal: 'Kas Yapma',
          mode: 'gym',
          daysPerWeek: 5,
        );
      }),
      _TestScenario('Min Yaş', '16 yaş, minimum değer', () async {
        return await _apiHandler.createWorkoutPlan(
          userId: 'test_user',
          age: 16,
          gender: 'Erkek',
          weight: 50.0,
          height: 160.0,
          fitnessLevel: 'Başlangıç',
          goal: 'Sağlıklı Yaşam',
          mode: 'ev',
          daysPerWeek: 2,
        );
      }),
      _TestScenario('Max Yaş', '100 yaş, maksimum değer', () async {
        return await _apiHandler.createWorkoutPlan(
          userId: 'test_user',
          age: 100,
          gender: 'Kadın',
          weight: 80.0,
          height: 170.0,
          fitnessLevel: 'Başlangıç',
          goal: 'Sağlıklı Yaşam',
          mode: 'ev',
          daysPerWeek: 2,
        );
      }),
    ];

    await _runTestScenarios(tests, 'Antrenman Planı');
  }

  Future<void> _runValidationTests() async {
    final tests = [
      _TestScenario('Normal Profil', 'Geçerli profil verisi', () async {
        final result = _validator.validateAndCleanProfileData({
          'userId': 'user_123',
          'age': 25,
          'gender': 'Erkek',
          'weight': 70.0,
          'height': 175.0,
          'activityLevel': 'Orta',
          'fitnessLevel': 'Orta',
          'goal': 'Sağlıklı Yaşam',
        });
        return result;
      }),
      _TestScenario('Virgüllü Sayılar', 'Kilo: 70,5, Boy: 175,5', () async {
        final result = _validator.validateAndCleanProfileData({
          'userId': 'user_123',
          'age': 25,
          'gender': 'Erkek',
          'weight': '70,5',
          'height': '175,5',
          'activityLevel': 'Orta',
          'fitnessLevel': 'Orta',
          'goal': 'Sağlıklı Yaşam',
        });
        return result;
      }),
      _TestScenario('İngilizce Cinsiyet', 'Male, Female', () async {
        final result = _validator.validateAndCleanProfileData({
          'userId': 'user_123',
          'age': 25,
          'gender': 'Male',
          'weight': 70.0,
          'height': 175.0,
          'activityLevel': 'Moderate',
          'fitnessLevel': 'Intermediate',
          'goal': 'Weight Loss',
        });
        return result;
      }),
      _TestScenario('Min Değerler', 'Yaş: 15, Kilo: 25kg', () async {
        final result = _validator.validateAndCleanProfileData({
          'userId': 'user_123',
          'age': 15,
          'gender': 'Erkek',
          'weight': 25.0,
          'height': 100.0,
          'activityLevel': 'Hareketsiz',
          'fitnessLevel': 'Başlangıç',
          'goal': 'Kilo Verme',
        });
        return result;
      }),
      _TestScenario('Max Değerler', 'Yaş: 150, Kilo: 500kg', () async {
        final result = _validator.validateAndCleanProfileData({
          'userId': 'user_123',
          'age': 150,
          'gender': 'Kadın',
          'weight': 500.0,
          'height': 300.0,
          'activityLevel': 'Çok Aktif',
          'fitnessLevel': 'Profesyonel',
          'goal': 'Kilo Alma',
        });
        return result;
      }),
      _TestScenario('Null Değerler', 'Bazı alanlar null', () async {
        final result = _validator.validateAndCleanProfileData({
          'userId': 'user_123',
          'age': null,
          'gender': null,
          'weight': null,
          'height': null,
          'activityLevel': null,
          'fitnessLevel': null,
          'goal': null,
        });
        return result;
      }),
    ];

    await _runTestScenarios(tests, 'Validasyon');
  }

  Future<void> _runTestScenarios(
      List<_TestScenario> scenarios, String category) async {
    for (final scenario in scenarios) {
      setState(() {
        _currentTest = '$category: ${scenario.name}';
      });

      final stopwatch = Stopwatch()..start();
      bool success = false;
      String error = '';

      try {
        await scenario.test();
        success = true;
      } catch (e) {
        error = e.toString();
        success = false;
      }

      stopwatch.stop();

      setState(() {
        _testResults.add(TestResult(
          testName: scenario.name,
          description: scenario.description,
          success: success,
          duration: stopwatch.elapsedMilliseconds,
          error: error,
        ));
      });

      // Testler arası kısa bekleme
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  void _clearResults() {
    setState(() {
      _testResults.clear();
    });
  }

  void _showTestDetails(TestResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(result.testName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Açıklama: ${result.description}'),
            const SizedBox(height: 8),
            Text('Durum: ${result.success ? "✅ Başarılı" : "❌ Başarısız"}'),
            const SizedBox(height: 8),
            Text('Süre: ${result.duration}ms'),
            if (result.error.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Hata: ${result.error}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  /// API bağlantısını test et
  Future<void> _testApiConnection() async {
    try {
      final smartHandler = SmartApiHandler();
      await smartHandler.testApiConnection();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('API test tamamlandı, console loglarını kontrol edin'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('API test hatası: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _TestScenario {
  final String name;
  final String description;
  final Future<dynamic> Function() test;

  _TestScenario(this.name, this.description, this.test);
}

class TestResult {
  final String testName;
  final String description;
  final bool success;
  final int duration;
  final String error;

  TestResult({
    required this.testName,
    required this.description,
    required this.success,
    required this.duration,
    required this.error,
  });
}
