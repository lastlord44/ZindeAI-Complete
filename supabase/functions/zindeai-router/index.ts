import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders })
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const { action, data, userId } = await req.json()
    console.log('Received request:', { action, userId })

    let response = {}

    switch (action) {
      case 'generate-meal-plan':
        // Basit meal plan generator
        const mealPlan = generateMealPlan(data)
        
        // Meal plan'ı kaydet
        const { data: savedPlan, error: saveError } = await supabase
          .from('meal_plans')
          .insert({
            user_id: userId,
            total_calories: mealPlan.totalCalories,
            total_protein: mealPlan.totalProtein,
            total_carbs: mealPlan.totalCarbs,
            total_fat: mealPlan.totalFat,
            weekly_plan: mealPlan.weeklyPlan,
            days_per_week: 7,
            goal: data.goal || 'maintain',
            diet: data.diet || 'balanced'
          })
          .select()
          .single()

        if (saveError) throw saveError

        // API log kaydet
        await supabase.from('api_logs').insert({
          endpoint: 'generate-meal-plan',
          method: 'POST',
          request_body: data,
          response_body: savedPlan,
          status_code: 200,
          user_id: userId
        })

        response = {
          success: true,
          data: savedPlan,
          message: 'Meal plan created successfully'
        }
        break

      case 'generate-workout-plan':
        // Workout plan generator
        const workoutPlan = generateWorkoutPlan(data)
        
        const { data: savedWorkout, error: workoutError } = await supabase
          .from('workout_plans')
          .insert({
            user_id: userId,
            split_type: data.splitType || 'full_body',
            mode: data.mode || 'home',
            goal: data.goal || 'general_fitness',
            days: workoutPlan.days,
            week_number: 1
          })
          .select()
          .single()

        if (workoutError) throw workoutError

        response = {
          success: true,
          data: savedWorkout,
          message: 'Workout plan created successfully'
        }
        break

      default:
        response = {
          success: false,
          error: 'Unknown action: ' + action
        }
    }

    return new Response(
      JSON.stringify(response),
      {
        status: 200,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        }
      }
    )

  } catch (error) {
    console.error('Edge Function Error:', error)
    
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message,
        stack: error.stack
      }),
      {
        status: 200, // Flutter'da handle etmek için 200 dönüyoruz
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        }
      }
    )
  }
})

// Basit meal plan generator
function generateMealPlan(data: any) {
  const days = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar']
  const weeklyPlan: any = {}

  days.forEach((day) => {
    weeklyPlan[day] = {
      meals: [
        {
          name: 'Kahvaltı',
          foods: [
            { name: 'Yumurta', amount: '2 adet', calories: 140, protein: 12, carbs: 2, fat: 10 },
            { name: 'Tam Buğday Ekmek', amount: '2 dilim', calories: 160, protein: 6, carbs: 30, fat: 2 },
            { name: 'Beyaz Peynir', amount: '50g', calories: 120, protein: 8, carbs: 2, fat: 9 }
          ],
          totalCalories: 420,
          totalProtein: 26,
          totalCarbs: 34,
          totalFat: 21
        },
        {
          name: 'Öğle Yemeği',
          foods: [
            { name: 'Tavuk Göğsü', amount: '150g', calories: 250, protein: 47, carbs: 0, fat: 5 },
            { name: 'Pirinç Pilavı', amount: '150g', calories: 195, protein: 4, carbs: 42, fat: 1 },
            { name: 'Salata', amount: '200g', calories: 40, protein: 2, carbs: 8, fat: 1 }
          ],
          totalCalories: 485,
          totalProtein: 53,
          totalCarbs: 50,
          totalFat: 7
        },
        {
          name: 'Akşam Yemeği',
          foods: [
            { name: 'Somon Balığı', amount: '150g', calories: 280, protein: 40, carbs: 0, fat: 12 },
            { name: 'Quinoa', amount: '100g', calories: 120, protein: 4, carbs: 21, fat: 2 },
            { name: 'Brokoli', amount: '150g', calories: 50, protein: 4, carbs: 10, fat: 1 }
          ],
          totalCalories: 450,
          totalProtein: 48,
          totalCarbs: 31,
          totalFat: 15
        },
        {
          name: 'Ara Öğünler',
          foods: [
            { name: 'Badem', amount: '30g', calories: 180, protein: 6, carbs: 6, fat: 16 },
            { name: 'Muz', amount: '1 adet', calories: 105, protein: 1, carbs: 27, fat: 0 },
            { name: 'Yoğurt', amount: '150g', calories: 90, protein: 5, carbs: 14, fat: 2 }
          ],
          totalCalories: 375,
          totalProtein: 12,
          totalCarbs: 47,
          totalFat: 18
        }
      ],
      dayTotals: {
        calories: 1730,
        protein: 139,
        carbs: 162,
        fat: 61
      }
    }
  })

  return {
    weeklyPlan,
    totalCalories: 1730,
    totalProtein: 139,
    totalCarbs: 162,
    totalFat: 61
  }
}

// Basit workout plan generator
function generateWorkoutPlan(data: any) {
  return {
    days: {
      'Pazartesi': {
        exercises: [
          { name: 'Şınav', sets: 3, reps: '12-15', rest: '60s' },
          { name: 'Squat', sets: 3, reps: '15-20', rest: '60s' },
          { name: 'Plank', sets: 3, reps: '30-60s', rest: '45s' }
        ]
      },
      'Çarşamba': {
        exercises: [
          { name: 'Burpee', sets: 3, reps: '10-12', rest: '90s' },
          { name: 'Dağ Tırmanıcısı', sets: 3, reps: '20-30', rest: '60s' },
          { name: 'Jumping Jack', sets: 3, reps: '30-40', rest: '45s' }
        ]
      },
      'Cuma': {
        exercises: [
          { name: 'Lunges', sets: 3, reps: '12-15 her bacak', rest: '60s' },
          { name: 'Dips', sets: 3, reps: '10-12', rest: '60s' },
          { name: 'Russian Twist', sets: 3, reps: '20-30', rest: '45s' }
        ]
      }
    }
  }
}