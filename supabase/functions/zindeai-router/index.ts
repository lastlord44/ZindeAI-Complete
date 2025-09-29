import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
  
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
}

// Vertex AI Configuration
const PROJECT_ID = 'august-journey-473119-t2'
const LOCATION = 'us-central1'
const MODEL_ID = 'gemini-2.0-flash'

// Service Account Key - Load from environment variables
const SERVICE_ACCOUNT_KEY = {
  "type": "service_account",
  "project_id": Deno.env.get("GOOGLE_PROJECT_ID") || "august-journey-473119-t2",
  "private_key_id": Deno.env.get("GOOGLE_PRIVATE_KEY_ID") || "",
  "private_key": Deno.env.get("GOOGLE_PRIVATE_KEY") || "",
  "client_email": Deno.env.get("GOOGLE_CLIENT_EMAIL") || "",
  "client_id": Deno.env.get("GOOGLE_CLIENT_ID") || "",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": `https://www.googleapis.com/robot/v1/metadata/x509/${Deno.env.get("GOOGLE_CLIENT_EMAIL") || ""}`,
  "universe_domain": "googleapis.com"
}

// JWT token oluşturma fonksiyonu
async function createJWT() {
  console.log('=== JWT TOKEN OLUŞTURMA BAŞLADI ===')
  const header = {
    "alg": "RS256",
    "typ": "JWT"
  }
  
  const now = Math.floor(Date.now() / 1000)
  const payload = {
    "iss": SERVICE_ACCOUNT_KEY.client_email,
    "scope": "https://www.googleapis.com/auth/cloud-platform",
    "aud": "https://oauth2.googleapis.com/token",
    "iat": now,
    "exp": now + 3600
  }
  
  const headerB64 = btoa(JSON.stringify(header))
  const payloadB64 = btoa(JSON.stringify(payload))
  const signatureInput = `${headerB64}.${payloadB64}`
  
  console.log('JWT signing başlıyor...')
  
  // Private key'i temizle ve parse et
  const privateKeyPem = SERVICE_ACCOUNT_KEY.private_key
    .replace(/-----BEGIN PRIVATE KEY-----/g, '')
    .replace(/-----END PRIVATE KEY-----/g, '')
    .replace(/\\n/g, '\n')
    .replace(/\n/g, '')
    .trim()
  
  console.log('Private key pem length:', privateKeyPem.length)
  const privateKeyDer = Uint8Array.from(atob(privateKeyPem), c => c.charCodeAt(0))
  
  const key = await crypto.subtle.importKey(
    "pkcs8",
    privateKeyDer,
    {
      name: "RSASSA-PKCS1-v1_5",
      hash: "SHA-256"
    },
    false,
    ["sign"]
  )
  
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(signatureInput)
  )
  
  const signatureB64 = btoa(String.fromCharCode(...new Uint8Array(signature)))
  
  console.log('JWT token oluşturuldu başarıyla')
  return `${signatureInput}.${signatureB64}`
}

async function getAccessToken() {
  try {
    console.log('=== ACCESS TOKEN ALMA BAŞLADI ===')
    const jwt = await createJWT()
    
    const response = await fetch("https://oauth2.googleapis.com/token", {
      method: "POST",
        headers: {
        "Content-Type": "application/x-www-form-urlencoded"
      },
      body: new URLSearchParams({
        "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
        "assertion": jwt
      })
    })
    
    if (!response.ok) {
      const errorText = await response.text()
      console.error(`Token request failed: ${response.status} - ${errorText}`)
      throw new Error(`Token request failed: ${response.status}`)
    }
    
    const data = await response.json()
    console.log('Access token başarıyla alındı')
    return data.access_token
  } catch (error) {
    console.error('Token generation error:', error)
    throw error
  }
}

