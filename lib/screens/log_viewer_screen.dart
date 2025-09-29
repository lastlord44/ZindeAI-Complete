import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Log görüntüleme ekranı
class LogViewerScreen extends StatefulWidget {
  const LogViewerScreen({super.key});

  @override
  State<LogViewerScreen> createState() => _LogViewerScreenState();
}

class _LogViewerScreenState extends State<LogViewerScreen> {
  final List<String> _logs = [];
  final ScrollController _scrollController = ScrollController();
  bool _autoScroll = true;
  String _filter = '';
  String _selectedLevel = 'All';

  final List<String> _logLevels = [
    'All',
    'DEBUG',
    'INFO',
    'WARNING',
    'ERROR',
    'SUCCESS',
    'API',
    'DATABASE',
    'UI',
    'AUTH',
    'PERFORMANCE',
  ];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadLogs() {
    // Gerçek uygulamada bu log'lar bir log service'den gelecek
    // Şimdilik örnek log'lar ekleyelim
    setState(() {
      _logs.clear();
      _logs.addAll([
        '[14:05:07.123] [ZindeAI] ℹ️ INFO [Main] Uygulama başlatılıyor',
        '[14:05:07.124] [ZindeAI] ✅ SUCCESS [Main] Locale başarıyla başlatıldı',
        '[14:05:07.125] [ZindeAI] ✅ SUCCESS [Main] Supabase API başarıyla başlatıldı',
        '[14:05:07.126] [ZindeAI] 🎨 UI [HomeScreen] HomeScreen build ediliyor',
        '[14:05:07.127] [ZindeAI] 🎨 UI [HomeScreen] Kullanıcı etkileşimi: Yemek Planı test butonuna tıklandı',
        '[14:05:07.128] [ZindeAI] 🌐 API [ApiService] Yemek planı oluşturma isteği alındı',
        '[14:05:07.129] [ZindeAI] 🌐 API [SmartApiHandler] Yemek planı oluşturma başlatılıyor',
        '[14:05:07.130] [ZindeAI] 🐛 DEBUG [SmartApiHandler] Input validasyonu başlıyor',
        '[14:05:07.131] [ZindeAI] ✅ SUCCESS [SmartApiHandler] Input validasyonu tamamlandı',
        '[14:05:07.132] [ZindeAI] 🐛 DEBUG [SmartApiHandler] Supabase API çağrısı yapılıyor',
        '[14:05:07.133] [ZindeAI] ❌ ERROR [SmartApiHandler] Supabase API hatası',
        '[14:05:07.134] [ZindeAI] ❌ ERROR [SmartApiHandler] Yemek planı oluşturulamadı',
        '[14:05:07.135] [ZindeAI] ❌ ERROR [ApiService] Yemek planı oluşturma hatası',
        '[14:05:07.136] [ZindeAI] ⚡ PERFORMANCE [ApiService] Performans ölçümü tamamlandı: 550ms',
        '[14:05:07.137] [ZindeAI] 🐛 DEBUG [SmartApiHandler] Request data: {"planType":"meal","calories":2807,"goal":"gain_weight","diet":"balanced","daysPerWeek":7,"preferences":{},"age":38,"sex":"male","weight":72.0,"height":180.0,"activity":"moderately_active"}',
        '[14:05:07.138] [ZindeAI] 🐛 DEBUG [SmartApiHandler] Base URL: https://uhibpbwgvnvasxlvcohr.supabase.co/functions/v1/',
        '[14:05:07.139] [ZindeAI] 🐛 DEBUG [SmartApiHandler] Headers: {Content-Type: application/json, Accept: application/json, apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...}',
        '[14:05:07.140] [ZindeAI] ❌ ERROR [SmartApiHandler] DioException [bad response]: 401 Unauthorized',
        '[14:05:07.141] [ZindeAI] ❌ ERROR [SmartApiHandler] Status code: 401',
        '[14:05:07.142] [ZindeAI] ❌ ERROR [SmartApiHandler] Response headers: {connection: keep-alive, set-cookie: __cf_bm=..., access-control-allow-origin: *, date: Mon, 29 Sep 2025 11:15:10 GMT, content-encoding: gzip, vary: Accept-Encoding, strict-transport-security: max-age=31536000; includeSubDomains; preload, cf-cache-status: DYNAMIC, sb-project-ref: uhibpbwgvnvasxlvcohr, content-type: application/json, server: cloudflare, x-served-by: supabase-edge-runtime, access-control-allow-headers: authorization, x-client-info, apikey, alt-svc: h3=":443"; ma=86400, content-length: 56, cf-ray: 986b0fa5eef6c66e-IST, x-sb-edge-region: eu-central-1, sb-request-id: 0199952f-03b9-7992-8296-c026ed9711d7}',
      ]);
    });

    if (_autoScroll) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  List<String> get _filteredLogs {
    if (_filter.isEmpty && _selectedLevel == 'All') {
      return _logs;
    }

    return _logs.where((log) {
      final matchesFilter =
          _filter.isEmpty || log.toLowerCase().contains(_filter.toLowerCase());

      final matchesLevel =
          _selectedLevel == 'All' || log.contains(_selectedLevel);

      return matchesFilter && matchesLevel;
    }).toList();
  }

  Color _getLogColor(String log) {
    if (log.contains('ERROR') || log.contains('❌')) {
      return Colors.red;
    } else if (log.contains('WARNING') || log.contains('⚠️')) {
      return Colors.orange;
    } else if (log.contains('SUCCESS') || log.contains('✅')) {
      return Colors.green;
    } else if (log.contains('API') || log.contains('🌐')) {
      return Colors.blue;
    } else if (log.contains('DEBUG') || log.contains('🐛')) {
      return Colors.purple;
    } else if (log.contains('INFO') || log.contains('ℹ️')) {
      return Colors.cyan;
    } else if (log.contains('UI') || log.contains('🎨')) {
      return Colors.pink;
    } else if (log.contains('PERFORMANCE') || log.contains('⚡')) {
      return Colors.amber;
    }
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Görüntüleyici'),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_autoScroll
                ? Icons.vertical_align_bottom
                : Icons.vertical_align_center),
            onPressed: () {
              setState(() {
                _autoScroll = !_autoScroll;
              });
            },
            tooltip: _autoScroll
                ? 'Otomatik kaydırmayı kapat'
                : 'Otomatik kaydırmayı aç',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogs,
            tooltip: 'Log\'ları yenile',
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {
              final logsText = _filteredLogs.join('\n');
              Clipboard.setData(ClipboardData(text: logsText));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Log\'lar panoya kopyalandı')),
              );
            },
            tooltip: 'Log\'ları kopyala',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtreler
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              children: [
                // Arama filtresi
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Log\'larda ara...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _filter = value;
                    });
                  },
                ),
                const SizedBox(height: 8),
                // Seviye filtresi
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _logLevels.map((level) {
                      final isSelected = _selectedLevel == level;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(level),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedLevel = selected ? level : 'All';
                            });
                          },
                          selectedColor: Colors.blue[100],
                          checkmarkColor: Colors.blue[800],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          // Log sayısı
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[200],
            child: Row(
              children: [
                Text(
                  '${_filteredLogs.length} log gösteriliyor',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const Spacer(),
                if (_filter.isNotEmpty || _selectedLevel != 'All')
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _filter = '';
                        _selectedLevel = 'All';
                      });
                    },
                    child: const Text('Filtreleri temizle'),
                  ),
              ],
            ),
          ),
          // Log listesi
          Expanded(
            child: _filteredLogs.isEmpty
                ? const Center(
                    child: Text(
                      'Filtrelere uygun log bulunamadı',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _filteredLogs.length,
                    itemBuilder: (context, index) {
                      final log = _filteredLogs[index];
                      final color = _getLogColor(log);

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey[300]!,
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: SelectableText(
                          log,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: color,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _scrollToBottom,
        tooltip: 'En alta git',
        child: const Icon(Icons.keyboard_arrow_down),
      ),
    );
  }
}
