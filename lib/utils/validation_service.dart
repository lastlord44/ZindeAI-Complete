class ValidationService {
  static Future<Map<String, dynamic>> validateProfile(Map<String, dynamic> profile) async {
    final errors = <String>[];
    
    // User ID kontrolü
    if (profile['userId'] == null || profile['userId'].toString().isEmpty) {
      errors.add('User ID gerekli');
    }
    
    // Yaş kontrolü
    final age = profile['age'];
    if (age == null || age < 13 || age > 100) {
      errors.add('Geçerli yaş gerekli (13-100)');
    }
    
    // Kilo kontrolü
    final weight = profile['weight'];
    if (weight == null || weight < 30 || weight > 300) {
      errors.add('Geçerli kilo gerekli (30-300 kg)');
    }
    
    // Boy kontrolü
    final height = profile['height'];
    if (height == null || height < 100 || height > 250) {
      errors.add('Geçerli boy gerekli (100-250 cm)');
    }
    
    return {
      'isValid': errors.isEmpty,
      'errors': errors,
      'cleanedData': profile,
    };
  }
  
  static Future<Map<String, dynamic>> validateMealPlan(Map<String, dynamic> plan) async {
    final errors = <String>[];
    
    // Plan adı kontrolü
    if (plan['plan_name'] == null || plan['plan_name'].toString().isEmpty) {
      errors.add('Plan adı gerekli');
    }
    
    // Günler kontrolü
    final days = plan['days'];
    if (days == null || days is! List || days.isEmpty) {
      errors.add('Günler listesi gerekli');
    }
    
    // Makrolar kontrolü
    final dailyMacros = plan['daily_macros'];
    if (dailyMacros == null || dailyMacros is! Map) {
      errors.add('Günlük makrolar gerekli');
    }
    
    return {
      'isValid': errors.isEmpty,
      'errors': errors,
    };
  }
  
  static Future<Map<String, dynamic>> validateWorkoutPlan(Map<String, dynamic> plan) async {
    final errors = <String>[];
    
    // Plan adı kontrolü
    if (plan['plan_name'] == null || plan['plan_name'].toString().isEmpty) {
      errors.add('Plan adı gerekli');
    }
    
    // Workouts kontrolü
    final workouts = plan['workouts'];
    if (workouts == null || workouts is! List || workouts.isEmpty) {
      errors.add('Antrenman listesi gerekli');
    }
    
    return {
      'isValid': errors.isEmpty,
      'errors': errors,
    };
  }
}
