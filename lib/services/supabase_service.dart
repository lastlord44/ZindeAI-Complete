import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/meal_plan.dart';
import '../models/workout_plan.dart';
import '../models/user_profile.dart';
import 'api_service.dart';

class SupabaseService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // 1. Kullanıcı Profili İşlemleri
  static Future<void> saveUserProfile(UserProfile profile) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      await _supabase.from('user_profiles').upsert({
        'id': user.id,
        'age': profile.age,
        'height_cm': profile.heightCm,
        'weight_kg': profile.weightKg,
        'sex': profile.sex,
        'goal': profile.goal,
        'activity_level': profile.activity,
        'training_preferences': {
          'days_per_week': profile.training.daysPerWeek,
          'split_preference': profile.training.splitPreference,
          'mode': profile.training.mode,
          'preferred_days': profile.training.days,
        },
        'diet_flags': profile.dietFlags,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Profil kaydedilemedi: $e');
    }
  }

  static Future<UserProfile?> getUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('user_profiles')
          .select()
          .eq('id', user.id)
          .single();

      if (response == null) return null;

      return UserProfile.fromJson(response);
    } catch (e) {
      print('Profil yüklenemedi: $e');
      return null;
    }
  }

  // 2. Yemek Planı İşlemleri (Şimdilik mevcut API'yi kullan)
  static Future<MealPlan> createMealPlan({
    required int calories,
    required String goal,
    String diet = 'balanced',
    int daysPerWeek = 7,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      // Mevcut API'yi kullan (geçici)
      final apiService = ApiService();
      final mealPlan = await apiService.createMealPlan(
        calories: calories,
        goal: goal,
        diet: diet,
        daysPerWeek: daysPerWeek,
        preferences: preferences,
      );

      // Database'e kaydet (opsiyonel)
      final user = _supabase.auth.currentUser;
      if (user != null) {
        await _supabase.from('meal_plans').insert({
          'user_id': user.id,
          'total_calories': mealPlan.totalCalories,
          'total_protein': mealPlan.totalProtein,
          'total_carbs': mealPlan.totalCarbs,
          'total_fat': mealPlan.totalFat,
          'weekly_plan': mealPlan.weeklyPlan?.map((day) => {
            'day': day.day,
            'meals': day.meals.map((meal) => {
              'name': meal.name,
              'type': meal.type,
              'calories': meal.calories,
              'items': meal.items,
              'notes': meal.notes,
            }).toList(),
          }).toList(),
          'days_per_week': daysPerWeek,
          'goal': goal,
          'diet': diet,
        });
      }

      return mealPlan;
    } catch (e) {
      throw Exception('Yemek planı oluşturulamadı: $e');
    }
  }

  static Future<List<MealPlan>> getUserMealPlans() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      final response = await _supabase
          .from('meal_plans')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return (response as List)
          .map((data) => MealPlan.fromJson(data))
          .toList();
    } catch (e) {
      throw Exception('Yemek planları yüklenemedi: $e');
    }
  }

  // 3. Antrenman Planı İşlemleri (Şimdilik mevcut API'yi kullan)
  static Future<WorkoutPlan> createWorkoutPlan({
    required String userId,
    required int age,
    required String gender,
    required double weight,
    required double height,
    required String fitnessLevel,
    required String goal,
    required String mode,
    required int daysPerWeek,
    String? preferredSplit,
    List<String>? equipment,
    List<String>? injuries,
    int? timePerSession,
  }) async {
    try {
      // Mevcut API'yi kullan (geçici)
      final apiService = ApiService();
      final workoutPlan = await apiService.createWorkoutPlan(
        userId: userId,
        age: age,
        gender: gender,
        weight: weight,
        height: height,
        fitnessLevel: fitnessLevel,
        goal: goal,
        mode: mode,
        daysPerWeek: daysPerWeek,
        preferredSplit: preferredSplit,
        equipment: equipment,
        injuries: injuries,
        timePerSession: timePerSession,
      );

      // Database'e kaydet (opsiyonel)
      final user = _supabase.auth.currentUser;
      if (user != null) {
        await _supabase.from('workout_plans').insert({
          'user_id': user.id,
          'week_number': workoutPlan.weekNumber,
          'split_type': workoutPlan.splitType,
          'mode': workoutPlan.mode,
          'goal': workoutPlan.goal,
          'days': workoutPlan.days.map((day) => {
            'day': day.day,
            'focus': day.focus,
            'exercises': day.exercises.map((exercise) => {
              'name': exercise.name,
              'sets': exercise.sets,
              'reps': exercise.reps,
              'rest': exercise.rest,
              'notes': exercise.notes,
              'targetMuscle': exercise.targetMuscle,
              'gif': exercise.gif,
            }).toList(),
            'warmup': day.warmup,
            'cooldown': day.cooldown,
            'totalTime': day.totalTime,
          }).toList(),
          'progression_notes': workoutPlan.progressionNotes,
        });
      }

      return workoutPlan;
    } catch (e) {
      throw Exception('Antrenman planı oluşturulamadı: $e');
    }
  }

  static Future<List<WorkoutPlan>> getUserWorkoutPlans() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      final response = await _supabase
          .from('workout_plans')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return (response as List)
          .map((data) => WorkoutPlan.fromJson(data))
          .toList();
    } catch (e) {
      throw Exception('Antrenman planları yüklenemedi: $e');
    }
  }

  // 4. Auth İşlemleri
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
    );
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  static User? get currentUser => _supabase.auth.currentUser;

  // 5. Storage İşlemleri (GIF'ler için)
  static String getGifUrl(String exerciseId) {
    return _supabase.storage
        .from('exercise-gifs')
        .getPublicUrl('$exerciseId.gif');
  }

  static String getMediaUrl(String exerciseId, {String format = 'gif'}) {
    return _supabase.storage
        .from('exercise-media')
        .getPublicUrl('$exerciseId.$format');
  }

  // 6. Real-time Subscriptions
  static RealtimeChannel subscribeToUserPlans() {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Kullanıcı giriş yapmamış');

    return _supabase
        .channel('user_plans')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'meal_plans',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (payload) {
            // Handle meal plan changes
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'workout_plans',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (payload) {
            // Handle workout plan changes
          },
        )
        .subscribe();
  }
}
