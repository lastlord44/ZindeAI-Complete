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

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  // Seçimler
  String _gender = 'Erkek';
  String _fitnessLevel = 'Başlangıç';
  String _primaryGoal = 'Kilo Verme';
  bool _preserveMuscle =
      false; // Kas kütlesi koruma - BU DEĞİŞKEN KAYBOLMAYACAK
  int _workoutDays = 3;
  String _dietType = 'Dengeli';
  String _activityLevel = 'Orta Aktif';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString('user_profile');

      if (profileJson != null) {
        final profile = jsonDecode(profileJson);

        setState(() {
          _nameController.text = profile['name'] ?? '';
          _ageController.text = profile['age']?.toString() ?? '25';
          _heightController.text = profile['height']?.toString() ?? '170';
          _weightController.text = profile['weight']?.toString() ?? '70';
          _gender = profile['gender'] ?? 'Erkek';
          _fitnessLevel = profile['fitness_level'] ?? 'Başlangıç';
          _primaryGoal = profile['primary_goal'] ?? 'Kilo Verme';
          _preserveMuscle = profile['preserve_muscle'] ?? false;
          _workoutDays = profile['workout_days'] ?? 3;
          _dietType = profile['diet_type'] ?? 'Dengeli';
          _activityLevel = profile['activity_level'] ?? 'Orta Aktif';
        });
      }
    } catch (e) {
      print('Profil yükleme hatası: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profil Bilgileri'),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple,
              Colors.deepPurple.shade50,
            ],
            stops: [0.0, 0.2],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Başlık kartı
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.deepPurple,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Kişisel Bilgiler',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  // Temel bilgiler
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Temel Bilgiler',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Ad Soyad',
                              prefixIcon: Icon(Icons.person_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Lütfen adınızı girin';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _ageController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Yaş',
                                    prefixIcon: Icon(Icons.cake),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Gerekli';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _gender,
                                  decoration: InputDecoration(
                                    labelText: 'Cinsiyet',
                                    prefixIcon: Icon(Icons.wc),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  items: ['Erkek', 'Kadın'].map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _gender = value!;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _heightController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Boy (cm)',
                                    prefixIcon: Icon(Icons.height),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Gerekli';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: _weightController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Kilo (kg)',
                                    prefixIcon: Icon(Icons.monitor_weight),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Gerekli';
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

                  SizedBox(height: 16),

                  // Fitness bilgileri
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fitness Bilgileri',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                          SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _fitnessLevel,
                            decoration: InputDecoration(
                              labelText: 'Fitness Seviyesi',
                              prefixIcon: Icon(Icons.fitness_center),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            items: ['Başlangıç', 'Orta', 'İleri']
                                .map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _fitnessLevel = value!;
                              });
                            },
                          ),
                          SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _activityLevel,
                            decoration: InputDecoration(
                              labelText: 'Aktivite Seviyesi',
                              prefixIcon: Icon(Icons.directions_run),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            items: [
                              'Sedanter (Hareketsiz)',
                              'Hafif Aktif',
                              'Orta Aktif',
                              'Çok Aktif',
                              'Aşırı Aktif'
                            ].map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child:
                                    Text(value, style: TextStyle(fontSize: 14)),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _activityLevel = value!;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 16),

                  // Hedefler
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hedefler',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                          SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _primaryGoal,
                            decoration: InputDecoration(
                              labelText: 'Ana Hedef',
                              prefixIcon: Icon(Icons.flag),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            items: [
                              'Kilo Verme',
                              'Kilo Alma',
                              'Kas Kazanma + Kilo Alma',
                              'Kas Kazanma + Kilo Verme',
                              'Bakım',
                              'Güç Kazanma'
                            ].map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _primaryGoal = value!;
                                // Yeni hedefler için kas koruma seçeneği gösterme
                                _preserveMuscle = false;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 16),

                  // Antrenman ve Diyet
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Antrenman ve Beslenme',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                          SizedBox(height: 16),

                          // Antrenman günleri slider
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Haftalık Antrenman',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.deepPurple,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '$_workoutDays gün',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Slider(
                                  value: _workoutDays.toDouble(),
                                  min: 3,
                                  max: 6,
                                  divisions: 3,
                                  activeColor: Colors.deepPurple,
                                  label: '$_workoutDays gün',
                                  onChanged: (value) {
                                    setState(() {
                                      _workoutDays = value.round();
                                    });
                                  },
                                ),
                                Text(
                                  _getWorkoutSplitInfo(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 16),

                          DropdownButtonFormField<String>(
                            value: _dietType,
                            decoration: InputDecoration(
                              labelText: 'Diyet Tipi',
                              prefixIcon: Icon(Icons.restaurant),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              helperText:
                                  'Beslenme planınız bu tercihe göre oluşturulacak',
                            ),
                            items: [
                              'Dengeli',
                              'Vejetaryen',
                              'Vegan',
                              'Ketojenik',
                              'Paleo',
                              'Akdeniz'
                            ].map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _dietType = value!;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 24),

                  // Kaydet butonu
                  ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 4,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'PROFİLİ KAYDET',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getWorkoutSplitInfo() {
    switch (_workoutDays) {
      case 3:
        return 'Full Body antrenmanları önerilir';
      case 4:
        return 'Upper/Lower split önerilir';
      case 5:
        return 'Push/Pull/Legs + Upper/Lower önerilir';
      case 6:
        return 'Push/Pull/Legs x2 önerilir';
      default:
        return '';
    }
  }

  // Hedefi API formatına çevir
  String _mapGoalToAPI(String goal) {
    switch (goal) {
      case 'Kilo Verme':
        return 'lose';
      case 'Kilo Alma':
        return 'gain';
      case 'Kas Kazanma + Kilo Alma':
        return 'gain_muscle_gain_weight';
      case 'Kas Kazanma + Kilo Verme':
        return 'gain_muscle_loss_fat';
      case 'Bakım':
        return 'maintain';
      case 'Güç Kazanma':
        return 'gain_strength';
      default:
        return 'maintain';
    }
  }

  // Aktivite seviyesini API formatına çevir
  String _mapActivityToAPI(String activity) {
    switch (activity) {
      case 'Sedanter (Hareketsiz)':
        return 'sedentary';
      case 'Hafif Aktif':
        return 'light';
      case 'Orta Aktif':
        return 'moderate';
      case 'Çok Aktif':
        return 'very_active';
      case 'Aşırı Aktif':
        return 'extra_active';
      default:
        return 'moderate';
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      // Profil nesnesini oluştur
      final profile = {
        'name': _nameController.text,
        'age': int.parse(_ageController.text),
        'height': int.parse(_heightController.text),
        'weight': double.parse(_weightController.text),
        'gender': _gender,
        'fitness_level': _fitnessLevel,
        'activity_level': _activityLevel,
        'primary_goal': _primaryGoal,
        'preserve_muscle': _preserveMuscle,
        'workout_days': _workoutDays,
        'diet_type': _dietType,
      };

      // SharedPreferences'a kaydet
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_profile', jsonEncode(profile));

        // Başarı mesajı göster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Profil başarıyla kaydedildi!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Plan seçim ekranına git
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlanSelectionScreen(
                profile: UserProfile(
              sex: _gender == 'Erkek' ? 'male' : 'female',
              age: int.parse(_ageController.text),
              heightCm: int.parse(_heightController.text),
              weightKg: double.parse(_weightController.text),
              goal: _mapGoalToAPI(_primaryGoal),
              activity: _mapActivityToAPI(_activityLevel),
              dietFlags: [_dietType.toLowerCase()],
              training: TrainingPreferences(
                daysPerWeek: _workoutDays,
                days: ['Monday', 'Wednesday', 'Friday'],
                splitPreference: 'AUTO',
                mode: 'gym',
              ),
            )),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Profil kaydedilemedi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }
}
