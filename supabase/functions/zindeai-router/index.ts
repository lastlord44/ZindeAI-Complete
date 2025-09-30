import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { GoogleGenerativeAI } from "https://esm.sh/@google/generative-ai@0.21.0"
  
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    console.log('Request received:', req.method, req.url)
    
    // Test endpoint
    if (req.url.includes('test')) {
      return new Response(
        JSON.stringify({ 
          success: true, 
          message: 'Edge Function çalışıyor!',
          timestamp: new Date().toISOString()
        }),
        { 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }
    
    const { requestType, data } = await req.json()
    console.log('Request data:', { requestType, data })
    
    const apiKey = Deno.env.get('GEMINI_API_KEY')
    console.log('API Key exists:', !!apiKey)
    
    if (!apiKey) {
      throw new Error('GEMINI_API_KEY not found')
    }
    
    const genAI = new GoogleGenerativeAI(apiKey)
    const model = genAI.getGenerativeModel({ 
      model: "gemini-2.0-flash-exp",
      generationConfig: {
        temperature: 0.7,
        topP: 0.95,
        topK: 40,
        maxOutputTokens: 8192
      }
    })
    
    if (requestType === 'plan') {
      // PROMPT 7 - Beslenme Planı (Frontend uyumlu JSON şeması, sadece TR ve sadece JSON)
      const prompt = `
Sadece Türkçe konuşan, deneyimli bir diyetisyensin. Yanıtını KESİNLİKLE SADECE JSON olarak ver.

Kullanıcı profili:
${JSON.stringify(data, null, 2)}

Kurallar:
- 7 günün tamamını doldur, her gün FARKLI yemekler yaz
- Günlük kalori ve makrolar matematiksel olarak tutarlı olsun
- Değerlerin hepsi tam sayı (integer) olsun
- Yemek adları Türkçe, malzemeler ulaşılabilir ve gerçekçi olsun
- Malzemelerde miktarları sayı+birim şeklinde yaz (örn: "120 g", "1 adet")
- Sadece JSON döndür; açıklama, kod bloğu veya ek metin yazma
- SAĞLIKLI BESLENME: Sütlaç, pizza, hamburger, patates kızartması, şekerli içecekler, işlenmiş gıdalar, fast food gibi sağlıksız yiyecekleri ASLA önerme
- Yüksek protein içerikli, besleyici ve doğal gıdalar tercih et

JSON Şeması (frontend beklenen yapı):
{
  "days": [
    {
      "day": 1,
      "dayName": "Pazartesi",
      "meals": {
        "sabah": { "name": "...", "calories": 0, "protein": 0, "carbs": 0, "fats": 0, "ingredients": [{"name": "...", "amount": "120 g"}] },
        "ara_ogun_1": { "name": "...", "calories": 0, "protein": 0, "carbs": 0, "fats": 0, "ingredients": [{"name": "...", "amount": "..."}] },
        "ogle": { "name": "...", "calories": 0, "protein": 0, "carbs": 0, "fats": 0, "ingredients": [{"name": "...", "amount": "..."}] },
        "ara_ogun_2": { "name": "...", "calories": 0, "protein": 0, "carbs": 0, "fats": 0, "ingredients": [{"name": "...", "amount": "..."}] },
        "aksam": { "name": "...", "calories": 0, "protein": 0, "carbs": 0, "fats": 0, "ingredients": [{"name": "...", "amount": "..."}] }
      },
      "totalCalories": 0,
      "macros": { "protein": 0, "carbs": 0, "fats": 0 }
    }
  ],
  "totalCalories": 0,
  "macros": { "protein": 0, "carbs": 0, "fats": 0 },
  "nutritionTips": ["...", "..."]
}

Önemli notlar:
- Gün sayısı 7 olacak
- Malzeme miktarlarını birimli ver (ör: "200 g", "1 su bardağı", "2 dilim")
- Günlük protein: vücut ağırlığı x 1.8–2.2 g aralığında olmalı (hedefe göre üst banda yakın)
- JSON dışında hiçbir şey yazma.`;

      const result = await model.generateContent(prompt);

      const response = await result.response;
      const text = response.text();
      
      // JSON parse kontrolü
      try {
        const plan = JSON.parse(text);
        return new Response(
          JSON.stringify({ success: true, plan }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      } catch (parseError) {
        // Text içinden JSON'u çıkarmayı dene
        const jsonMatch = text.match(/\{[\s\S]*\}/);
        if (jsonMatch) {
          const plan = JSON.parse(jsonMatch[0]);
          return new Response(
            JSON.stringify({ success: true, plan }),
            { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
          );
        }
        throw new Error('JSON parse hatası');
      }
      
    } else if (requestType === 'antrenman') {
      // PROMPT 7 - Antrenman Planı (Frontend uyumlu JSON şeması, sadece TR ve sadece JSON)
      const prompt = `
Sadece Türkçe konuşan, deneyimli bir antrenörsün. Yanıtını KESİNLİKLE SADECE JSON olarak ver.

Kullanıcı Profili:
${JSON.stringify(data, null, 2)}

Kurallar:
- Split seçimini gün sayısına göre otomatik belirle (3: Full Body, 4: Upper/Lower, 5+: PPL vb.)
- Her güne 5-6 egzersiz yaz; compound önce, izolasyon sonra
- Dinlenme süresi sadece 60/90/120/180 saniye (tam sayı)
- RPE 5-8 aralığında, tempo "2-0-2-0" gibi
- Sadece JSON döndür; açıklama yazma

JSON Şeması:
{
  "trainingPlan": {
    "programName": "...",
    "level": "beginner|intermediate|advanced",
    "duration": "8 hafta",
    "frequency": 3,
    "split": "Full Body|Upper/Lower|PPL",
    "weeklyVolume": {"chest": 0, "back": 0, "shoulders": 0, "legs": 0, "arms": 0},
    "days": [
      {
        "day": 1,
        "name": "Full Body A",
        "focus": "Tüm vücut",
        "warmup": "5 dakika hafif kardiyo ve dinamik esneme",
        "exercises": [
          {"name": "Squat", "targetMuscle": "Bacaklar", "sets": 3, "reps": "8-10", "rest": 90, "rpe": 6, "tempo": "2-0-2-0", "formTip": "Sırtını düz tut", "notes": ""}
        ],
        "cooldown": "5 dk statik esneme"
      }
    ],
    "progressionTips": ["Her hafta ağırlığı %2.5 artır"]
  }
}`;

      const result = await model.generateContent(prompt);

      const response = await result.response;
      const text = response.text();
      
      // JSON parse kontrolü
      try {
        const antrenman = JSON.parse(text);
        return new Response(
          JSON.stringify({ success: true, antrenman }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      } catch (parseError) {
        // Text içinden JSON'u çıkarmayı dene
        const jsonMatch = text.match(/\{[\s\S]*\}/);
        if (jsonMatch) {
          const antrenman = JSON.parse(jsonMatch[0]);
          return new Response(
            JSON.stringify({ success: true, antrenman }),
            { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
          );
        }
        throw new Error('JSON parse hatası');
      }
    }
    
  } catch (error) {
    console.error('Hata:', error)
    console.error('Error stack:', error.stack)
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: error.message,
        stack: error.stack
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500 
      }
    )
  }
})