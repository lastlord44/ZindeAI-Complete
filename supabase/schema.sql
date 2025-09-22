-- ZindeAI Database Schema
-- Supabase SQL Editor'da çalıştırın

-- 1. User Profiles Table
CREATE TABLE IF NOT EXISTS user_profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  age INTEGER CHECK (age >= 10 AND age <= 100),
  height_cm INTEGER CHECK (height_cm >= 100 AND height_cm <= 250),
  weight_kg DECIMAL(5,2) CHECK (weight_kg >= 30 AND weight_kg <= 300),
  sex VARCHAR(10) CHECK (sex IN ('male', 'female', 'other')),
  goal VARCHAR(50) CHECK (goal IN ('lose', 'maintain', 'gain', 'muscle_gain', 'fat_loss')),
  activity_level VARCHAR(20) CHECK (activity_level IN ('low', 'med', 'high', 'very_high')),
  training_preferences JSONB DEFAULT '{}',
  diet_flags TEXT[] DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Meal Plans Table
CREATE TABLE IF NOT EXISTS meal_plans (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  total_calories INTEGER NOT NULL,
  total_protein INTEGER DEFAULT 0,
  total_carbs INTEGER DEFAULT 0,
  total_fat INTEGER DEFAULT 0,
  weekly_plan JSONB,
  days_per_week INTEGER DEFAULT 7 CHECK (days_per_week >= 1 AND days_per_week <= 7),
  goal VARCHAR(50),
  diet VARCHAR(50),
  preferences JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Workout Plans Table
CREATE TABLE IF NOT EXISTS workout_plans (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  week_number INTEGER DEFAULT 1,
  split_type VARCHAR(50),
  mode VARCHAR(20) CHECK (mode IN ('home', 'gym', 'outdoor')),
  goal VARCHAR(50),
  days JSONB,
  progression_notes TEXT,
  next_week_adjustment TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Exercise Metadata Table (GIF'ler için)
CREATE TABLE IF NOT EXISTS exercise_metadata (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  exercise_id VARCHAR(100) UNIQUE NOT NULL,
  name VARCHAR(200) NOT NULL,
  description TEXT,
  target_muscle VARCHAR(100),
  difficulty_level VARCHAR(20) CHECK (difficulty_level IN ('beginner', 'intermediate', 'advanced')),
  equipment_needed TEXT[],
  media_formats JSONB DEFAULT '{}', -- {gif: true, mp4: true, webp: false}
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. User Progress Table
CREATE TABLE IF NOT EXISTS user_progress (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  workout_plan_id UUID REFERENCES workout_plans(id) ON DELETE CASCADE,
  completed_exercises JSONB DEFAULT '[]',
  workout_date DATE NOT NULL,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. Indexes for Performance
CREATE INDEX IF NOT EXISTS idx_user_profiles_user_id ON user_profiles(id);
CREATE INDEX IF NOT EXISTS idx_meal_plans_user_id ON meal_plans(user_id);
CREATE INDEX IF NOT EXISTS idx_meal_plans_created_at ON meal_plans(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_workout_plans_user_id ON workout_plans(user_id);
CREATE INDEX IF NOT EXISTS idx_workout_plans_created_at ON workout_plans(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_exercise_metadata_exercise_id ON exercise_metadata(exercise_id);
CREATE INDEX IF NOT EXISTS idx_user_progress_user_id ON user_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_user_progress_workout_date ON user_progress(workout_date DESC);

-- 7. Row Level Security (RLS) Policies
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE meal_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_progress ENABLE ROW LEVEL SECURITY;

-- User Profiles Policies
DROP POLICY IF EXISTS "Users can view own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON user_profiles;

CREATE POLICY "Users can view own profile" ON user_profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON user_profiles
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON user_profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Meal Plans Policies
DROP POLICY IF EXISTS "Users can view own meal plans" ON meal_plans;
DROP POLICY IF EXISTS "Users can insert own meal plans" ON meal_plans;
DROP POLICY IF EXISTS "Users can update own meal plans" ON meal_plans;
DROP POLICY IF EXISTS "Users can delete own meal plans" ON meal_plans;

CREATE POLICY "Users can view own meal plans" ON meal_plans
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own meal plans" ON meal_plans
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own meal plans" ON meal_plans
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own meal plans" ON meal_plans
  FOR DELETE USING (auth.uid() = user_id);

-- Workout Plans Policies
DROP POLICY IF EXISTS "Users can view own workout plans" ON workout_plans;
DROP POLICY IF EXISTS "Users can insert own workout plans" ON workout_plans;
DROP POLICY IF EXISTS "Users can update own workout plans" ON workout_plans;
DROP POLICY IF EXISTS "Users can delete own workout plans" ON workout_plans;

CREATE POLICY "Users can view own workout plans" ON workout_plans
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own workout plans" ON workout_plans
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own workout plans" ON workout_plans
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own workout plans" ON workout_plans
  FOR DELETE USING (auth.uid() = user_id);

-- User Progress Policies
DROP POLICY IF EXISTS "Users can view own progress" ON user_progress;
DROP POLICY IF EXISTS "Users can insert own progress" ON user_progress;
DROP POLICY IF EXISTS "Users can update own progress" ON user_progress;

CREATE POLICY "Users can view own progress" ON user_progress
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own progress" ON user_progress
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own progress" ON user_progress
  FOR UPDATE USING (auth.uid() = user_id);

-- 8. Functions for Auto-updating timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for auto-updating timestamps
DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON user_profiles;
DROP TRIGGER IF EXISTS update_meal_plans_updated_at ON meal_plans;
DROP TRIGGER IF EXISTS update_workout_plans_updated_at ON workout_plans;

CREATE TRIGGER update_user_profiles_updated_at BEFORE UPDATE ON user_profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_meal_plans_updated_at BEFORE UPDATE ON meal_plans
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_workout_plans_updated_at BEFORE UPDATE ON workout_plans
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 9. Storage Buckets (SQL Editor'da çalıştırın)
INSERT INTO storage.buckets (id, name, public) VALUES 
  ('exercise-gifs', 'exercise-gifs', true),
  ('exercise-media', 'exercise-media', true);

-- 10. Sample Data (Test için)
INSERT INTO exercise_metadata (exercise_id, name, description, target_muscle, difficulty_level, equipment_needed, media_formats) VALUES
  ('push-up', 'Şınav', 'Klasik şınav hareketi', 'Göğüs, Omuz, Triceps', 'beginner', '{}', '{"gif": true, "mp4": true}'),
  ('squat', 'Squat', 'Temel squat hareketi', 'Bacak, Kalça', 'beginner', '{}', '{"gif": true, "mp4": true}'),
  ('plank', 'Plank', 'Plank pozisyonu', 'Core, Karın', 'beginner', '{}', '{"gif": true, "mp4": true}'),
  ('burpee', 'Burpee', 'Tam vücut egzersizi', 'Tüm Vücut', 'intermediate', '{}', '{"gif": true, "mp4": true}'),
  ('mountain-climber', 'Dağ Tırmanıcısı', 'Kardiyovasküler egzersiz', 'Tüm Vücut', 'intermediate', '{}', '{"gif": true, "mp4": true}')
ON CONFLICT (exercise_id) DO NOTHING;
