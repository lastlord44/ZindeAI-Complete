// lib/utils/wire.dart
import '../models/user_profile.dart';

extension _EnumWire on Object {
  String sexWire(Sex s) => s == Sex.male ? 'M' : 'F';
  String goalWire(Goal g) => {
        Goal.cut: 'cut',
        Goal.maintain: 'maintain',
        Goal.bulk: 'bulk',
        Goal.gain_muscle_loss_fat: 'gain_muscle_loss_fat',
        Goal.gain_strength: 'gain_strength',
        Goal.gain_muscle_gain_weight: 'gain_muscle_gain_weight',
      }[g]!;
  String activityWire(Activity a) => {
        Activity.sedentary: 'sedentary',
        Activity.light: 'light',
        Activity.moderate: 'moderate',
        Activity.very_active: 'very_active',
      }[a]!;
  String modeWire(TrainingMode m) => {
        TrainingMode.gym: 'gym',
        TrainingMode.home: 'home',
        TrainingMode.hybrid: 'hybrid',
      }[m]!;
  String splitWire(SplitPreference s) => {
        SplitPreference.upperLower: 'upperLower',
        SplitPreference.pushPullLegs: 'pushPullLegs',
        SplitPreference.fullBody: 'fullBody',
        SplitPreference.broSplit: 'broSplit',
        SplitPreference.custom: 'custom',
      }[s]!;
}

/// Tüm yerlerde **bunu** kullan: profile → API/wire JSON
Map<String, dynamic> buildPlanRequest(UserProfile p) {
  // training alanın yoksa null güvenliği:
  final t = (p as dynamic).training; // proje kodu profile.training içeriyor
  final hasTraining = t != null;

  if (!hasTraining) {
    return {
      'sex': (Object()).sexWire(p.sex),
      'age': p.age,
      'height_cm': p.heightCm,
      'weight_kg': p.weightKg,
      'goal': (Object()).goalWire(p.goal),
      'activity': (Object()).activityWire(p.activity),
      'diet_flags': p.dietFlags,
      'dislikes': p.dislikes,
    };
  }

  String mode = 'hybrid';
  String split = 'fullBody';
  int daysPerWeek = 3;
  List<String> days = const [];
  List<String> equipment = const [];

  try {
    mode = (Object()).modeWire(t.mode as TrainingMode);
    split = (Object()).splitWire(t.splitPreference as SplitPreference);
    daysPerWeek = (t.daysPerWeek as int);
    days = (t.days as List).cast<String>();
    equipment = (t.equipment as List).cast<String>();
  } catch (e) {
    print('⚠️ Wire parsing error: $e - Using defaults');
  }

  return {
    'sex': (Object()).sexWire(p.sex),
    'age': p.age,
    'height_cm': p.heightCm,
    'weight_kg': p.weightKg,
    'goal': (Object()).goalWire(p.goal),
    'activity': (Object()).activityWire(p.activity),
    'diet_flags': p.dietFlags,
    'dislikes': p.dislikes,
    'training': {
      'daysPerWeek': daysPerWeek,
      'mode': mode,
      'splitPreference': split,
      'equipment': equipment,
      'days': days,
    }
  };
}
