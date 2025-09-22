import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { corsHeaders } from '../_shared/cors.ts'

// ONAYLI EGZERSİZ VERİTABANI (Kendi GIF'lerine göre bu listeyi genişlet)
const EXERCISE_DATABASE = [
    { exerciseId: 'barbell_bench_press', name: 'Barbell Bench Press', equipment: ['barbell', 'bench'] },
    { exerciseId: 'dumbbell_bench_press', name: 'Dumbbell Bench Press', equipment: ['dumbbell', 'bench'] },
    { exerciseId: 'incline_dumbbell_press', name: 'Incline Dumbbell Press', equipment: ['dumbbell', 'bench'] },
    { exerciseId: 'push_up', name: 'Push-up', equipment: ['bodyweight'] },
    { exerciseId: 'dips', name: 'Triceps Dips', equipment: ['bodyweight', 'parallel_bars'] },
    { exerciseId: 'triceps_pushdown', name: 'Triceps Pushdown', equipment: ['cable'] },
    { exerciseId: 'overhead_press', name: 'Overhead Press', equipment: ['barbell', 'dumbbell'] },
    { exerciseId: 'lateral_raise', name: 'Lateral Raise', equipment: ['dumbbell'] },
    { exerciseId: 'barbell_squat', name: 'Barbell Squat', equipment: ['barbell', 'rack'] },
    { exerciseId: 'goblet_squat', name: 'Goblet Squat', equipment: ['dumbbell', 'kettlebell'] },
    { exerciseId: 'leg_press', name: 'Leg Press', equipment: ['machine'] },
    { exerciseId: 'romanian_deadlift', name: 'Romanian Deadlift', equipment: ['barbell', 'dumbbell'] },
    { exerciseId: 'leg_curl', name: 'Leg Curl', equipment: ['machine'] },
    { exerciseId: 'lunges', name: 'Lunges', equipment: ['bodyweight', 'dumbbell'] },
    { exerciseId: 'pull_up', name: 'Pull-up', equipment: ['pullup_bar'] },
    { exerciseId: 'barbell_row', name: 'Barbell Row', equipment: ['barbell'] },
    { exerciseId: 'dumbbell_row', name: 'Dumbbell Row', equipment: ['dumbbell', 'bench'] },
    { exerciseId: 'lat_pulldown', name: 'Lat Pulldown', equipment: ['cable', 'machine'] },
    { exerciseId: 'biceps_curl', name: 'Biceps Curl', equipment: ['dumbbell', 'barbell'] },
    { exerciseId: 'plank', name: 'Plank', equipment: ['bodyweight'] },
    { exerciseId: 'crunches', name: 'Crunches', equipment: ['bodyweight'] },
    { exerciseId: 'treadmill_run', name: 'Treadmill Run', equipment: ['machine'] },
];

