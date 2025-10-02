import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// Security Note: Credentials moved to environment variables for GitHub push safety
// Use Supabase Edge Function secrets:
// supabase secrets set VERTEX_AI_PROJECT_ID="august-journey-473119-t2"
// supabase secrets set VERTEX_AI_LOCATION="us-central1" 
// supabase secrets set VERTEX_AI_SERVICE_ACCOUNT_JSON='{"type":"service_account",...}'

const VERTEX_AI_PROJECT_ID = Deno.env.get("VERTEX_AI_PROJECT_ID") || "august-journey-473119-t2";
const VERTEX_AI_LOCATION = Deno.env.get("VERTEX_AI_LOCATION") || "us-central1";

// Environment-based service account (secure)
const VERTEX_AI_SERVICE_ACCOUNT = Deno.env.get("VERTEX_AI_SERVICE_ACCOUNT_JSON") 
  ? JSON.parse(Deno.env.get("VERTEX_AI_SERVICE_ACCOUNT_JSON")!)
  : null; // Will disable Google Cloud if secrets not set

const VERTEX_AI_URL = `https://${VERTEX_AI_LOCATION}-aiplatform.googleapis.com/v1/projects/${VERTEX_AI_PROJECT_ID}/locations/${VERTEX_AI_LOCATION}/publishers/google/models/gemini-1.5-flash:generateContent`;

console.log(`🚀 ZindeAI Router başlatılıyor...`);
console.log(`📍 Project ID: ${VERTEX_AI_PROJECT_ID}`);
console.log(`📍 Location: ${VERTEX_AI_LOCATION}`);
console.log(`🔑 Service Account: ${VERTEX_AI_SERVICE_ACCOUNT ? '✅ Mevcut' : '❌ Eksik (local fallback aktif)'}`);

// Supabase client initialization
const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const supabaseClient = createClient(supabaseUrl, supabaseServiceKey);

interface RequestData {
  goal: string;
  age: number;
  sex: string;
  weight: number;
  heightCm: number;
  activityLevel: string;
  diet: string;
  calories: number;
  primaryGoal: string;
  trainingDays?: number;
}

interface MealPlanRequest {
  userProfile: RequestData;
  planType?: string;
  duration?: number;
}

interface WorkoutPlanRequest {
  userProfile: RequestData;
  fitnessGoal: string;
  experienceLevel: string;
  availableEquipment: string[];
  trainingDays: number;
  sessionDuration: number;
  preferences: {
    favoriteExercises?: string[];
    avoidExercises?: string[];
    injuryConsiderations?: string[];
  };
}

// Default meal database (fallback)
const LOCAL_MEAL_DATABASE = [
  {
    name: "Tam buğday ekmeği + lor peyniri + domates",
    calories: 280,
    protein: 18,
    carbs: 35,
    fat: 8,
    category: "breakfast"
  },
  {
    name: "Tavuk sote + bulgur pilavı + yoğurt",
    calories: 420,
    protein: 35,
    carbs: 45,
    fat: 12,
    category: "lunch"
  },
  {
    name: "Ton balığı salatası + yeşil salata",
    calories: 350,
    protein: 28,
    carbs: 20,
    fat: 18,
    category: "lunch"
  },
  {
    name: "Fırın somon + patates + sebze",
    calories: 450,
    protein: 32,
    carbs: 38,
    fat: 22,
    category: "dinner"
  },
  {
    name: "Meyve + ceviz + badem",
    calories: 180,
    protein: 6,
    carbs: 20,
    fat: 12,
    category: "snack"
  }
];

async function generateMealPlan(requestData: MealPlanRequest): Promise<any> {
  console.log("🍽️ Meal plan generation başladı");
  console.log("📊 Request data:", JSON.stringify(requestData, null, 2));

  try {
    // Gemini API çağrısı (only if service account is available)
    if (VERTEX_AI_SERVICE_ACCOUNT) {
      try {
        return await generateMealPlanWithGemini(requestData);
      } catch (error) {
        console.log("⚠️ Gemini API hatası:", error.message);
        console.log("🔄 Local fallback'e geçiliyor...");
      }
    } else {
      console.log("🚀 Doğrudan local database kullanılıyor...");
    }

    // Local database fallback
    return generateLocalMealPlan(requestData);

  } catch (error) {
    console.error("❌ Meal plan generation hatası:", error);
    
    return {
      success: false,
      error: error.message,
      fallbackUsed: true,
      mealPlan: generateEmergencyMealPlan(requestData)
    };
  }
}

