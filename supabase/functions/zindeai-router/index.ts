import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
}

serve(async (req) => {
  // CORS handling
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { requestType, ...data } = await req.json()
    
    let result;
    
    if (data.planType === 'meal') {
      result = await generateMealPlan(data)
    } else if (data.planType === 'workout') {
      result = await generateWorkoutPlan(data)
    } else {
      throw new Error('Invalid plan type')
    }
    
    // KRITIK: Her zaman JSON object döndür
    const response = typeof result === 'string' 
      ? { data: JSON.parse(result) }  // String ise parse et
      : { data: result }               // Zaten object ise wrap et
    
    return new Response(
      JSON.stringify(response),
      { 
        headers: { 
          ...corsHeaders,
          'Content-Type': 'application/json; charset=utf-8'  // Doğru content-type
        },
        status: 200
      }
    )
  } catch (error) {
    // Hata durumunda da JSON döndür
    return new Response(
      JSON.stringify({ 
        error: error.message,
        details: error.toString()
      }),
      { 
        headers: { 
          ...corsHeaders,
          'Content-Type': 'application/json; charset=utf-8'
        },
        status: 500
      }
    )
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
    activity = 'moderately_active',
    wantMuscleGain = false,
    proteinTarget = '112',
    proteinPreference = 'moderate'
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
  console.log('Want Muscle Gain:', wantMuscleGain)
  console.log('Protein Target:', proteinTarget)
  console.log('Protein Preference:', proteinPreference)

  const prompt = `Sen dünyanın en iyi diyetisyenisin! Profesyonel bir beslenme uzmanı olarak ${actualAge} yaşında, ${actualWeight}kg, ${actualHeight}cm boyunda ${actualSex} için ${actualDays} günlük detaylı beslenme planı oluştur.
      
      KİŞİ BİLGİLERİ:
      - Kilo: ${actualWeight} kg
      - Boy: ${actualHeight} cm
      - Yaş: ${actualAge}
      - Cinsiyet: ${actualSex}
      - Hedef: ${actualGoal}
      - Kas Kütlesi Hedefi: ${wantMuscleGain ? 'EVET - KAS KAZANIMI/KORUMA ÖNCELİKLİ' : 'Hayır'}
      
      MAKRO HEDEFLER:
      - Günlük Protein: MİNİMUM ${proteinTarget} gram (${wantMuscleGain ? 'HER ÖĞÜNDE PROTEIN ZORUNLU' : 'dengeli dağıtım'})
      - Protein Kaynakları: Tavuk, balık, yumurta, süt ürünleri, baklagiller
      - Kalori: ${calories || 2000} kcal
      
      ${wantMuscleGain ? `
      ÖNEMLİ: Kas gelişimi için:
      - Sabah yüksek proteinli kahvaltı
      - Antrenman sonrası 30g+ protein
      - Yatmadan önce kazein/yoğurt
      - Her öğünde en az 25-30g protein
      ` : ''}
      
      HER GÜN İÇİN ZORUNLU:
      1. Tam makro değerleri (protein/karb/yağ gram olarak)
      2. Detaylı malzeme listesi (gramajlarıyla)
      3. Hazırlanış tarifi
      4. Öğün zamanlaması önerileri
      
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
        
        return mealPlan
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
    
    throw error
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
      
      ZORUNLU DETAYLAR (HER HAREKET İÇİN):
      1. Set x Tekrar sayısı
      2. Dinlenme süresi (saniye olarak)
      3. Tempo (örn: 2-0-2-0 = 2sn iniş, 0 duraklama, 2sn kalkış, 0 üstte duraklama)
      4. RPE değeri (1-10 zorlanma skalası)
      5. Form ipuçları (en az 2 madde)
      6. Dikkat edilecek noktalar
      7. Yaygın hatalar
      8. Alternatif hareketler
      
      ÖRNEK FORMAT:
      {
        "exercise": "Barbell Bench Press",
        "sets": 4,
        "reps": "8-10",
        "rest": "90-120 saniye",
        "tempo": "2-0-1-0",
        "rpe": 7,
        "formTips": [
          "Omuz küreklerini birbirine yaklaştır ve göğsünü dışarı çıkar",
          "Ayakları yere sağlam bas, kalça kasını sık"
        ],
        "commonMistakes": [
          "Dirseği çok açmak (45 derece açı ideal)",
          "Barı göğse değdirmeden kaldırmak"
        ],
        "alternatives": ["Dumbbell Press", "İncline Press"],
        "targetMuscles": ["Göğüs", "Ön omuz", "Triceps"]
      }
      
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
                "tempo": "string",
                "rpe": "number",
                "formTips": ["string array"],
                "commonMistakes": ["string array"],
                "alternatives": ["string array"],
                "targetMuscles": ["string array"],
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
        
        return workoutPlan
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
    
    throw error
  }
}