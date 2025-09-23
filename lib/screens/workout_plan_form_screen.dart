import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/workout_plan.dart';

class WorkoutPlanFormScreen extends StatefulWidget {
  const WorkoutPlanFormScreen({super.key});

  @override
  State<WorkoutPlanFormScreen> createState() => _WorkoutPlanFormScreenState();
}

class _WorkoutPlanFormScreenState extends State<WorkoutPlanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _error;

  // Form değerleri
  int _age = 25;
  String _gender = 'male';
  double _weight = 70;
  int _height = 170;
  String _fitnessLevel = 'beginner';
  String _goal = 'general';
  String _mode = 'home';
  int _daysPerWeek = 3;
  String _preferredSplit = 'fullbody';
  String _equipment = 'none';
  String _injuries = '';
  int _timePerSession = 45;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Antrenman Planı Oluştur'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kişisel Bilgiler
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kişisel Bilgiler',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: _age.toString(),
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Yaş',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) =>
                                  _age = int.tryParse(value) ?? 25,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _gender,
                              decoration: const InputDecoration(
                                labelText: 'Cinsiyet',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(
                                    value: 'male', child: Text('Erkek')),
                                DropdownMenuItem(
                                    value: 'female', child: Text('Kadın')),
                              ],
                              onChanged: (value) =>
                                  setState(() => _gender = value!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: _weight.toString(),
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Kilo (kg)',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) =>
                                  _weight = double.tryParse(value) ?? 70,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              initialValue: _height.toString(),
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Boy (cm)',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) =>
                                  _height = int.tryParse(value) ?? 170,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Fitness Bilgileri
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Fitness Bilgileri',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _fitnessLevel,
                        decoration: const InputDecoration(
                          labelText: 'Fitness Seviyesi',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'beginner', child: Text('Başlangıç')),
                          DropdownMenuItem(
                              value: 'intermediate', child: Text('Orta')),
                          DropdownMenuItem(
                              value: 'advanced', child: Text('İleri')),
                        ],
                        onChanged: (value) =>
                            setState(() => _fitnessLevel = value!),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _goal,
                        decoration: const InputDecoration(
                          labelText: 'Hedef',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'general', child: Text('Genel Fitness')),
                          DropdownMenuItem(
                              value: 'muscle', child: Text('Kas Geliştirme')),
                          DropdownMenuItem(
                              value: 'weight_loss', child: Text('Kilo Verme')),
                          DropdownMenuItem(
                              value: 'endurance', child: Text('Dayanıklılık')),
                        ],
                        onChanged: (value) => setState(() => _goal = value!),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _mode,
                        decoration: const InputDecoration(
                          labelText: 'Antrenman Yeri',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'home', child: Text('Ev')),
                          DropdownMenuItem(
                              value: 'gym', child: Text('Spor Salonu')),
                          DropdownMenuItem(
                              value: 'outdoor', child: Text('Açık Alan')),
                        ],
                        onChanged: (value) => setState(() => _mode = value!),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Antrenman Tercihleri
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Antrenman Tercihleri',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Text('Haftalık Antrenman Günü: $_daysPerWeek'),
                      Slider(
                        value: _daysPerWeek.toDouble(),
                        min: 1,
                        max: 7,
                        divisions: 6,
                        label: '$_daysPerWeek gün',
                        onChanged: (value) {
                          setState(() => _daysPerWeek = value.round());
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _preferredSplit,
                        decoration: const InputDecoration(
                          labelText: 'Split Tercihi',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'fullbody', child: Text('Full Body')),
                          DropdownMenuItem(
                              value: 'upper_lower', child: Text('Upper/Lower')),
                          DropdownMenuItem(
                              value: 'push_pull_legs',
                              child: Text('Push/Pull/Legs')),
                          DropdownMenuItem(
                              value: 'bro_split', child: Text('Bro Split')),
                        ],
                        onChanged: (value) =>
                            setState(() => _preferredSplit = value!),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: _equipment,
                        decoration: const InputDecoration(
                          labelText: 'Ekipman (varsa)',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => _equipment = value,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: _injuries,
                        decoration: const InputDecoration(
                          labelText: 'Yaralanma/Sorun (varsa)',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => _injuries = value,
                      ),
                      const SizedBox(height: 16),
                      Text('Antrenman Süresi: $_timePerSession dakika'),
                      Slider(
                        value: _timePerSession.toDouble(),
                        min: 15,
                        max: 120,
                        divisions: 21,
                        label: '$_timePerSession dk',
                        onChanged: (value) {
                          setState(() => _timePerSession = value.round());
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Oluştur Butonu
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createPlan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Antrenman Planı Oluştur',
                          style: TextStyle(fontSize: 16)),
                ),
              ),

              if (_error != null)
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createPlan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = context.read<ApiService>();
      final result = await apiService.createWorkoutPlan(
        userId: 'user_${DateTime.now().millisecondsSinceEpoch}',
        age: _age,
        gender: _gender,
        weight: _weight.toDouble(),
        height: _height.toDouble(),
        fitnessLevel: _fitnessLevel,
        goal: _goal,
        mode: _mode,
        daysPerWeek: _daysPerWeek,
        preferredSplit: _preferredSplit,
        equipment: _equipment.isNotEmpty ? [_equipment] : null,
        injuries: _injuries.isNotEmpty ? [_injuries] : null,
        timePerSession: _timePerSession,
      );

      // Sonucu göster
      if (mounted) {
        Navigator.pop(context, result);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
}
