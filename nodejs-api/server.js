require('dotenv').config();
const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const fs = require('fs');
const path = require('path');
const axios = require('axios');
const { VertexAI } = require('@google-cloud/vertexai');

// Vertex AI Configuration
const PROJECT_ID = 'august-journey-473119-t2'; // Google Cloud Project ID
const LOCATION = 'us-central1';
const MODEL_ID = 'gemini-2.0-flash-exp';

// Initialize Vertex AI client
const vertex_ai = new VertexAI({ 
  project: PROJECT_ID, 
  location: LOCATION,
  keyFilename: path.join(__dirname, 'service-account.json')
});

const app = express();
const PORT = process.env.PORT || 3002;

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Data file path
const DATA_FILE = path.join(__dirname, 'data.json');

// Helper function to read data
function readData() {
  try {
    const data = fs.readFileSync(DATA_FILE, 'utf8');
    return JSON.parse(data);
  } catch (error) {
    console.error('Error reading data file:', error);
    return {
      users: [],
      meal_plans: [],
      workout_plans: [],
      api_keys: {},
      settings: {}
    };
  }
}

// Helper function to write data
function writeData(data) {
  try {
    fs.writeFileSync(DATA_FILE, JSON.stringify(data, null, 2));
    return true;
  } catch (error) {
    console.error('Error writing data file:', error);
    return false;
  }
}

// Routes

// Health check
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    message: 'ZindeAI Node.js API is running',
    timestamp: new Date().toISOString()
  });
});

// Get all data
app.get('/api/data', (req, res) => {
  const data = readData();
  res.json(data);
});