// JSON Temizleme fonksiyonu - ULTRA AGGRESSIVE
function cleanAndParseJson(text: string) {
  try {
    console.log('Raw AI response:', text.substring(0, 500) + '...');
    
    // Markdown code block'larından JSON'ı çıkar
    let jsonString = text;
    if (text.includes('```json')) {
      const start = text.indexOf('```json') + 7;
      const end = text.indexOf('```', start);
      jsonString = text.substring(start, end).trim();
    } else if (text.includes('```')) {
      const start = text.indexOf('```') + 3;
      const end = text.indexOf('```', start);
      jsonString = text.substring(start, end).trim();
    }
    
    // Tek satırlık (//) ve çok satırlık (/* ... */) yorumları temizle
    const withoutComments = jsonString.replace(/\/\*[\s\S]*?\*\/|\/\/.*$/gm, '').trim();
    
    // JSON5'e benzer şekilde sondaki virgülleri temizle
    const withoutTrailingCommas = withoutComments.replace(/,\s*([\]}])/g, '$1');
    
    // Çoklu boşlukları tek boşluğa çevir
    const cleaned = withoutTrailingCommas.replace(/\s+/g, ' ');
    
    // ULTRA AGGRESSIVE: JSON'ı kes ve sadece geçerli kısmını al
    let fixedJson = cleaned;
    
    // İlk { ile başlayan ve son } ile biten kısmı bul
    const firstBrace = fixedJson.indexOf('{');
    const lastBrace = fixedJson.lastIndexOf('}');
    
    if (firstBrace !== -1 && lastBrace !== -1 && lastBrace > firstBrace) {
      fixedJson = fixedJson.substring(firstBrace, lastBrace + 1);
    }
    
    // Eksik kapanış parantezlerini ekle
    const openBraces = (fixedJson.match(/\{/g) || []).length;
    const closeBraces = (fixedJson.match(/\}/g) || []).length;
    const openBrackets = (fixedJson.match(/\[/g) || []).length;
    const closeBrackets = (fixedJson.match(/\]/g) || []).length;
    
    // Eksik kapanış parantezlerini ekle
    for (let i = 0; i < openBraces - closeBraces; i++) {
      fixedJson += '}';
    }
    for (let i = 0; i < openBrackets - closeBrackets; i++) {
      fixedJson += ']';
    }
    
    // Son çare: JSON'ı truncate et
    if (fixedJson.length > 10000) {
      fixedJson = fixedJson.substring(0, 10000);
      // Son geçerli } veya ] bul ve orada kes
      const lastValidClose = Math.max(fixedJson.lastIndexOf('}'), fixedJson.lastIndexOf(']'));
      if (lastValidClose !== -1) {
        fixedJson = fixedJson.substring(0, lastValidClose + 1);
      }
    }
    
    console.log('Cleaned JSON:', fixedJson.substring(0, 200) + '...');
    
    return JSON.parse(fixedJson);
  } catch (error) {
    console.error("JSON Temizleme ve Parse Etme Hatası:", error);
    console.error("Raw text:", text);
    
    // Son çare: Boş bir plan döndür
    console.log("Son çare: Boş plan döndürülüyor");
    return {
      planTitle: "Plan Oluşturulamadı",
      summary: "AI'dan geçersiz yanıt alındı. Lütfen tekrar deneyin.",
      dailyPlan: []
    };
  }
}