serve(async (req) => {
  console.log('=== SUPABASE EDGE FUNCTION BAŞLADI ===')
  console.log('Request method:', req.method)
  console.log('Request URL:', req.url)
  console.log('Request headers:', Object.fromEntries(req.headers.entries()))
  
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    console.log('CORS preflight request handled')
    return new Response('ok', { headers: corsHeaders })
  }

  // Auth kontrolü - sadece log için
  const authHeader = req.headers.get('authorization')
  const apikeyHeader = req.headers.get('apikey')
  console.log('Auth header:', authHeader)
  console.log('API key header:', apikeyHeader)
  console.log('✅ Edge Function çalışıyor - auth kontrolü atlandı')

  try {
    console.log('Request body parsing başlıyor...')
    const body = await req.json()
    console.log('Raw request body:', JSON.stringify(body, null, 2))
    
    const { planType, ...params } = body
    
    console.log('Received request:', { planType, params })

    if (planType === 'meal') {
      console.log('=== MEAL PLAN OLUŞTURMA BAŞLADI ===')
      const mealPlan = await generateMealPlan(params)
      console.log('=== MEAL PLAN OLUŞTURULDU ===')
      console.log('Meal plan response:', JSON.stringify(mealPlan, null, 2))
      return new Response(
        JSON.stringify({ success: true, data: mealPlan }),
        { 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 200 
        }
      )
    } else if (planType === 'workout') {
      console.log('=== WORKOUT PLAN OLUŞTURMA BAŞLADI ===')
      const workoutPlan = await generateWorkoutPlan(params)
      console.log('=== WORKOUT PLAN OLUŞTURULDU ===')
      console.log('Workout plan response:', JSON.stringify(workoutPlan, null, 2))
      return new Response(
        JSON.stringify({ success: true, data: workoutPlan }),
        { 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 200 
        }
      )
    } else {
      console.log('=== HATA: GEÇERSİZ PLAN TİPİ ===')
      console.log('Plan type:', planType)
      return new Response(
        JSON.stringify({ success: false, error: 'Invalid plan type' }),
        { 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 400 
        }
      )
    }
  } catch (error) {
    console.error('=== SUPABASE EDGE FUNCTION HATASI ===')
    console.error('Error type:', typeof error)
    console.error('Error message:', error.message)
    console.error('Error stack:', error.stack)
    console.error('Full error object:', JSON.stringify(error, null, 2))
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500 
      }
    )
  }
})

