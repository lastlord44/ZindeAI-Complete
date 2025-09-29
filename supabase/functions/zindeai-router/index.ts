import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
}

serve(async (req) => {
  console.log('=== SUPABASE EDGE FUNCTION BAŞLADI ===')
  console.log('Request method:', req.method)
  console.log('Request URL:', req.url)

  // CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const body = await req.json()
    console.log('Request body:', body)
    
    const { planType, calories, goal, diet, daysPerWeek, preferences, age, sex, weight, height, activity } = body

    if (planType === 'meal') {
      return await generateMealPlan(body)
    } else if (planType === 'workout') {
      return await generateWorkoutPlan(body)
    } else {
      throw new Error('Invalid plan type')
    }

  } catch (error) {
    console.error('=== SUPABASE EDGE FUNCTION HATASI ===')
    console.error('Error type:', typeof error)
    console.error('Error stack:', error.stack)
    console.error('Full error object:', error)
    console.error('Error message:', error.message)
    
    return new Response(JSON.stringify({ 
      error: 'Request failed', 
      details: error.message 
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }
})

async function generateMealPlan(params: any) {
  const {
    age = 25,
    sex = 'male',
    weight = 70,
    height = 175,
    goal = 'maintain',
    diet = 'balanced',
    calories = 2000,
    daysPerWeek = 7,
    activity = 'moderately_active'
  } = params

  const actualAge = parseInt(age.toString())
  const actualWeight = parseFloat(weight.toString())
  const actualHeight = parseFloat(height.toString())
  const actualSex = sex.toString()
  const actualGoal = goal.toString()
  const actualDiet = diet.toString()
  const actualDays = parseInt(daysPerWeek.toString())
  const actualActivity = activity.toString()

  console.log('=== MEAL PLAN PARAMETRELERİ ===')
  console.log('Age:', actualAge)
  console.log('Sex:', actualSex)
  console.log('Weight:', actualWeight)
  console.log('Height:', actualHeight)
  console.log('Goal:', actualGoal)
  console.log('Diet:', actualDiet)
  console.log('Calories:', calories)
  console.log('Days:', actualDays)
  console.log('Activity:', actualActivity)

  const prompt = `Sen dünyanın en iyi diyetisyenisin! Profesyonel bir beslenme uzmanı olarak ${actualAge} yaşında, ${actualWeight}kg, ${actualHeight}cm boyunda ${actualSex} için ${actualDays} günlük detaylı beslenme planı oluştur.
      
      KULLANICI PROFİLİ:
      - Yaş: ${actualAge}
      - Cinsiyet: ${actualSex}
      - Kilo: ${actualWeight} kg
      - Boy: ${actualHeight} cm
      - Hedef: ${actualGoal}
      - Aktivite Seviyesi: ${actualActivity}
      - Diyet Tercihi: ${actualDiet}
      - Günlük Kalori: ${calories || 2000}
      
      ÖNEMLİ KURALLAR:
      1. Her gün 5 öğün olacak: 1 kahvaltı + 2 ana öğün + 2 ara öğün
      2. Günlük protein miktarı 120-150g arasında olsun
      3. Her öğünde yüksek protein içeriği bulunsun
      4. Profil bilgilerine göre kişiselleştirilmiş yemekler seç
      5. Sağlıklı ve dengeli beslenme prensiplerini uygula
      6. TAMAMEN FARKLI yemek isimleri kullan - hiçbir örnek yemek ismi kullanma
      7. Farklı protein kaynakları kullan (tavuk, balık, et, yumurta, baklagil vb.)
      8. Farklı sebze, meyve ve tahıl kombinasyonları oluştur
      9. TÜRK MUTFAĞI yemekleri tercih et
      10. Her yemek için DETAYLI TARİF yaz: malzemeler, gramajlar, pişirme yöntemi, süre
      11. MUTLAKA her malzeme için gramaj belirt: "200g tavuk göğsü", "150g mercimek", "2 yemek kaşığı zeytinyağı"
      12. Pişirme sürelerini dakika olarak belirt: "15 dakika haşla", "20 dakika kavur"
      13. Porsiyon miktarlarını net belirt: "1 porsiyon için 300g", "2 kişilik"
      14. Malzeme listesinde her şeyin miktarını yaz: "1 orta boy soğan (100g)", "2 diş sarımsak (10g)"
      
      JSON formatında yanıt ver:
      {
        "goal": "${actualGoal}",
        "user_info": {
          "age": ${actualAge},
          "sex": "${actualSex}",
          "weight_kg": ${actualWeight},
          "height_cm": ${actualHeight},
          "activity_level": "${actualActivity}",
          "diet": "${actualDiet}",
          "daily_calories": ${calories || 2000}
        },
        "days": ${actualDays},
        "meals": [
          {
            "day": 1,
            "breakfast": {
              "name": "string",
              "calories": "number",
              "protein": "number",
              "carbs": "number",
              "fat": "number",
              "foods": ["string array"],
              "recipe": "DETAYLI TARİF: Her malzeme için gramaj (200g tavuk, 150g mercimek), pişirme yöntemi (haşla, kavur), süre (15 dakika), porsiyon miktarı"
            },
            "snack1": {
              "name": "string",
              "calories": "number",
              "protein": "number",
              "carbs": "number",
              "fat": "number",
              "foods": ["string array"],
              "recipe": "DETAYLI TARİF: Her malzeme için gramaj (200g tavuk, 150g mercimek), pişirme yöntemi (haşla, kavur), süre (15 dakika), porsiyon miktarı"
            },
            "lunch": {
              "name": "string",
              "calories": "number",
              "protein": "number",
              "carbs": "number",
              "fat": "number",
              "foods": ["string array"],
              "recipe": "DETAYLI TARİF: Her malzeme için gramaj (200g tavuk, 150g mercimek), pişirme yöntemi (haşla, kavur), süre (15 dakika), porsiyon miktarı"
            },
            "snack2": {
              "name": "string",
              "calories": "number",
              "protein": "number",
              "carbs": "number",
              "fat": "number",
              "foods": ["string array"],
              "recipe": "DETAYLI TARİF: Her malzeme için gramaj (200g tavuk, 150g mercimek), pişirme yöntemi (haşla, kavur), süre (15 dakika), porsiyon miktarı"
            },
            "dinner": {
              "name": "string",
              "calories": "number",
              "protein": "number",
              "carbs": "number",
              "fat": "number",
              "foods": ["string array"],
              "recipe": "DETAYLI TARİF: Her malzeme için gramaj (200g tavuk, 150g mercimek), pişirme yöntemi (haşla, kavur), süre (15 dakika), porsiyon miktarı"
            }
          }
        ]
      }`

  try {
    console.log('=== GEMINI API ÇAĞRISI BAŞLADI ===')
    
    // Gemini API endpoint
    const apiKey = "AIzaSyDBKGbsPR3LRs7dRYqkn4_QXEMmUvv8wE0"
    const geminiEndpoint = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=${apiKey}`
    
    console.log('Gemini endpoint:', geminiEndpoint)
    console.log('Prompt length:', prompt.length)
    console.log('Prompt preview:', prompt.substring(0, 200) + '...')
    
    const response = await fetch(geminiEndpoint, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        contents: [{
          role: 'user',
          parts: [{
            text: prompt
          }]
        }],
        generationConfig: {
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 8192,
        }
      })
    })

    console.log('Response status:', response.status)
    console.log('Response headers:', Object.fromEntries(response.headers.entries()))

    if (!response.ok) {
      const errorText = await response.text()
      console.error('Gemini API error response:', errorText)
      throw new Error(`Gemini API failed: ${response.status} ${response.statusText} - ${errorText}`)
    }

    const data = await response.json()
    console.log('Gemini API response received')
    
    if (data.candidates && data.candidates[0] && data.candidates[0].content) {
      const generatedText = data.candidates[0].content.parts[0].text
      console.log('Generated text length:', generatedText.length)
      console.log('Generated text preview:', generatedText.substring(0, 200) + '...')
      
      try {
        // JSON'u parse et
        const jsonMatch = generatedText.match(/\{[\s\S]*\}/)
        if (!jsonMatch) {
          throw new Error('No JSON found in Gemini response')
        }
        
        const mealPlan = JSON.parse(jsonMatch[0])
        console.log('✅ Meal plan JSON parsed successfully')
        
        // Her günün öğün sayısını kontrol et
        if (mealPlan.meals && mealPlan.meals.length > 0) {
          console.log('=== ÖĞÜN KONTROLÜ ===')
          mealPlan.meals.forEach((day: any, index: number) => {
            const mealKeys = Object.keys(day).filter(key => key !== 'day')
            console.log(`Gün ${day.day}: ${mealKeys.length} öğün - ${mealKeys.join(', ')}`)
          })
        }
        
        return new Response(JSON.stringify(mealPlan), {
          status: 200,
          headers: corsHeaders
        })
      } catch (parseError) {
        console.error('❌ JSON parse error:', parseError)
        console.log('Raw generated text:', generatedText)
        throw new Error(`JSON parse error: ${parseError.message}`)
      }
    } else {
      console.error('❌ Invalid response structure:', data)
      throw new Error('Invalid response structure from Gemini API')
    }
  } catch (error) {
    console.error('=== SUPABASE EDGE FUNCTION HATASI ===')
    console.error('Error type:', typeof error)
    console.error('Error stack:', error.stack)
    console.error('Full error object:', error)
    console.error('Error message:', error.message)
    
    return new Response(JSON.stringify({ 
      error: 'Meal plan generation failed', 
      details: error.message 
    }), {
      status: 500,
      headers: corsHeaders
    })
  }
}

async function generateWorkoutPlan(params: any) {
  const {
    age = 25,
    sex = 'male',
    weight = 70,
    height = 175,
    goal = 'muscle_gain',
    fitnessLevel = 'intermediate',
    daysPerWeek = 4,
    mode = 'gym',
    splitPreference = 'AUTO'
  } = params

  const actualAge = parseInt(age.toString())
  const actualWeight = parseFloat(weight.toString())
  const actualHeight = parseFloat(height.toString())
  const actualSex = sex.toString()
  const actualGoal = goal.toString()
  const actualFitnessLevel = fitnessLevel.toString()
  const actualDays = parseInt(daysPerWeek.toString())
  const actualMode = mode.toString()

  console.log('=== WORKOUT PLAN PARAMETRELERİ ===')
  console.log('Age:', actualAge)
  console.log('Sex:', actualSex)
  console.log('Weight:', actualWeight)
  console.log('Height:', actualHeight)
  console.log('Goal:', actualGoal)
  console.log('Fitness Level:', actualFitnessLevel)
  console.log('Days:', actualDays)
  console.log('Mode:', actualMode)

  const prompt = `Sen dünyanın en iyi fitness antrenörüsün! Profesyonel bir antrenör olarak ${actualAge} yaşında, ${actualWeight}kg, ${actualHeight}cm boyunda ${actualSex} için ${actualDays} günlük detaylı antrenman planı oluştur.
      
      KULLANICI PROFİLİ:
      - Yaş: ${actualAge}
      - Cinsiyet: ${actualSex}
      - Kilo: ${actualWeight} kg
      - Boy: ${actualHeight} cm
      - Hedef: ${actualGoal}
      - Fitness Seviyesi: ${actualFitnessLevel}
      - Haftalık Antrenman: ${actualDays} gün
      - Antrenman Yeri: ${actualMode}
      
      ÖNEMLİ KURALLAR:
      1. Kullanıcının hedefine, fitness seviyesine ve antrenman yerine göre kişiselleştir
      2. Gerçek egzersiz isimleri kullan
      3. Her gün farklı kas gruplarına odaklan
      4. Set, tekrar ve dinlenme sürelerini fitness seviyesine göre ayarla
      5. Farklı egzersiz isimleri kullan - hiçbir örnek egzersiz ismi kullanma
      6. Detaylı set/tekrar bilgileri ver
      7. Antrenman yerine göre uygun egzersizler seç (${actualMode})
      
      JSON formatında yanıt ver:
      {
        "goal": "${actualGoal}",
        "user_info": {
          "age": ${actualAge},
          "sex": "${actualSex}",
          "weight_kg": ${actualWeight},
          "height_cm": ${actualHeight},
          "fitness_level": "${actualFitnessLevel}",
          "training_days": ${actualDays},
          "training_location": "${actualMode}"
        },
        "days": ${actualDays},
        "workouts": [
          {
            "day": 1,
            "name": "string",
            "focus": "string",
            "exercises": [
              {
                "name": "string",
                "sets": "number",
                "reps": "string",
                "rest": "string",
                "notes": "string"
              }
            ]
          }
        ]
      }`

  try {
    console.log('=== GEMINI API ÇAĞRISI BAŞLADI ===')
    
    // Gemini API endpoint
    const apiKey = "AIzaSyDBKGbsPR3LRs7dRYqkn4_QXEMmUvv8wE0"
    const geminiEndpoint = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=${apiKey}`
    
    console.log('Gemini endpoint:', geminiEndpoint)
    console.log('Prompt length:', prompt.length)
    console.log('Prompt preview:', prompt.substring(0, 200) + '...')
    
    const response = await fetch(geminiEndpoint, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        contents: [{
          role: 'user',
          parts: [{
            text: prompt
          }]
        }],
        generationConfig: {
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 8192,
        }
      })
    })

    console.log('Response status:', response.status)
    console.log('Response headers:', Object.fromEntries(response.headers.entries()))

    if (!response.ok) {
      const errorText = await response.text()
      console.error('Gemini API error response:', errorText)
      throw new Error(`Gemini API failed: ${response.status} ${response.statusText} - ${errorText}`)
    }

    const data = await response.json()
    console.log('Gemini API response received')
    
    if (data.candidates && data.candidates[0] && data.candidates[0].content) {
      const generatedText = data.candidates[0].content.parts[0].text
      console.log('Generated text length:', generatedText.length)
      console.log('Generated text preview:', generatedText.substring(0, 200) + '...')
      
      try {
        // JSON'u parse et
        const jsonMatch = generatedText.match(/\{[\s\S]*\}/)
        if (!jsonMatch) {
          throw new Error('No JSON found in Gemini response')
        }
        
        const workoutPlan = JSON.parse(jsonMatch[0])
        console.log('✅ Workout plan JSON parsed successfully')
        
        // Debug: Tüm workout planını logla
        console.log('=== GEMINI WORKOUT PLAN DEBUG ===')
        console.log('Full workout plan:', JSON.stringify(workoutPlan, null, 2))
        
        if (workoutPlan.workouts && workoutPlan.workouts.length > 0) {
          console.log('=== WORKOUT KONTROLÜ ===')
          workoutPlan.workouts.forEach((workout: any, index: number) => {
            console.log(`Gün ${workout.day}: ${workout.name} - ${workout.exercises?.length || 0} egzersiz`)
            if (workout.exercises) {
              workout.exercises.forEach((exercise: any, exIndex: number) => {
                console.log(`  ${exIndex + 1}. ${exercise.name} - ${exercise.sets} set x ${exercise.reps} tekrar`)
              })
            }
          })
        }
        
        return new Response(JSON.stringify(workoutPlan), {
          status: 200,
          headers: corsHeaders
        })
      } catch (parseError) {
        console.error('❌ JSON parse error:', parseError)
        console.log('Raw generated text:', generatedText)
        throw new Error(`JSON parse error: ${parseError.message}`)
      }
    } else {
      console.error('❌ Invalid response structure:', data)
      throw new Error('Invalid response structure from Gemini API')
    }
  } catch (error) {
    console.error('=== SUPABASE EDGE FUNCTION HATASI ===')
    console.error('Error type:', typeof error)
    console.error('Error stack:', error.stack)
    console.error('Full error object:', error)
    console.error('Error message:', error.message)
    
    return new Response(JSON.stringify({ 
      error: 'Workout plan generation failed', 
      details: error.message 
    }), {
      status: 500,
      headers: corsHeaders
    })
  }
}