// ULTRA-DETAYLI PROMPT OLUŞTURUCU - PROFESYONEL KALİTE İÇİN
function createPrompt(type: string, params: any): string {
  if (type === 'meal-plan') {
    const { calories, goal, diet, daysPerWeek = 7, preferences } = params;
    const preferencesStr = preferences ?
      Object.entries(preferences)
        .filter(([_, value]) => value === true)
        .map(([key, _]) => key)
        .join(', ') : 'yok';

    return `
      Sen, danışanlarına en ince ayrıntısına kadar planlar sunan, bilimsel verilerle çalışan bir Türk uzman diyetisyensin.
      Sadece ve sadece aşağıda belirtilen şemaya uygun, TEK BİR JSON objesi döndür. Asla yorum satırı veya açıklama ekleme.

      KULLANICI HEDEFİ: Yaklaşık ${calories} kalori, Amaç: ${goal === 'lose' ? 'kilo verme' : goal === 'gain' ? 'kilo alma' : 'kilo koruma'}

      İSTENEN JSON ŞEMASI:
      {
        "planTitle": "string",
        "summary": "string",
        "dailyPlan": [
          ${Array.from({length: daysPerWeek}, (_, i) => `
          {
            "day": "string", // "Pazartesi", "Salı" vb.
            "meals": [
              {
                "mealName": "string", // "Kahvaltı", "Öğle Yemeği"
                "items": [
                  {
                    "itemName": "string", // "Yulaf Ezmesi", "Laktozsuz Süt", "Çiğ Badem"
                    "quantity": "int", // 80, 200, 15
                    "unit": "string", // "gram", "ml", "adet"
                    "calories": "int",
                    "protein": "int",
                    "carbs": "int",
                    "fat": "int"
                  }
                ]
              }
            ]
          }`).join(',')}
        ]
      }

      KURALLAR (BUNLARA UYMAK ZORUNDASIN):
      1. KURAL 1 (EN ÖNEMLİ): Öğünleri 'Tavuklu Pilav' gibi genel yemek isimleriyle VERME. Bir öğünü, onu oluşturan BÜTÜN HAM MALZEMELERİN ('150g Tavuk Göğsü (Çiğ)', '100g Pirinç (Pişmemiş)', '5g Zeytinyağı' gibi) bir listesi olarak oluştur. HER BİR MALZEMENİN kendi kalori ve makro değerleri olmalı.
      2. KURAL 2: Haftanın ${daysPerWeek} GÜNÜ için de plan oluştur. Asla eksik gün bırakma.
      3. KURAL 3: Tüm sayısal değerler (kalori, makro, miktar) TAM SAYI (integer) olmalıdır.
      4. KURAL 4: Plan, Türk mutfağında kolayca bulunabilecek temel ve sağlıklı malzemelerden oluşsun.
      5. KURAL 5: Her gün için 4 öğün: Kahvaltı, Öğle Yemeği, Akşam Yemeği, Ara Öğün
      6. KURAL 6: Makro dağılımı: Protein %25-30, Karbonhidrat %45-50, Yağ %20-25
    `;
  }

  if (type === 'workout-plan') {
    const { fitnessLevel, goal, daysPerWeek, mode, preferredSplit } = params;
    const availableExercises = JSON.stringify(EXERCISE_DATABASE);

    return `
      Sen, danışanlarının gelişimini RPE (Algılanan Efor) ve progresif aşırı yükleme ile takip eden bir IFBB Pro fitness koçusun.
      Sadece ve sadece aşağıda belirtilen şemaya uygun, TEK BİR JSON objesi döndür.

      Kullanıcı Profili:
      - Seviye: ${fitnessLevel}, Amaç: ${goal}, Haftalık Gün: ${daysPerWeek}, Yer: ${mode}

      KULLANABİLECEĞİN EGZERSİZLER VERİTABANI:
      ${availableExercises}
      
      İSTENEN JSON ŞEMASI:
      {
        "weekNumber": 1,
        "splitType": "string", // "Full Body", "Upper/Lower", "Push/Pull/Legs"
        "progressionNotes": "string", // "Her hafta ağırlığı veya tekrarı artırmaya odaklan."
        "days": [
          {
            "day": "string", // Örn: "Pazartesi"
            "focus": "string", // Örn: "Üst Vücut (İtiş)"
            "warmup": "string", // "5-10 dakika hafif kardiyo ve dinamik esneme."
            "exercises": [
              {
                "exerciseId": "string", // VERİTABANINDAN ALINACAK
                "name": "string", // VERİTABANINDAN ALINACAK
                "targetMuscle": "string",
                "sets": "int",
                "reps": "string", // Örn: "8-12"
                "rest": "int", // saniye cinsinden, Örn: 90
                "rpe": "string", // "6-7", "8-9" gibi RPE değeri ZORUNLU
                "gif": "string", // "https://storage.googleapis.com/zindeai-gifler/{exerciseId}.gif" formatında
                "notes": "string" // "Forma odaklan, son tekrarda zorlanmalısın."
              }
            ],
            "cooldown": "string" // "5 dakika statik esneme."
          }
        ]
      }

      TASARIM KURALLARI:
      1. EGZERSİZ KAYNAĞI: Sadece sana verilen veritabanındaki egzersizleri kullan.
      2. SPLIT MANTIĞI: 'daysPerWeek' değerine göre doğru split'i seç (2-3: Full Body, 4: Upper/Lower, 5-6: PPL).
      3. EGZERSİZ SAYISI: Full Body 6-8, Split günleri 5-6 egzersiz içermeli.
      4. RPE EKLE (ZORUNLU): Her egzersiz için, hedeflenen tekrar sayısına uygun bir RPE (1-10 arası) değeri ekle.
      5. MOD MANTIĞI:
         - 'gym': Ağırlıklı olarak barbell, dumbbell, machine ve cable hareketlerini kullan.
         - 'home': Sadece 'bodyweight' ve 'dumbbell' (eğer varsa) egzersizlerini kullan.
         - 'hybrid': Haftayı 'Spor Salonu Günü' ve 'Ev Günü' olarak böl.
      6. GIF URL: Her egzersiz için 'gif' alanını "https://storage.googleapis.com/zindeai-gifler/{exerciseId}.gif" formatında doldur.
    `;
  }

  return 'Geçersiz endpoint';
}

