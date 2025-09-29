import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
}

// JSON temizleme fonksiyonu
const cleanJsonString = (str: string): string => {
  // Markdown kod bloklarını temizle
  str = str.replace(/```json\s*/gi, '');
  str = str.replace(/```\s*/gi, '');
  
  // JSON'u bul ve çıkar
  const jsonMatch = str.match(/\{[\s\S]*\}/);
  if (!jsonMatch) {
    throw new Error('Valid JSON not found');
  }
  
  return jsonMatch[0];
};

// Güvenli beslenme planı formatı
const createSafeMealPlan = (rawPlan: any) => {
  const safePlan = {
    days: [],
    totalCalories: 0,
    macros: {
      protein: 0,
      carbs: 0,
      fats: 0
    }
  };
  
  // 7 gün için boş plan oluştur
  for (let i = 0; i < 7; i++) {
    safePlan.days.push({
      day: i + 1,
      dayName: ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'][i],
      meals: {
        sabah: null,
        ara_ogun_1: null,
        ogle: null,
        ara_ogun_2: null,
        aksam: null
      },
      totalCalories: 0
    });
  }
  
  // Gerçek veriyi doldur
  if (rawPlan && rawPlan.days && Array.isArray(rawPlan.days)) {
    rawPlan.days.forEach((day, index) => {
      if (index < 7 && day && day.meals) {
        safePlan.days[index].meals = {
          sabah: day.meals.sabah || { name: 'Kahvaltı', calories: 0, ingredients: [] },
          ara_ogun_1: day.meals.ara_ogun_1 || { name: 'Ara Öğün', calories: 0, ingredients: [] },
          ogle: day.meals.ogle || { name: 'Öğle Yemeği', calories: 0, ingredients: [] },
          ara_ogun_2: day.meals.ara_ogun_2 || { name: 'Ara Öğün', calories: 0, ingredients: [] },
          aksam: day.meals.aksam || { name: 'Akşam Yemeği', calories: 0, ingredients: [] }
        };
        safePlan.days[index].totalCalories = day.totalCalories || 0;
      }
    });
  }
  
  safePlan.totalCalories = rawPlan.totalCalories || 0;
  safePlan.macros = rawPlan.macros || safePlan.macros;
  
  return safePlan;
};

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

  const prompt = `Sen uzman bir diyetisyensin. Kullanıcının PROFİL BİLGİLERİNE GÖRE beslenme planı oluştur.

KULLANICI BİLGİLERİ:
      - Yaş: ${actualAge}
      - Cinsiyet: ${actualSex}
      - Kilo: ${actualWeight} kg
      - Boy: ${actualHeight} cm
- Hedef: ${actualGoal}
- Kas Kütlesi Hedefi: ${wantMuscleGain ? 'EVET - KAS KAZANIMI/KORUMA ÖNCELİKLİ' : 'Hayır'}

DİNAMİK MAKRO HESAPLAMA:

1. ÖNCE BMR HESAPLA:
   - Erkek: (10 x kilo) + (6.25 x boy) - (5 x yaş) + 5
   - Kadın: (10 x kilo) + (6.25 x boy) - (5 x yaş) - 161

2. TDEE HESAPLA:
   - Sedanter (egzersiz yok): BMR x 1.2
   - Hafif aktif (haftada 1-3 gün): BMR x 1.375
   - Orta aktif (haftada 3-5 gün): BMR x 1.55
   - Çok aktif (haftada 6-7 gün): BMR x 1.725

3. HEDEFE GÖRE KALORİ AYARLA:
   - "Kilo Verme" + "Kas Kütlesi Koru": TDEE - 300 (az açık, kas kaybını önle)
   - "Kilo Verme" normal: TDEE - 500
   - "Kas Kazanma": TDEE + 400-500
   - "Kilo Alma": TDEE + 500-600
   - "Bakım": TDEE

4. PROTEİN HESAPLA (ÇOK ÖNEMLİ):
   - "Kilo Verme" + kas koruma varsa: kilo x 2.4-2.6 gram (yüksek protein kas korur)
   - "Kilo Verme" normal: kilo x 2.0-2.2 gram
   - "Kas Kazanma": kilo x 2.2-2.5 gram
   - "Kilo Alma": kilo x 2.0-2.2 gram
   - "Bakım": kilo x 1.8-2.0 gram
   
5. YAĞ HESAPLA:
   - Minimum: kilo x 0.8 gram (hormonal sağlık için)
   - Ketojenik diyet ise: toplam kalorinin %70'i yağdan

6. KARBONHİDRAT:
   - Ketojenik: maksimum 30-50 gram
   - Normal: Kalan kaloriyi doldur
   - Antrenman yapıyorsa: kilo x 3-4 gram tercih et

DİYET TİPİNE GÖRE YEMEK SEÇİMİ:

"Dengeli": Her gıda grubundan
"Vejetaryen": Et yok, süt/yumurta var
"Vegan": Hiç hayvansal ürün yok, bitkisel protein kaynakları kullan
"Ketojenik": Yüksek yağ, çok düşük karb (max 30g), orta protein
"Paleo": İşlenmiş gıda yok, tahıl yok, baklagil yok

KULLANICI KOMBİNASYONLARINA ÖRNEKLER:

Örnek 1: 80kg, Kilo Verme + Kas Kütlesi Koru, Dengeli Diyet
- Kalori: TDEE - 300 (kas korumak için az açık)
- Protein: 192-208g (kilo x 2.4-2.6)
- Yağ: 64g (kilo x 0.8)
- Karb: Kalan kalori

Örnek 2: 70kg, Kilo Verme, Ketojenik
- Kalori: TDEE - 500
- Protein: 140g (kilo x 2.0)
- Karb: 30g (keto sınırı)
- Yağ: Kalan tüm kalori (yüksek)

Örnek 3: 65kg, Kas Kazanma, Vegan
- Kalori: TDEE + 500
- Protein: 143-162g (mercimek, nohut, tofu, tempeh, seitan)
- Karb: 260g
- Yağ: 65g

KRİTİK KURALLAR:
1. Kullanıcının KENDİ kilosu, boyu, yaşı, cinsiyeti kullanılacak
2. Diyet tipi mutlaka dikkate alınacak (vegan ise et/süt YOK)
3. 7 gün farklı yemekler olacak
4. Her öğünde ingredients dolu olacak
5. Kilo verme + kas koruma kombinasyonu varsa protein YÜKSEK olacak
      
JSON FORMATI (7 GÜN ZORUNLU):
{
  "plan_name": "[Hedef] + [Diyet Tipi] Beslenme Planı",
  "user_specs": {
    "weight": ${actualWeight},
    "goal": "${actualGoal}",
    "diet_type": "${actualDiet}",
    "muscle_preserve": ${wantMuscleGain}
  },
  "daily_macros": {
    "calories": HESAPLANAN,
    "protein": HESAPLANAN,
    "carbs": HESAPLANAN,
    "fat": HESAPLANAN
  },
  "days": [
    {
      "day": "Pazartesi",
        "meals": [
          {
          "name": "Kahvaltı",
          "time": "08:00",
          "description": "DİYET TİPİNE UYGUN YEMEKLER",
          "calories": XXX,
          "protein": XX,
          "carbs": XX,
          "fat": XX,
          "ingredients": [
            {"name": "...", "amount": "...", "unit": "..."}
          ]
        }
        // EN AZ 5-6 ÖĞÜN OLMALI
      ]
    }
    // 7 GÜN TAMAMLANMALI
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

  const prompt = `${actualDays} günlük ${actualFitnessLevel} seviye antrenman planı oluştur.