async function generateWorkoutPlan(requestData: WorkoutPlanRequest): Promise<any> {
  console.log("🏋️ Workout plan generation başladı");
  
  try {
    // Simple workout plan generation for now
    const workoutPlan = generateSimpleWorkoutPlan(requestData);
    
    return {
      success: true,
      fallbackUsed: true,
      workflowPlan: workoutPlan
    };

  } catch (error) {
    console.error("❌ Workout plan generation hatası:", error);
    
    return {
      success: false,
      error: error.message,
      fallbackUsed: true,
      workoutPlan: null
    };
  }
}

async function generateMealPlanWithGemini(requestData: MealPlanRequest): Promise<any> {
  // Google Cloud authentication setup would go here
  // For now, return error to use local fallback
  
  throw new Error("Gemini API temporarily disabled - using local fallback");
  
  /*
  // TODO: Implement proper Google Cloud authentication
  const accessToken = await getGoogleAccessToken();
  
  const geminiResponse = await fetch(VERTEX_AI_URL, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      contents: [{
        parts: [{
          text: `Generate meal plan for: ${JSON.stringify(requestData)}`
        }]
      }]
    })
  });
  
  const result = await geminiResponse.json();
  return {
    success: true,
    fallbackUsed: false,
    mealPlan: result
  };
  */
}

function generateLocalMealPlan(requestData: MealPlanRequest): any {
  console.log("🗃️ Local database meal plan generation");
  
  const { userProfile } = requestData;
  const days = userProfile.calories > 2000 ? 7 : 5; // Simple logic
  
  const mealPlan = {
    planType: "local_generated",
    duration: days,
    meals: []
  };

  // Generate meals for each day
  for (let day = 0; day < days; day++) {
    const dayMeals = LOCAL_MEAL_DATABASE.map(meal => ({
      ...meal,
      day: day + 1,
      mealtime: getMealtimeByCategory(meal.category)
    }));
    
    mealPlan.meals.push(...dayMeals);
  }

  return {
或  success: true,
    fallbackUsed: true, 
    mealPlan: mealPlan,
    message: "Local database ile üretildi"
  };
}

function generateSimpleWorkoutPlan(requestData: WorkoutPlanRequest): any {
  const workouts = [];
  const trainingDays = requestData.trainingDays || 3;
  
  for (let i = 0; i < trainingDays; i++) {
    workouts.push({
      day: i + 1,
      exercises: [
        {
          name: "Push-up",
          sets: 3,
          reps: "10-15",
          rest: "60s"
        },
        {
          name: "Squat", 
          sets: 3,
          reps: "12-15",
          rest: "60s"
        }
      ]
    });
  }
  
  return {
    planType: "simple_gym_routine",
    duration: trainingDays,
    workouts: workouts
  };
}

function generateEmergencyMealPlan(requestData: any): any {
  return {
    planType: "emergency",
    duration: 3,
    meals: LOCAL_MEAL_DATABASE.slice(0, 3).map((meal, index) => ({
      ...meal,
      day: index + 1,
      mealtime: getMealtimeByCategory(meal.category)
    })),
    note: "Acil durum beslenme planı"
  };
}

function getMealtimeByCategory(category: string): string {
  const mapping = {
    "breakfast": "Sabah",
    "lunch": "Öğle", 
    "dinner": "Akşam",
    "snack": "Ara Öğün"
  };
  return mapping[category] || "Genel";
}

// Main server handler
serve(async (req) => {
  try {
    console.log(`🌐 ${req.method} ${req.url}`);
    
    if (req.method !== "POST") {
      return new Response(JSON.stringify({ 
        error: "Only POST requests allowed" 
      }), {
        status: 405,
        headers: { "Content-Type": "application/json" }
      });
    }

    const url = new URL(req.url);
    const pathname = url.pathname.split('/').pop();

    const requestData = await req.json();

    if (pathname === "meal-plan") {
      const result = await generateMealPlan(requestData);
      return new Response(JSON.stringify(result), {
        status: 200,
        headers: { 
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Methods": "POST, OPTIONS",
          "Access-Control-Allow-Headers": "Content-Type"
        }
      });
    }
    
    if (pathname === "workout-plan") {
      const result = await generateWorkoutPlan(requestData);
      return new Response(JSON.stringify(result), {
        status: 200,
        headers: { 
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Methods": "POST, OPTIONS",
          "Access-Control-Allow-Headers": "Content-Type"
        }
      });
    }

    // Default response for unmatched paths
    return new Response(JSON.stringify({ 
      message: "ZindeAI Router is running",
      availableEndpoints: ["/meal-plan", "/workout-plan"],
      status: "active"
    }), {
      status: 200,
      headers: { 
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*"
      }
    });

  } catch (error) {
    console.error("❌ Server error:", error);
    
    return new Response(JSON.stringify({ 
        error: error.message,
      stack: error.stack 
    }), {
        status: 500,
      headers: { "Content-Type": "application/json" }
    });
  }
});