// AI sağlayıcılarını çağıran fonksiyon
async function callProvider(provider: string, prompt: string, systemPrompt: string = '') {
  const GROQ_API_KEY = Deno.env.get('GROQ_API_KEY');
  const GEMINI_API_KEY = Deno.env.get('GEMINI_API_KEY');
  const HF_API_KEY = Deno.env.get('HF_API_KEY');

  console.log(`[${provider}] sağlayıcısı çağrılıyor...`);

  try {
    let response;
    let data;

    switch (provider) {
      case 'groq':
        response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${GROQ_API_KEY}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            model: 'llama-3.1-8b-instant',
            messages: [
              { role: 'system', content: systemPrompt },
              { role: 'user', content: prompt }
            ],
            temperature: 0.7,
            max_tokens: 2000,
            response_format: { type: "json_object" }
          }),
        });
        if (!response.ok) throw new Error(`Groq API Hatası: ${response.statusText}`);
        data = await response.json();
        return data.choices?.[0]?.message?.content || data.choices?.[0]?.text;

      case 'gemini':
        const geminiPayload = {
          contents: [
            { parts: [{ text: systemPrompt }] },
            { parts: [{ text: prompt }] }
          ],
          generationConfig: {
            temperature: 0.7,
            maxOutputTokens: 2000
          }
        };
        response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${GEMINI_API_KEY}`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(geminiPayload),
        });
        if (!response.ok) throw new Error(`Gemini API Hatası: ${response.statusText}`);
        data = await response.json();
        return data.candidates?.[0]?.content?.parts?.[0]?.text;

      case 'hf':
        const hfModel = 'microsoft/DialoGPT-medium';
        response = await fetch(`https://api-inference.huggingface.co/models/${hfModel}`, {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${HF_API_KEY}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            inputs: `${systemPrompt}\n${prompt}`,
            parameters: {
              max_new_tokens: 2000
            }
          }),
        });
        if (!response.ok) throw new Error(`HuggingFace API Hatası: ${response.statusText}`);
        data = await response.json();
        return data[0]?.generated_text || data[0]?.text;

      default:
        throw new Error(`Bilinmeyen sağlayıcı: ${provider}`);
    }
  } catch (error) {
    console.error(`Provider ${provider} failed:`, error.message);
    throw error;
  }
}

// AI sağlayıcılarını sırayla dene
async function callAIWithFallback(prompt: string, systemPrompt: string): Promise<string> {
  const providers = ['groq', 'gemini', 'hf']; // Öncelik sırası

  for (const provider of providers) {
    try {
      console.log(`Trying provider: ${provider}`);
      const result = await callProvider(provider, prompt, systemPrompt);
      console.log(`Provider ${provider} succeeded`);
      return result;
    } catch (error) {
      console.error(`Provider ${provider} failed:`, error.message);
      continue; // Sonraki provider'a geç
    }
  }
  throw new Error('Tüm AI servisleri başarısız oldu');
}

serve(async (req) => {
  // CORS Preflight isteğini ele al
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  // Authorization kontrolü - sadece apikey header'ını kontrol et
  const apikey = req.headers.get('apikey')
  if (!apikey) {
    return new Response(
      JSON.stringify({ error: 'Missing apikey header' }),
      { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }

  try {
    const body = await req.json();
    const { type } = body;

    if (!type) {
      throw new Error('Missing type parameter');
    }

    const prompt = createPrompt(type, body);
    const systemPrompt = type === 'meal-plan' 
      ? 'Sen bir Türk diyetisyensin. Kullanıcının isteğine göre bir yemek planı oluşturacaksın. Sadece ve sadece aşağıda belirtilen şemaya uygun, TEK BİR JSON objesi döndür. Asla yorum satırı (// veya /* */) kullanma. Asla metin olarak açıklama ekleme. Sadece JSON çıktısı ver.'
      : 'Sen deneyimli bir fitness koçu ve IFBB Pro antrenörüsün. Kullanıcı profiline göre etkili bir antrenman programı tasarlayacaksın. Sadece ve sadece aşağıda belirtilen şemaya uygun, TEK BİR JSON objesi döndür. Asla yorum satırı (// veya /* */) veya açıklama metni ekleme. Sadece JSON çıktısı ver.';

    if (prompt === 'Geçersiz endpoint') {
      throw new Error('Endpoint anlaşılamadı.');
    }

    console.log('Calling AI with prompt type:', type);
    const rawApiResponse = await callAIWithFallback(prompt, systemPrompt);

    const cleanJsonData = cleanAndParseJson(rawApiResponse);

    return new Response(
      JSON.stringify(cleanJsonData),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Edge Function Error:', error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})