ZORUNLU KURALLAR:
1. Her egzersiz için MUTLAKA şu formatı kullan:
   - Set sayısı: Tam sayı (örn: 3)
   - Tekrar: Tam sayı veya aralık (örn: 12 veya 8-10)
   - Dinlenme: Saniye cinsinden tam sayı (örn: 60, 90, 120)
   - RPE: 1-10 arası sayı (örn: 7)
   - Form ipucu: Kısa ve net açıklama

2. Split Dağılımı:
   - 3 gün: Full Body (her gün)
   - 4 gün: Upper/Lower/Upper/Lower
   - 5 gün: Push/Pull/Legs/Upper/Lower
   - 6 gün: Push/Pull/Legs tekrarı

3. JSON formatı:
{
  "trainingPlan": {
    "days": [
      {
        "day": 1,
        "name": "Push Day",
        "exercises": [
          {
            "name": "Bench Press",
            "targetMuscle": "Göğüs",
            "sets": 4,
            "reps": "8-10",
            "rest": 90,
            "rpe": 7,
            "formTip": "Omuzları geriye çek, göğsü dışarı çıkar"
          }
        ]
      }
    ],
    "weeklyVolume": {
      "chest": 12,
      "back": 12,
      "shoulders": 8,
      "legs": 16,
      "arms": 8
    }
  }
}

YASAKLAR:
- "60-90 saniye" gibi belirsiz dinlenme süreleri KULLANMA
- Boş veya null değer bırakma
- Mantıksız kas grubu kombinasyonları yapma

KULLANICI BİLGİLERİ:
- Yaş: ${actualAge}
- Cinsiyet: ${actualSex}
- Kilo: ${actualWeight} kg
- Boy: ${actualHeight} cm
- Hedef: ${actualGoal}
- Fitness Seviyesi: ${actualFitnessLevel}
- Haftalık Antrenman: ${actualDays} gün
- Antrenman Yeri: ${actualMode}

