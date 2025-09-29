-- Meal progress tablosu
CREATE TABLE IF NOT EXISTS meal_progress (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  progress JSONB DEFAULT '{}',
  week_start DATE DEFAULT date_trunc('week', CURRENT_DATE),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, week_start)
);

-- Weekly reports tablosu
CREATE TABLE IF NOT EXISTS weekly_reports (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  week_start DATE,
  week_end DATE,
  completion_rate DECIMAL(5,2),
  total_meals INTEGER,
  completed_meals INTEGER,
  report_data JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Shopping lists tablosu
CREATE TABLE IF NOT EXISTS shopping_lists (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  meal_plan_id UUID,
  items JSONB,
  checked_items JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS policies
ALTER TABLE meal_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE weekly_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE shopping_lists ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can manage own progress" ON meal_progress
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can view own reports" ON weekly_reports
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own shopping lists" ON shopping_lists
  FOR ALL USING (auth.uid() = user_id);
