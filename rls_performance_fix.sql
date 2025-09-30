-- Bu script, RLS performans uyarılarını düzeltmek için auth.uid() fonksiyonunu
-- (select auth.uid()) ile değiştirir, böylece fonksiyon sorgu başına sadece bir kez çalışır.

-- 1. user_profiles tablosu için düzeltme
DROP POLICY IF EXISTS "Users can manage their own profile" ON public.user_profiles;
CREATE POLICY "Users can manage their own profile" 
ON public.user_profiles FOR ALL 
USING ((select auth.uid()) = id);

-- 2. meal_plans tablosu için düzeltme
DROP POLICY IF EXISTS "Users can manage their own meal plans" ON public.meal_plans;
CREATE POLICY "Users can manage their own meal plans" 
ON public.meal_plans FOR ALL 
USING ((select auth.uid()) = user_id);

-- 3. workout_plans tablosu için düzeltme
DROP POLICY IF EXISTS "Users can manage their own workout plans" ON public.workout_plans;
CREATE POLICY "Users can manage their own workout plans" 
ON public.workout_plans FOR ALL 
USING ((select auth.uid()) = user_id);

-- 4. user_progress tablosu için düzeltme
DROP POLICY IF EXISTS "Users can manage their own progress" ON public.user_progress;
CREATE POLICY "Users can manage their own progress" 
ON public.user_progress FOR ALL 
USING ((select auth.uid()) = user_id);

-- 5. api_logs tablosu için düzeltme
DROP POLICY IF EXISTS "Users can manage their own api logs" ON public.api_logs;
CREATE POLICY "Users can manage their own api logs" 
ON public.api_logs FOR ALL 
USING ((select auth.uid()) = user_id);

-- 6. health_status tablosu için düzeltme
DROP POLICY IF EXISTS "Users can manage their own health status" ON public.health_status;
CREATE POLICY "Users can manage their own health status" 
ON public.health_status FOR ALL 
USING ((select auth.uid()) = user_id);

-- 7. exercise_metadata tablosu için düzeltme
DROP POLICY IF EXISTS "Users can manage their own exercise metadata" ON public.exercise_metadata;
CREATE POLICY "Users can manage their own exercise metadata" 
ON public.exercise_metadata FOR ALL 
USING ((select auth.uid()) = user_id);

-- 8. batch_check_results tablosu için düzeltme
DROP POLICY IF EXISTS "Users can manage their own batch check results" ON public.batch_check_results;
CREATE POLICY "Users can manage their own batch check results" 
ON public.batch_check_results FOR ALL 
USING ((select auth.uid()) = user_id);

-- 9. api_keys tablosu için düzeltme (sadece admin erişimi)
DROP POLICY IF EXISTS "Only service role can access api keys" ON public.api_keys;
CREATE POLICY "Only service role can access api keys" 
ON public.api_keys FOR ALL 
USING (auth.role() = 'service_role');

-- 10. Tüm tablolar için RLS'yi etkinleştir
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meal_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.api_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.health_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exercise_metadata ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.batch_check_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.api_keys ENABLE ROW LEVEL SECURITY;

-- 11. Performans için index'ler oluştur
CREATE INDEX IF NOT EXISTS idx_user_profiles_id ON public.user_profiles(id);
CREATE INDEX IF NOT EXISTS idx_meal_plans_user_id ON public.meal_plans(user_id);
CREATE INDEX IF NOT EXISTS idx_workout_plans_user_id ON public.workout_plans(user_id);
CREATE INDEX IF NOT EXISTS idx_user_progress_user_id ON public.user_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_api_logs_user_id ON public.api_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_health_status_user_id ON public.health_status(user_id);
CREATE INDEX IF NOT EXISTS idx_exercise_metadata_user_id ON public.exercise_metadata(user_id);
CREATE INDEX IF NOT EXISTS idx_batch_check_results_user_id ON public.batch_check_results(user_id);

-- 12. RLS performans uyarılarını kontrol et
-- Bu script çalıştıktan sonra RLS performans uyarıları ortadan kalkmalı