// ZindeAI Router - Main endpoint
app.post('/api/zindeai-router', async (req, res) => {
  try {
    const { planType, ...params } = req.body;
    
    console.log('Received request:', { planType, params });
    
    if (planType === 'meal') {
      // Meal plan generation
      const mealPlan = await generateMealPlan(params);
      
      // Save to local storage
      const data = readData();
      data.meal_plans.push({
        id: Date.now().toString(),
        ...mealPlan,
        created_at: new Date().toISOString()
      });
      writeData(data);
      
      // Debug: Log mealPlan structure
      console.log('MealPlan structure:', {
        hasMeals: !!mealPlan.meals,
        mealsType: typeof mealPlan.meals,
        mealsLength: mealPlan.meals ? mealPlan.meals.length : 'undefined'
      });
      
      res.json({
        success: true,
        planType: 'meal',
        data: mealPlan,
        weeklyPlan: mealPlan.meals || [],
        dailyPlan: mealPlan.meals || []
      });
      
    } else if (planType === 'workout') {
      // Workout plan generation
      const workoutPlan = await generateWorkoutPlan(params);
      
      // Save to local storage
      const data = readData();
      data.workout_plans.push({
        id: Date.now().toString(),
        ...workoutPlan,
        created_at: new Date().toISOString()
      });
      writeData(data);
      
      res.json({
        success: true,
        planType: 'workout',
        data: workoutPlan,
        weeklyPlan: workoutPlan.workouts || [],
        dailyPlan: workoutPlan.workouts || []
      });
      
    } else {
      res.status(400).json({
        success: false,
        error: 'Invalid planType. Must be "meal" or "workout"'
      });
    }
    
  } catch (error) {
    console.error('Error in zindeai-router:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Generate Meal Plan with Vertex AI
async function generateMealPlan(params) {
  const { goal, age, sex, weight_kg, height_cm, activity_level, diet, daysOfWeek, calories } = params;
  
  // Flutter'dan gelen parametreleri düzelt
  const actualAge = age || 30;
  const actualSex = sex || 'male';
  const actualWeight = weight_kg || 70;
  const actualHeight = height_cm || 170;
  const actualActivity = activity_level || 'moderate';
  const actualDiet = diet || 'balanced';
  const actualDays = daysOfWeek || 7;
  
  try {
    // Vertex AI Gemini call
    const generativeModel = vertex_ai.getGenerativeModel({
      model: MODEL_ID,
    });

    const request = {
      contents: [{
        role: 'user',
        parts: [{
          text: `Sen dünyanın en iyi diyetisyenisin! ${actualAge} yaşında, ${actualWeight}kg, ${actualHeight}cm boyunda ${actualSex} için ${actualDays} günlük detaylı beslenme planı oluştur.
            
            HEDEF: ${goal}
            AKTİVİTE SEVİYESİ: ${actualActivity}
            DİYET TERCİHİ: ${actualDiet}
            GÜNLÜK KALORİ: ${calories || 2000}
            
            ÖNEMLİ: Günlük protein miktarı 120-150g arasında olsun! Her öğünde yüksek protein içeriği bulunsun.
            
            JSON formatında yanıt ver:
            {
              "goal": "${goal}",
              "user_info": {
                "age": ${actualAge},
                "sex": "${actualSex}",
                "weight_kg": ${actualWeight},
                "height_cm": ${actualHeight},
                "activity_level": "${actualActivity}",
                "diet": "${actualDiet}"
              },
              "days": ${actualDays},
              "meals": [
                {
                  "day": 1,
                  "breakfast": {
                    "name": "Kahvaltı",
                    "calories": 500,
                    "protein": 35,
                    "carbs": 50,
                    "fat": 18,
                    "foods": ["Yumurta (3 adet)", "Tam buğday ekmeği", "Peynir", "Zeytin", "Domates"]
                  },
                  "lunch": {
                    "name": "Öğle Yemeği",
                    "calories": 700,
                    "protein": 45,
                    "carbs": 65,
                    "fat": 22,
                    "foods": ["Tavuk göğsü (200g)", "Kahverengi pilav", "Yeşil salata", "Avokado"]
                  },
                  "dinner": {
                    "name": "Akşam Yemeği",
                    "calories": 600,
                    "protein": 40,
                    "carbs": 45,
                    "fat": 20,
                    "foods": ["Somon balığı", "Buharda sebze", "Yoğurt", "Badem"]
                  }
                }
              ]
            }
            
            ÖNEMLİ: Sadece JSON formatında yanıt ver, başka açıklama yapma!`
        }]
      }],
      generationConfig: {
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 8192,
      }
    };

    const response = await generativeModel.generateContent(request);

    // Parse Vertex AI response
    const geminiText = response.response.candidates[0].content.parts[0].text;
    console.log('Vertex AI raw response:', geminiText);
    
    const jsonMatch = geminiText.match(/\{[\s\S]*\}/);
    
    if (jsonMatch) {
      const parsedData = JSON.parse(jsonMatch[0]);
      console.log('Parsed Gemini data:', JSON.stringify(parsedData, null, 2));
      return parsedData;
    } else {
      console.error('No JSON found in Gemini response');
      throw new Error('Invalid JSON response from Gemini');
    }
    
  } catch (error) {
    console.error('Gemini API Error:', error.message);
    console.error('Full error:', error);
    
    // Gemini başarısız oldu, hata fırlat
    throw new Error(`Gemini API failed: ${error.message}`);
  }
}

// Generate Workout Plan with Gemini API
async function generateWorkoutPlan(params) {
  const { userId, fitnessLevel, daysPerWeek, goal, preferredSplit } = params;
  
  try {
    // Gemini API call
    // Vertex AI Gemini call
    const generativeModel = vertex_ai.getGenerativeModel({
      model: MODEL_ID,
    });

    const request = {
      contents: [{
        role: 'user',
        parts: [{
          text: `Sen dünyanın en iyi antrenman koçusun! Profesyonel bir antrenman programı hazırla.

KULLANICI BİLGİLERİ:
- Yaş: ${params.age}
- Cinsiyet: ${params.gender}
- Kilo: ${params.weight} kg
- Boy: ${params.height} cm
- Fitness Seviyesi: ${fitnessLevel}
- Hedef: ${goal}
- Haftalık Antrenman Günü: ${daysPerWeek}
- Antrenman Yeri: ${params.mode}
- Tercih Edilen Split: ${preferredSplit || 'Otomatik'}

GÖREVİN:
1. Kullanıcının hedefine uygun profesyonel antrenman programı hazırla
2. Fitness seviyesine göre uygun egzersizler seç
3. Haftalık gün sayısına göre optimal split belirle
4. Her egzersiz için set, tekrar ve dinlenme süreleri ver
5. Antrenman süresini belirt

LÜTFEN AŞAĞIDAKİ JSON FORMATINDA YANIT VER:
            {
              "userId": "${userId}",
              "weekNumber": 1,
              "splitType": "${preferredSplit || 'Full Body'}",
              "mode": "${params.mode}",
              "fitnessLevel": "${fitnessLevel}",
              "daysPerWeek": ${daysPerWeek},
              "goal": "${goal}",
              "preferredSplit": "${preferredSplit}",
              "workouts": [
                {
                  "day": 1,
                  "type": "Workout Type",
                  "exercises": [
                    {
                      "name": "Exercise Name",
                      "sets": 3,
                      "reps": 12,
                      "rest": "60s"
                    }
                  ],
                  "duration": "45 minutes",
                  "difficulty": "${fitnessLevel}"
                }
              ]
            }
            
            ÖNEMLİ: Sadece JSON formatında yanıt ver, başka açıklama yapma!`
        }]
      }],
      generationConfig: {
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 8192,
      }
    };

    const response = await generativeModel.generateContent(request);

    // Parse Vertex AI response
    const geminiText = response.response.candidates[0].content.parts[0].text;
    console.log('Vertex AI raw response:', geminiText);
    
    const jsonMatch = geminiText.match(/\{[\s\S]*\}/);
    
    if (jsonMatch) {
      const parsedData = JSON.parse(jsonMatch[0]);
      console.log('Parsed Gemini data:', JSON.stringify(parsedData, null, 2));
      return parsedData;
    } else {
      console.error('No JSON found in Gemini response');
      throw new Error('Invalid JSON response from Gemini');
    }
    
  } catch (error) {
    console.error('Gemini API Error:', error.message);
    console.error('Full error:', error);
    
    // Gemini başarısız oldu, hata fırlat
    throw new Error(`Gemini API failed: ${error.message}`);
  }
}

// Get meal plans
app.get('/api/meal-plans', (req, res) => {
  const data = readData();
  res.json(data.meal_plans);
});

// Get workout plans
app.get('/api/workout-plans', (req, res) => {
  const data = readData();
  res.json(data.workout_plans);
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 ZindeAI Node.js API running on port ${PORT}`);
  console.log(`📊 Health check: http://localhost:${PORT}/health`);
  console.log(`🍽️  Meal plans: http://localhost:${PORT}/api/meal-plans`);
  console.log(`💪 Workout plans: http://localhost:${PORT}/api/workout-plans`);
  console.log(`🎯 Main endpoint: http://localhost:${PORT}/api/zindeai-router`);
});