async function generateMealPlan(params: any) {
  console.log('=== GENERATE MEAL PLAN FONKSİYONU BAŞLADI ===')
  console.log('Input params:', JSON.stringify(params, null, 2))
  
  const {
    age = 25,
    sex = 'erkek',
    weight = 70,
    height = 175,
    activity = 'orta',
    diet = 'balanced',
    goal = 'maintain',
    days = 7,
    calories = 2000
  } = params

  const actualAge = parseInt(age) || 25
  const actualWeight = parseInt(weight) || 70
  const actualHeight = parseInt(height) || 175
  const actualSex = sex || 'erkek'
  const actualActivity = activity || 'orta'
  const actualDiet = diet || 'balanced'
  const actualDays = parseInt(days) || 7
  
  console.log('Parsed values:', {
    actualAge, actualWeight, actualHeight, actualSex, 
    actualActivity, actualDiet, actualDays
  })

  const prompt = `Sen dünyanın en iyi diyetisyenisin! Profesyonel bir beslenme uzmanı olarak ${actualAge} yaşında, ${actualWeight}kg, ${actualHeight}cm boyunda ${actualSex} için ${actualDays} günlük detaylı beslenme planı oluştur.
      
      KULLANICI PROFİLİ:
      - Yaş: ${actualAge}
      - Cinsiyet: ${actualSex}
      - Kilo: ${actualWeight} kg
      - Boy: ${actualHeight} cm
      - Hedef: ${goal}
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
      
      JSON formatında yanıt ver:
      {
        "goal": "${goal}",
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
              "recipe": "DETAYLI TARİF: Malzemeler (gramajlar), pişirme yöntemi, süre"
            },
            "snack1": {
              "name": "string",
              "calories": "number",
              "protein": "number",
              "carbs": "number",
              "fat": "number",
              "foods": ["string array"],
              "recipe": "DETAYLI TARİF: Malzemeler (gramajlar), pişirme yöntemi, süre"
            },
            "lunch": {
              "name": "string",
              "calories": "number",
              "protein": "number",
              "carbs": "number",
              "fat": "number",
              "foods": ["string array"],
              "recipe": "DETAYLI TARİF: Malzemeler (gramajlar), pişirme yöntemi, süre"
            },
            "snack2": {
              "name": "string",
              "calories": "number",
              "protein": "number",
              "carbs": "number",
              "fat": "number",
              "foods": ["string array"],
              "recipe": "DETAYLI TARİF: Malzemeler (gramajlar), pişirme yöntemi, süre"
            },
            "dinner": {
              "name": "string",
              "calories": "number",
              "protein": "number",
              "carbs": "number",
              "fat": "number",
              "foods": ["string array"],
              "recipe": "DETAYLI TARİF: Malzemeler (gramajlar), pişirme yöntemi, süre"
            }
          }
        ]
      }
      
      ÖNEMLİ: 
      - Sadece JSON formatında yanıt ver, başka açıklama yapma!
      - Her gün için TAMAMEN FARKLI yemek isimleri ve detaylı besin listesi ver!
      - ${actualDays} gün için farklı protein kaynakları kullan (balık, tavuk, et, hindi, yumurta, peynir vb.)
      - Her gün farklı sebze, meyve ve tahıl kombinasyonları kullan!
      - 5 öğün mutlaka olsun: breakfast, snack1, lunch, snack2, dinner
      - Kullanıcının hedefi, yaşı, cinsiyeti ve aktivite seviyesine göre kişiselleştir!
      - Günlük ${calories || 2000} kalori hedefine uygun porsiyonlar ver!
      - TÜRK MUTFAĞI yemekleri öner (örn: "Mercimek Çorbası", "Karnıyarık", "İmam Bayıldı", "Köfte", "Pilav", "Bulgur Pilavı", "Kuru Fasulye", "Nohut", "Bakla", "Bamya", "Patlıcan Musakka", "Karnabahar Kızartması", "Mantı", "Lahmacun", "Pide", "Börek", "Gözleme", "Menemen", "Kavurma", "Sarma", "Dolma", "Çiğ Köfte", "Kısır", "Bulgur Pilavı", "Pirinç Pilavı", "Makarna")!
      - Her yemek için DETAYLI TARİF ekle: malzemeler, gramajlar, pişirme yöntemi, süre!
      - Örnek: "200g tavuk göğsü haşla, 1 su bardağı mercimek kaynat, 1 yemek kaşığı zeytinyağı ekle"!
      - Kullanıcı tam olarak ne yapacağını bilsin!`

  try {
    console.log('=== VERTEX AI ÇAĞRISI BAŞLADI ===')
    // Vertex AI endpoint
    const vertexAIEndpoint = `https://${LOCATION}-aiplatform.googleapis.com/v1/projects/${PROJECT_ID}/locations/${LOCATION}/publishers/google/models/${MODEL_ID}:generateContent`
    
    console.log('Vertex AI endpoint:', vertexAIEndpoint)
    console.log('Prompt length:', prompt.length)
    console.log('Prompt preview:', prompt.substring(0, 200) + '...')
    
    const accessToken = await getAccessToken();
    console.log('Access token generated:', !!accessToken);
    console.log('Access token length:', accessToken?.length);
    
    const response = await fetch(vertexAIEndpoint, {
        method: 'POST',
        headers: {
        'Authorization': `Bearer ${accessToken}`,
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

    console.log('Response status:', response.status);
    console.log('Response headers:', Object.fromEntries(response.headers.entries()));

    if (!response.ok) {
      const errorText = await response.text();
      console.error('Vertex AI error response:', errorText);
      throw new Error(`Vertex AI API failed: ${response.status} ${response.statusText} - ${errorText}`)
    }

    const data = await response.json()
    console.log('Vertex AI response data:', JSON.stringify(data, null, 2));
    
    const geminiText = data.candidates[0].content.parts[0].text
    
    console.log('Vertex AI raw response:', geminiText)
    
    // JSON'u parse et
    const jsonMatch = geminiText.match(/\{[\s\S]*\}/)
    if (!jsonMatch) {
      throw new Error('No JSON found in Vertex AI response')
    }
    
    const parsedData = JSON.parse(jsonMatch[0])
    console.log('Parsed Vertex AI data:', JSON.stringify(parsedData, null, 2))
    
    // Her günün öğün sayısını kontrol et
    if (parsedData.meals && parsedData.meals.length > 0) {
      console.log('=== ÖĞÜN KONTROLÜ ===')
      parsedData.meals.forEach((day: any, index: number) => {
        const mealKeys = Object.keys(day).filter(key => key !== 'day')
        console.log(`Gün ${day.day}: ${mealKeys.length} öğün - ${mealKeys.join(', ')}`)
      })
    }
    
    return parsedData
  } catch (error) {
    console.error('Vertex AI Error:', error)
    throw new Error(`Vertex AI failed: ${error.message}`)
  }
}

async function generateWorkoutPlan(params: any) {
  const {
    age = 25,
    gender = 'erkek',
    weight = 70,
    height = 175,
    activity = 'orta',
    goal = 'maintain',
    daysPerWeek = 3,
    mode = 'gym',
    preferredSplit = 'Full Body'
  } = params

  const fitnessLevel = getFitnessLevel(activity)
  const userId = 'user_' + Date.now()

  const prompt = `Sen dünyanın en iyi antrenman koçusun! Profesyonel bir antrenman programı hazırla.
      
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

JSON formatında yanıt ver:
        {
          "userId": "${userId}",
          "weekNumber": 1,
          "splitType": "string",
          "mode": "${params.mode}",
          "fitnessLevel": "${fitnessLevel}",
          "daysPerWeek": ${daysPerWeek},
          "goal": "${goal}",
          "preferredSplit": "${preferredSplit}",
          "workouts": [
            {
              "day": 1,
              "type": "string",
              "focus": "string",
              "exercises": [
                {
                  "name": "string",
                  "sets": "number",
                  "reps": "string",
                  "rest": "string"
                }
              ],
              "duration": "string",
              "difficulty": "${fitnessLevel}"
            }
          ]
        }
        
        ÖNEMLİ: 
        - Sadece JSON formatında yanıt ver, başka açıklama yapma!
        - ${daysPerWeek} gün için farklı egzersiz isimleri ve detaylı set/tekrar bilgileri ver!
        - Kullanıcının hedefi (${goal}), fitness seviyesi (${fitnessLevel}) ve antrenman yeri (${params.mode}) göre kişiselleştir!
        - Gerçek egzersiz isimleri kullan (örn: "Bench Press", "Squat", "Deadlift", "Pull-ups")!
        - Her gün farklı kas gruplarına odaklan!
        - Set, tekrar ve dinlenme sürelerini fitness seviyesine göre ayarla!`

  try {
    console.log('=== VERTEX AI WORKOUT ÇAĞRISI BAŞLADI ===')
    // Vertex AI endpoint
    const vertexAIEndpoint = `https://${LOCATION}-aiplatform.googleapis.com/v1/projects/${PROJECT_ID}/locations/${LOCATION}/publishers/google/models/${MODEL_ID}:generateContent`
    
    const accessToken = await getAccessToken();
    console.log('Access token generated:', !!accessToken);
    console.log('Vertex AI endpoint:', vertexAIEndpoint);
    
    const response = await fetch(vertexAIEndpoint, {
        method: 'POST',
        headers: {
        'Authorization': `Bearer ${accessToken}`,
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

    console.log('Response status:', response.status);
    console.log('Response headers:', Object.fromEntries(response.headers.entries()));

    if (!response.ok) {
      const errorText = await response.text();
      console.error('Vertex AI error response:', errorText);
      throw new Error(`Vertex AI API failed: ${response.status} ${response.statusText} - ${errorText}`)
    }

    const data = await response.json()
    console.log('Vertex AI response data:', JSON.stringify(data, null, 2));
    
    const geminiText = data.candidates[0].content.parts[0].text
    
    console.log('Vertex AI raw workout response:', geminiText)
    
    // JSON'u parse et
    const jsonMatch = geminiText.match(/\{[\s\S]*\}/)
    if (!jsonMatch) {
      throw new Error('No JSON found in Vertex AI response')
    }
    
    const parsedData = JSON.parse(jsonMatch[0])
    console.log('Parsed Vertex AI workout data:', JSON.stringify(parsedData, null, 2))
    
    return parsedData
  } catch (error) {
    console.error('Vertex AI Workout Error:', error)
    throw new Error(`Vertex AI failed: ${error.message}`)
  }
}

function getFitnessLevel(activity: string): string {
  switch (activity) {
    case 'sedanter': return 'Başlangıç'
    case 'hafif': return 'Başlangıç'
    case 'orta': return 'Orta'
    case 'aktif': return 'İleri'
    case 'çok_aktif': return 'İleri'
    default: return 'Orta'
  }
}