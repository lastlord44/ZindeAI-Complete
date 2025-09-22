import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_profile.dart';
import 'weekly_plan_screen.dart';

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

  // Aktivite seviyesi - Profesyonel TDEE çarpanları
  String _activityLevel = 'moderately_active';

  // Antrenman tercihleri
  int _daysPerWeek = 3;
  String _splitPreference = 'AUTO';
  String _mode = 'gym';
  List<String> _selectedDays = ['Monday', 'Wednesday', 'Friday'];

  // Diyet tercihleri
  List<String> _dietFlags = [];

  @override
  void initState() {
    super.initState();
    _loadProfile(); // Önce profili yükle
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
      // Profil yoksa varsayılan değerleri set et
      setState(() {
        _ageController.text = '25';
        _heightController.text = '170';
        _weightController.text = '70';
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

    // Profili kaydet
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_profile', json.encode(profile.toJson()));

    // Plan sayfasına git
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WeeklyPlanScreen(profile: profile),
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

                      // Yaş, Boy, Kilo
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _ageController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Yaş', // labelText'e geri dönüyoruz
                                floatingLabelBehavior: FloatingLabelBehavior
                                    .always, // BU SATIR HATAYI ÇÖZER
                                suffixText: 'yaş',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.cake),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Gerekli';
                                }
                                final age = int.tryParse(value);
                                if (age == null || age < 13 || age > 100) {
                                  return '13-100 arası';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _heightController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Boy',
                                floatingLabelBehavior: FloatingLabelBehavior
                                    .always, // BU SATIR HATAYI ÇÖZER
                                suffixText: 'cm',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.height),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Gerekli';
                                }
                                final height = int.tryParse(value);
                                if (height == null ||
                                    height < 100 ||
                                    height > 250) {
                                  return '100-250 cm';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _weightController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Kilo',
                                floatingLabelBehavior: FloatingLabelBehavior
                                    .always, // BU SATIR HATAYI ÇÖZER
                                suffixText: 'kg',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.monitor_weight),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Gerekli';
                                }
                                final weight = double.tryParse(value);
                                if (weight == null ||
                                    weight < 30 ||
                                    weight > 300) {
                                  return '30-300 kg';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
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
                      // Ana hedef
                      const Text('Ana Hedefiniz Nedir?'),
                      const SizedBox(height: 12),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'cut',
                            label: Text('Kilo Ver'),
                            icon: Icon(Icons.trending_down),
                          ),
                          ButtonSegment(
                            value: 'maintain',
                            label: Text('Koru'),
                            icon: Icon(Icons.horizontal_rule),
                          ),
                          ButtonSegment(
                            value: 'bulk',
                            label: Text('Kilo Al'),
                            icon: Icon(Icons.trending_up),
                          ),
                        ],
                        selected: {_primaryGoal},
                        onSelectionChanged: (selected) {
                          setState(() => _primaryGoal = selected.first);
                        },
                      ),

                      const SizedBox(height: 16),

                      // Kas yapma hedefi
                      CheckboxListTile(
                        title: const Text(
                            'Kas kütlesi kazanmak/korumak istiyorum'),
                        subtitle: Text(
                          _primaryGoal == 'cut'
                              ? 'Kilo verirken kas korunur'
                              : _primaryGoal == 'bulk'
                                  ? 'Kilo alırken kas yapılır'
                                  : 'Mevcut kiloyu korurken güç kazanılır',
                          style: const TextStyle(fontSize: 12),
                        ),
                        value: _buildMuscle,
                        onChanged: (value) {
                          setState(() => _buildMuscle = value ?? false);
                        },
                        activeColor: Theme.of(context).primaryColor,
                      ),
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
                        value:
                            'sedentary', // Değerleri İngilizce ve standart yapıyoruz
                        groupValue: _activityLevel,
                        onChanged: (value) {
                          setState(() => _activityLevel = value!);
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text('Az Aktif'),
                        subtitle: const Text('Haftada 1-3 gün hafif egzersiz'),
                        value: 'lightly_active',
                        groupValue: _activityLevel,
                        onChanged: (value) {
                          setState(() => _activityLevel = value!);
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text('Orta Derecede Aktif'),
                        subtitle:
                            const Text('Haftada 3-5 gün orta seviye egzersiz'),
                        value: 'moderately_active',
                        groupValue: _activityLevel,
                        onChanged: (value) {
                          setState(() => _activityLevel = value!);
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text('Çok Aktif'),
                        subtitle: const Text('Haftada 6-7 gün ağır egzersiz'),
                        value: 'very_active',
                        groupValue: _activityLevel,
                        onChanged: (value) {
                          setState(() => _activityLevel = value!);
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
                          ButtonSegment(
                            value: 'hybrid',
                            label: Text('Her İkisi'),
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

                      // Split tercihi
                      const Text('Antrenman programı tipi:'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _splitPreference,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        items: _getSplitOptions(),
                        onChanged: (value) {
                          setState(() => _splitPreference = value!);
                        },
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

  List<DropdownMenuItem<String>> _getSplitOptions() {
    final options = <DropdownMenuItem<String>>[];

    options.add(const DropdownMenuItem(
      value: 'AUTO',
      child: Text('Otomatik Seç (Önerilen)'),
    ));

    if (_daysPerWeek >= 2) {
      options.add(const DropdownMenuItem(
        value: 'full_body',
        child: Text('Full Body - Tüm vücut'),
      ));
    }

    if (_daysPerWeek >= 2) {
      options.add(const DropdownMenuItem(
        value: 'upper_lower',
        child: Text('Upper/Lower - Üst/Alt'),
      ));
    }

    if (_daysPerWeek >= 3) {
      options.add(const DropdownMenuItem(
        value: 'ppl',
        child: Text('PPL - Push/Pull/Legs'),
      ));
    }

    if (_daysPerWeek >= 4) {
      options.add(const DropdownMenuItem(
        value: 'arnold',
        child: Text('Arnold Split'),
      ));
    }

    if (_daysPerWeek >= 5) {
      options.add(const DropdownMenuItem(
        value: 'bro_split',
        child: Text('Bro Split - 5 günlük'),
      ));
    }

    return options;
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
    // Gün sayısına göre uygun olmayan split'i değiştir
    if (_daysPerWeek < 5 && _splitPreference == 'bro_split') {
      _splitPreference = 'AUTO';
    } else if (_daysPerWeek < 4 && _splitPreference == 'arnold') {
      _splitPreference = 'AUTO';
    } else if (_daysPerWeek < 3 && _splitPreference == 'ppl') {
      _splitPreference = 'AUTO';
    }
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }
}
