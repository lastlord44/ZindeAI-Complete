import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { corsHeaders } from '../_shared/cors.ts'

// ONAYLI EGZERSİZ VERİTABANI
const EXERCISE_DATABASE = [
    { exerciseId: 'barbell_bench_press', name: 'Barbell Bench Press' }, { exerciseId: 'dumbbell_bench_press', name: 'Dumbbell Bench Press' },
    { exerciseId: 'push_up', name: 'Push-up' }, { exerciseId: 'overhead_press', name: 'Overhead Press' },
    { exerciseId: 'barbell_squat', name: 'Barbell Squat' }, { exerciseId: 'goblet_squat', name: 'Goblet Squat' },
    { exerciseId: 'leg_press', name: 'Leg Press' }, { exerciseId: 'pull_up', name: 'Pull-up' },
    { exerciseId: 'barbell_row', name: 'Barbell Row' }, { exerciseId: 'biceps_curl', name: 'Biceps Curl' },
    { exerciseId: 'triceps_pushdown', name: 'Triceps Pushdown' }, { exerciseId: 'plank', name: 'Plank' },
    { exerciseId: 'incline_dumbbell_press', name: 'Incline Dumbbell Press' }, { exerciseId: 'lat_pulldown', name: 'Lat Pulldown' },
    { exerciseId: 'lateral_raise', name: 'Lateral Raise' }, { exerciseId: 'leg_curl', name: 'Leg Curl' }, { exerciseId: 'lunges', name: 'Lunges' }
];

function cleanAndParseJson(text: string) {
  try {
    let cleanText = text.trim();
    
    // 1. Markdown kod bloklarını temizle (```json ve ```)
    cleanText = cleanText.replace(/^```json\s*/i, '').replace(/```\s*$/, '');
    
    // 2. Yorum satırlarını temizle
    cleanText = cleanText.replace(/\/\*[\s\S]*?\*\/|\/\/.*/g, '');
    
    // 3. Trailing comma'ları temizle
    cleanText = cleanText.replace(/,\s*([\]}])/g, '$1');
    
    // 4. İlk { ve son } karakterlerini bul
    const startIndex = cleanText.indexOf('{');
    const endIndex = cleanText.lastIndexOf('}');
    
    if (startIndex !== -1 && endIndex !== -1 && endIndex > startIndex) {
      cleanText = cleanText.substring(startIndex, endIndex + 1);
    }
    
    return JSON.parse(cleanText);
  } catch (error) {
    console.error("JSON Temizleme ve Parse Etme Hatası:", error);
    console.error("Ham metin:", text.substring(0, 200));
    throw new Error(`Geçersiz JSON formatı: ${text.substring(0, 100)}...`);
  }
}

