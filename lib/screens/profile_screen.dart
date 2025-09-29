// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_profile.dart';
import 'plan_selection_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Kullanıcı bilgileri
  String _sex = 'male';
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  // Hedefler
  String _primaryGoal = 'maintain';
  bool _buildMuscle = false;
  String? selectedGoal;
  bool wantMuscleGain = false;

  // Aktivite seviyesi - Profesyonel TDEE çarpanları
  String _activityLevel = 'moderately_active';

  // Antrenman tercihleri
  int _daysPerWeek = 3;
  String _splitPreference = 'AUTO';
  String _mode = 'gym';
  final List<String> _selectedDays = ['Monday', 'Wednesday', 'Friday'];

  // Diyet tercihleri
  List<String> _dietFlags = [];

  @override
  void initState() {
    super.initState();
    // Önce controller'lara değer ata
    _ageController.text = '25';
    _heightController.text = '170';
    _weightController.text = '70';

    // Sonra profili yükle (varsa üzerine yazacak)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final profileJson = prefs.getString('user_profile');

    if (profileJson != null) {
      final profile = UserProfile.fromJson(json.decode(profileJson));
      setState(() {
        _sex = profile.sex;
        _ageController.text = profile.age.toString();
        _heightController.text = profile.heightCm.toString();
        _weightController.text = profile.weightKg.toString();
        _primaryGoal = profile.goal;
        _activityLevel = _mapOldActivityLevel(profile.activity);
        _daysPerWeek = profile.training.daysPerWeek;
        _splitPreference = profile.training.splitPreference;
        _mode = profile.training.mode;
        _dietFlags = profile.dietFlags;
      });
    } else {
      // Profil yoksa varsayılan değerleri set et (zaten initState'de set edildi)
      setState(() {
        // Controller değerleri zaten initState'de set edildi
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // Hedef kombinasyonu
    String finalGoal;
    if (_primaryGoal == 'cut' && _buildMuscle) {
      finalGoal = 'fat_loss'; // Yağ yakma + kas koruma
    } else if (_primaryGoal == 'bulk' && _buildMuscle) {
      finalGoal = 'muscle_gain'; // Kas yapma
    } else if (_primaryGoal == 'maintain' && _buildMuscle) {
      finalGoal = 'strength'; // Güç kazanma
    } else if (_primaryGoal == 'cut') {
      finalGoal = 'fat_loss';
    } else if (_primaryGoal == 'bulk') {
      finalGoal = 'muscle_gain';
    } else {
      finalGoal = 'maintenance';
    }

    final profile = UserProfile(
      sex: _sex,
      age: int.parse(_ageController.text),
      heightCm: int.parse(_heightController.text),
      weightKg: double.parse(_weightController.text),
      goal: finalGoal,
      activity: _activityLevel,
      dietFlags: _dietFlags,
      training: TrainingPreferences(
        daysPerWeek: _daysPerWeek,
        days: _selectedDays,
        splitPreference: _splitPreference,
        mode: _mode,
      ),
    );

    // Profile data'ya ekle
    Map<String, dynamic> profileData = {
      'goal': selectedGoal,
      'wantMuscleGain': wantMuscleGain,
      'proteinPreference': wantMuscleGain ? 'high' : 'moderate',
    };

    // Profili kaydet
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_profile', json.encode(profile.toJson()));

    // Plan seçim sayfasına git
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PlanSelectionScreen(profile: profile),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('ZindeAI Profil'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Başlık
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.person_add,
                      size: 64,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Kişisel Bilgileriniz',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Size özel plan oluşturacağız',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // TEMEL BİLGİLER
              _buildSectionTitle('📊 Temel Bilgiler'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Cinsiyet
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'male',
                            label: Text('Erkek'),
                            icon: Icon(Icons.male),
                          ),
                          ButtonSegment(
                            value: 'female',
                            label: Text('Kadın'),
                            icon: Icon(Icons.female),
                          ),
                        ],
                        selected: {_sex},
                        onSelectionChanged: (selected) {
                          setState(() => _sex = selected.first);
                        },
                      ),

                      const SizedBox(height: 16),

                      // Yaş, Boy, Kilo - Responsive
                      _buildResponsiveTextField(
                        label: 'Yaşınız',
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        maxLength: 3,
                      ),
                      _buildResponsiveTextField(
                        label: 'Boyunuz',
                        controller: _heightController,
                        keyboardType: TextInputType.number,
                        suffix: 'cm',
                        maxLength: 3,
                      ),
                      _buildResponsiveTextField(
                        label: 'Kilonuz',
                        controller: _weightController,
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        suffix: 'kg',
                        maxLength: 5,  // 3 + nokta + 1 ondalık
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // HEDEFLER
              _buildSectionTitle('🎯 Hedefleriniz'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Hedef seçimi
                      _buildGoalSelection(),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // AKTİVİTE SEVİYESİ - PROFESYONEL TDEE ÇARPANLARI
              _buildSectionTitle('🏃 Aktivite Seviyesi'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        title: const Text('Hareketsiz'),
                        subtitle: const Text('Masa başı iş, hiç egzersiz yok'),
                        value: 'sedentary',
                        groupValue: _activityLevel,
                        onChanged: (value) {
                          if (mounted) {
                            setState(() => _activityLevel = value!);
                          }
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text('Az Aktif'),
                        subtitle: const Text('Haftada 1-3 gün hafif egzersiz'),
                        value: 'lightly_active',
                        groupValue: _activityLevel,
                        onChanged: (value) {
                          if (mounted) {
                            setState(() => _activityLevel = value!);
                          }
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text('Orta Derecede Aktif'),
                        subtitle:
                            const Text('Haftada 3-5 gün orta seviye egzersiz'),
                        value: 'moderately_active',
                        groupValue: _activityLevel,
                        onChanged: (value) {
                          if (mounted) {
                            setState(() => _activityLevel = value!);
                          }
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text('Çok Aktif'),
                        subtitle: const Text('Haftada 6-7 gün ağır egzersiz'),
                        value: 'very_active',
                        groupValue: _activityLevel,
                        onChanged: (value) {
                          if (mounted) {
                            setState(() => _activityLevel = value!);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ANTRENMAN TERCİHLERİ
              _buildSectionTitle('💪 Antrenman Tercihleri'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Antrenman yeri
                      const Text('Nerede antrenman yapacaksınız?'),
                      const SizedBox(height: 12),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'gym',
                            label: Text('Spor Salonu'),
                          ),
                          ButtonSegment(
                            value: 'home',
                            label: Text('Ev'),
                          ),
                        ],
                        selected: {_mode},
                        onSelectionChanged: (selected) {
                          setState(() => _mode = selected.first);
                        },
                      ),

                      const SizedBox(height: 16),

                      // Haftalık gün sayısı
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Haftada kaç gün: $_daysPerWeek'),
                          Slider(
                            value: _daysPerWeek.toDouble(),
                            min: 2,
                            max: 6,
                            divisions: 4,
                            label: '$_daysPerWeek gün',
                            onChanged: (value) {
                              setState(() {
                                _daysPerWeek = value.round();
                                _updateSplitPreference();
                              });
                            },
                          ),
                        ],
                      ),

                      // Split tercihi - Gemini otomatik seçsin
                      const Text('Antrenman programı tipi:'),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Yapay zeka size uygun programı belirleyecek',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // DİYET TERCİHLERİ
              _buildSectionTitle('🥗 Diyet Tercihleri'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Vejetaryen'),
                        selected: _dietFlags.contains('vegetarian'),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _dietFlags.add('vegetarian');
                              _dietFlags.remove('vegan');
                            } else {
                              _dietFlags.remove('vegetarian');
                            }
                          });
                        },
                      ),
                      FilterChip(
                        label: const Text('Vegan'),
                        selected: _dietFlags.contains('vegan'),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _dietFlags.add('vegan');
                              _dietFlags.remove('vegetarian');
                            } else {
                              _dietFlags.remove('vegan');
                            }
                          });
                        },
                      ),
                      FilterChip(
                        label: const Text('Glutensiz'),
                        selected: _dietFlags.contains('glutenFree'),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _dietFlags.add('glutenFree');
                            } else {
                              _dietFlags.remove('glutenFree');
                            }
                          });
                        },
                      ),
                      FilterChip(
                        label: const Text('Laktozsuz'),
                        selected: _dietFlags.contains('dairyFree'),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _dietFlags.add('dairyFree');
                            } else {
                              _dietFlags.remove('dairyFree');
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // PLANINI OLUŞTUR BUTONU
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _saveProfile,
                  icon: const Icon(Icons.rocket_launch),
                  label: const Text(
                    'PLANINI OLUŞTUR',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Responsive TextField widget'ı
  Widget _buildResponsiveTextField({
    required String label,
    required TextEditingController controller,
    required TextInputType keyboardType,
    String? suffix,
    int? maxLength,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              maxLength: maxLength,
              style: TextStyle(
                fontSize: 18,  // Büyük font
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,  // Daha fazla padding
                ),
                suffixText: suffix,
                suffixStyle: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                border: InputBorder.none,
                counterText: '',  // Karakter sayacını gizle
                // Input alanını genişlet
                isDense: false,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<DropdownMenuItem<String>> _getSplitOptions() {
    return [
      const DropdownMenuItem(
        value: 'AUTO',
        child: Text('Otomatik Seç (Önerilen)'),
      ),
    ];
  }

  // Eski aktivite seviyesi değerlerini yeni TDEE değerlerine çevir
  String _mapOldActivityLevel(String oldLevel) {
    switch (oldLevel) {
      case 'low':
        return 'sedentary';
      case 'med':
        return 'moderately_active';
      case 'high':
        return 'very_active';
      default:
        return 'moderately_active'; // Varsayılan değer
    }
  }

  void _updateSplitPreference() {
    // Gemini otomatik seçsin
    _splitPreference = 'AUTO';
  }

  // Hedef seçimi widget'ı
  Widget _buildGoalSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hedefiniz:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        RadioListTile(
          title: Text('Kilo Almak'),
          value: 'bulk',
          groupValue: selectedGoal,
          onChanged: (value) => setState(() => selectedGoal = value),
        ),
        RadioListTile(
          title: Text('Kilo Vermek'),
          value: 'cut',
          groupValue: selectedGoal,
          onChanged: (value) => setState(() => selectedGoal = value),
        ),
        RadioListTile(
          title: Text('Kilo Korumak'),
          value: 'maintain',
          groupValue: selectedGoal,
          onChanged: (value) => setState(() => selectedGoal = value),
        ),
        CheckboxListTile(
          title: Text('Kas kütlesi kazanmak/korumak istiyorum'),
          value: wantMuscleGain,
          onChanged: (value) => setState(() => wantMuscleGain = value!),
          activeColor: Theme.of(context).primaryColor,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }
}