ONAYLANMIŞ EGZERSİZ LİSTESİ:
[GÖĞÜS]
- Barbell Bench Press
- Dumbbell Bench Press
- Incline Dumbbell Press
- Cable Crossover
- Push-up
- Dips

[SIRT]
- Pull-up / Lat Pulldown
- Barbell Row
- Cable Row
- T-Bar Row
- Deadlift
- Face Pull

[OMUZ]
- Military Press
- Dumbbell Shoulder Press
- Lateral Raise
- Rear Delt Fly
- Arnold Press
- Upright Row

[BACAK]
- Squat
- Front Squat
- Leg Press
- Romanian Deadlift
- Leg Curl
- Leg Extension
- Walking Lunge
- Calf Raise

[KOL]
- Barbell Curl
- Hammer Curl
- Cable Curl
- Close Grip Bench Press
- Cable Pushdown
- Overhead Extension

[CORE]
- Plank
- Russian Twist
- Leg Raise
- Cable Crunch
- Ab Wheel
      
JSON FORMATI - MUTLAKA BU FORMATTA DÖN:
{
  "plan_name": "Kişiye Özel ${actualDays} Günlük Programı",
  "weekly_schedule": {
    "monday": "Push (Göğüs, Omuz, Triceps)",
    "tuesday": "Pull (Sırt, Biceps)",
    "wednesday": "Legs (Bacak, Kalça)",
    "thursday": "Upper Body",
    "friday": "Lower Body",
    "saturday": "Dinlenme veya Aktif Toparlanma",
    "sunday": "Dinlenme"
  },
          "workouts": [
            {
      "day": "Pazartesi - Push Günü",
      "focus": "Göğüs, Omuz, Triceps",
      "warmup": [
        "5 dakika hafif kardiyo",
        "Dinamik germe - 10 omuz çevirme",
        "2x15 şınav (ısınma)"
      ],
              "exercises": [
                {
          "name": "Barbell Bench Press",
          "sets": "4 set",
          "reps": "6-8 tekrar",
          "rest": "180 saniye",
          "rpe": "RPE 8",
          "form_tips": [
            "Omuz kemiklerini sıkıştır ve göğsünü dışarı çıkar",
            "Barı göğsüne kontrollü indir, patlayıcı kaldır",
            "Ayakların yerde sabit kalsın"
          ],
          "notes": "Ana compound hareket, ağır git"
        }
      ],
      "cooldown": [
        "5 dakika hafif yürüyüş",
        "Göğüs ve omuz stretching - her bölge 30 saniye"
      ]
    }
  ],
  "progression_notes": [
    "Her hafta ağırlıkları %2.5-5 artırmaya çalış",
    "RPE 10'a ulaştığında deload haftası al",
    "Form bozulmaya başlarsa ağırlığı düşür"
  ],
  "recovery_tips": [
    "Günde en az 7-8 saat uyku",
    "Her antrenman sonrası protein alımı",
    "Haftada 2-3 gün aktif dinlenme"
  ]
}

ÖNEMLİ NOTLAR:
1. Dinlenme süreleri MUTLAKA tam sayı olmalı (60, 90, 120, 180 saniye)
2. Her egzersiz için form_tips en az 2-3 madde içermeli
3. Split mantığı kullanıcının gün sayısına uygun olmalı
4. Başlangıç seviyesi için RPE 6-7, ileri seviye için RPE 8-9
5. Sadece onaylı egzersiz listesinden seç`

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
        // JSON'u temizle ve parse et
        const cleanedJson = cleanJsonString(generatedText)
        const workoutPlan = JSON.parse(cleanedJson)
        
        // Güvenli format kontrolü
        if (!workoutPlan.trainingPlan || !workoutPlan.trainingPlan.days) {
          throw new Error('Invalid workout plan structure')
        }
        
        console.log('✅ Workout plan JSON parsed successfully')
        
        // Debug: Tüm workout planını logla
        console.log('=== GEMINI WORKOUT PLAN DEBUG ===')
        console.log('Full workout plan:', JSON.stringify(workoutPlan, null, 2))
        
        if (workoutPlan.trainingPlan.days && workoutPlan.trainingPlan.days.length > 0) {
          console.log('=== WORKOUT KONTROLÜ ===')
          workoutPlan.trainingPlan.days.forEach((day: any, index: number) => {
            console.log(`Gün ${day.day}: ${day.name} - ${day.exercises?.length || 0} egzersiz`)
            if (day.exercises) {
              day.exercises.forEach((exercise: any, exIndex: number) => {
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