function createPrompt(endpoint: string, body: any): string {
    if (endpoint === 'plan') {
        const { calories, goal, daysPerWeek } = body;
        return `
          Sen bir Türk uzman diyetisyensin. Sadece JSON formatında cevap ver. Asla açıklama ekleme.
          Kullanıcı ${daysPerWeek} günlük, yaklaşık ${calories} kalorilik, "${goal}" amaçlı bir plan istiyor.
          
          ZORUNLU JSON FORMATI:
          { "planTitle": "string", "summary": "string", "dailyPlan": [ { "day": "string", "meals": [ { "mealName": "string", "items": [ { "itemName": "string", "quantity": "int", "unit": "string", "calories": "int", "protein": "int", "carbs": "int", "fat": "int" } ] } ] } ] }

          ÖRNEK ÇIKTI:
          { "planTitle": "Kilo Alma Odaklı Plan", "summary": "Bu plan kas kütlesi kazanmanıza yardımcı olur.", "dailyPlan": [ { "day": "Pazartesi", "meals": [ { "mealName": "Kahvaltı", "items": [ { "itemName": "Yulaf Ezmesi", "quantity": 80, "unit": "g", "calories": 300, "protein": 10, "carbs": 50, "fat": 5 } ] } ] } ] }
        `;
    }

    if (endpoint === 'antrenman') {
        const { fitnessLevel, goal, daysPerWeek, mode, preferredSplit } = body;
        return `
          Sen bir IFBB Pro fitness koçusun. Sadece JSON formatında cevap ver. Asla yorum satırı veya açıklama ekleme.
          Kullanıcı ${daysPerWeek} günlük, "${goal}" amaçlı bir plan istiyor.
          
          ZORUNLU KURALLAR:
          1. SPLIT MANTIĞI: 'preferredSplit' AUTO ise, 'daysPerWeek'e göre split seç: 2-3 gün ise 'Full Body'; 4 gün ise 'Upper/Lower'; 5-6 gün ise 'Push/Pull/Legs'.
          2. EGZERSİZ SAYISI (EN ÖNEMLİ KURAL): Full Body günleri 6 ILE 8 ARASINDA egzersiz içermelidir. Split günleri (Upper, Lower, PPL vb.) 5 ILE 6 ARASINDA ana egzersiz içermelidir. BU KURALA UYMAK ZORUNDASIN, ASLA DAHA AZ EGZERSİZ YAZMA.
          3. EGZERSİZ KAYNAĞI: Sadece ve sadece sana aşağıda verilen 'KULLANILABİLİR EGZERSİZLER' listesindeki exerciseId'leri kullan.

          KULLANILABİLİR EGZERSİZLER: ${JSON.stringify(EXERCISE_DATABASE.map(e => e.exerciseId))}
          
          İSTENEN JSON ŞEMASI:
          { "weekNumber": 1, "splitType": "string", "progressionNotes": "string", "days": [ { "day": "string", "focus": "string", "exercises": [ { "exerciseId": "string", "name": "string", "sets": "int", "reps": "string", "rest": "int" } ] } ] }

          ÖRNEK ÇIKTI (4 günlük Upper/Lower için, EGZERSİZ SAYISI KURALINA DİKKAT ET):
          {
            "weekNumber": 1,
            "splitType": "Upper/Lower",
            "progressionNotes": "Her hafta ağırlığı veya tekrar sayısını artırmaya odaklan.",
            "days": [
              { "day": "Pazartesi", "focus": "Üst Vücut - İtiş", "exercises": [
                { "exerciseId": "barbell_bench_press", "name": "Barbell Bench Press", "sets": 4, "reps": "8-10", "rest": 90 },
                { "exerciseId": "incline_dumbbell_press", "name": "Incline Dumbbell Press", "sets": 3, "reps": "10-12", "rest": 60 },
                { "exerciseId": "overhead_press", "name": "Overhead Press", "sets": 3, "reps": "8-10", "rest": 90 },
                { "exerciseId": "lateral_raise", "name": "Lateral Raise", "sets": 3, "reps": "12-15", "rest": 45 },
                { "exerciseId": "triceps_pushdown", "name": "Triceps Pushdown", "sets": 3, "reps": "10-12", "rest": 45 }
              ]},
              { "day": "Salı", "focus": "Alt Vücut", "exercises": [
                { "exerciseId": "barbell_squat", "name": "Barbell Squat", "sets": 4, "reps": "8-10", "rest": 120 },
                { "exerciseId": "leg_press", "name": "Leg Press", "sets": 3, "reps": "10-12", "rest": 90 },
                { "exerciseId": "lunges", "name": "Lunges", "sets": 3, "reps": "10-12", "rest": 90 },
                { "exerciseId": "leg_curl", "name": "Leg Curl", "sets": 3, "reps": "12-15", "rest": 60 },
                { "exerciseId": "plank", "name": "Plank", "sets": 3, "reps": "60s", "rest": 60 }
              ]}
            ]
          }
        `;
    }
    return 'Geçersiz endpoint';
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const body = await req.json();
    const endpoint = body.requestType; 

    if (!endpoint) {
      throw new Error("İstekte 'requestType' alanı (plan veya antrenman) belirtilmemiş.");
    }
    
    const prompt = createPrompt(endpoint, body);
    
    if (prompt === 'Geçersiz endpoint') {
        throw new Error(`Endpoint anlaşılamadı: ${endpoint}`);
    }

    let providerResponse;
    let rawContent = '';

    if (endpoint === 'plan') {
      console.log('Beslenme planı için Gemini çağrılıyor...');
      const GEMINI_API_KEY = Deno.env.get('GEMINI_API_KEY');
      const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=${GEMINI_API_KEY}`;
      
      providerResponse = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
          generationConfig: { 
            responseMimeType: "application/json",
            temperature: 0.1
          }
        }),
      });

      if (!providerResponse.ok) throw new Error(`Gemini API Hatası: ${await providerResponse.text()}`);
      
      const jsonData = await providerResponse.json();
      // YENİ GÜVENLİK KONTROLÜ
      if (!jsonData.candidates || !jsonData.candidates[0].content.parts[0].text) {
        throw new Error('Gemini API cevabı beklenmedik bir formatta geldi.');
      }
      rawContent = jsonData.candidates[0].content.parts[0].text;

    } else if (endpoint === 'antrenman') {
      console.log('Antrenman planı için Groq (Llama) çağrılıyor...');
      const GROQ_API_KEY = Deno.env.get('GROQ_API_KEY');
      
      providerResponse = await fetch('https://api.groq.com/openai/v1/chat/completions', {
        method: 'POST',
        headers: { 'Authorization': `Bearer ${GROQ_API_KEY}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({
          model: 'llama-3.1-8b-instant',
          messages: [{ role: 'user', content: prompt }],
          response_format: { type: "json_object" }
        }),
      });

      if (!providerResponse.ok) throw new Error(`Groq API Hatası: ${await providerResponse.text()}`);
      
      const jsonData = await providerResponse.json();
      rawContent = jsonData.choices[0].message.content;
    }
    
    // SON KONTROL: Gelen içeriğin gerçekten JSON'a benzediğinden emin ol
    // Eğer düz metin ise, cleanAndParseJson fonksiyonu bir hata fırlatacak.
    const cleanJsonData = cleanAndParseJson(rawContent);

    return new Response(
      JSON.stringify(cleanJsonData),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    // Fırlatılan herhangi bir hata burada yakalanacak ve Flutter'a temiz bir hata mesajı olarak gönderilecek.
    console.error("Fonksiyon Hatası:", error.message);
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})