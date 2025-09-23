import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { corsHeaders } from '../_shared/cors.ts'

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

function createPrompt(endpoint: string, body: any): string {
    if (endpoint === 'plan') {
        const { calories, goal } = body;
        const daysPerWeek = 7;
        return `7 günlük Türkçe yemek planı oluştur. Günlük ${calories} kalori.

KURALLARI TAKİP ET:
1. Tam olarak 7 gün olacak (Pazartesi-Pazar)
2. Her gün 4 öğün olacak
3. Türk yemekleri kullan
4. SADECE JSON döndür
5. Türkiye'nin en iyi diyetisyenisin

FORMAT:
{"totalCalories": ${calories}, "totalProtein": ${Math.round(calories*0.3/4)}, "totalCarbs": ${Math.round(calories*0.4/4)}, "totalFat": ${Math.round(calories*0.3/9)}, "weeklyPlan": [{"day": "Pazartesi", "meals": [{"name": "Kahvaltı", "type": "breakfast", "calories": 500, "items": ["Yumurta","Peynir"], "notes": ""}]}]}`;
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
    
    if (endpoint === 'plan') {
      console.log('Beslenme planı için Groq 70B çağrılıyor...');
      const GROQ_API_KEY = Deno.env.get('GROQ_API_KEY');
      const GEMINI_API_KEY = Deno.env.get('GEMINI_API_KEY');
      
      // GROQ İÇİN DAHA İYİ MODEL VE PROMPT
      const groqPayload = {
        model: 'llama-3.1-70b-versatile', // ÜST VERSİYON
        messages: [
          {
            role: 'system',
            content: 'JSON uzmanısın. SADECE JSON döndür, başka açıklama yapma.'
          },
          {
            role: 'user',
            content: prompt
          }
        ],
        temperature: 0.2, // Daha tutarlı
        max_tokens: 4000, // Daha fazla token
        response_format: { type: "json_object" } // JSON ZORLA
      };
      
      // Önce Groq'u dene
      const groqResponse = await fetch('https://api.groq.com/openai/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${GROQ_API_KEY}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(groqPayload),
      });
      
      if (groqResponse.ok) {
        const groqData = await groqResponse.json();
        const content = groqData.choices?.[0]?.message?.content;
        
        if (content) {
          try {
            const parsed = JSON.parse(content);
            
            // 7 gün kontrolü
            if (parsed.weeklyPlan && parsed.weeklyPlan.length === 7) {
              console.log('Groq 70B başarılı, 7 gün geldi');
              return new Response(
                JSON.stringify(parsed),
                { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
              );
            }
          } catch (e) {
            console.error('Groq parse hatası:', e);
          }
        }
      }
      
      // Groq başarısızsa Gemini dene
      console.log('Groq başarısız, Gemini deneniyor...');
      const geminiPayload = {
        contents: [{
          parts: [{
            text: `7 günlük yemek planı JSON: ${prompt}`
          }]
        }],
        generationConfig: {
          temperature: 0.2,
          maxOutputTokens: 2000
        }
      };
      
      const geminiResponse = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${GEMINI_API_KEY}`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(geminiPayload),
        }
      );
      
      if (geminiResponse.ok) {
        const geminiData = await geminiResponse.json();
        const text = geminiData.candidates?.[0]?.content?.parts?.[0]?.text;
        
        if (text) {
          // Temizle
          const cleaned = text
            .replace(/```json\s*/gi, '')
            .replace(/```\s*/gi, '')
            .trim();
          
          try {
            const parsed = JSON.parse(cleaned);
            if (parsed.weeklyPlan && parsed.weeklyPlan.length === 7) {
              console.log('Gemini başarılı, 7 gün geldi');
              return new Response(
                JSON.stringify(parsed),
                { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
              );
            }
          } catch (e) {
            console.error('Gemini parse hatası:', e);
          }
        }
      }
      
      // İKİSİ DE BAŞARISIZ - HATA DÖNDÜR (FALLBACK YOK)
      return new Response(
        JSON.stringify({
          error: 'AI servisleri 7 günlük plan oluşturamadı',
          details: 'Groq 70B ve Gemini başarısız oldu'
        }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
      
    } else if (endpoint === 'antrenman') {
      console.log('Antrenman planı için Groq 70B çağrılıyor...');
      const GROQ_API_KEY = Deno.env.get('GROQ_API_KEY');
      
      providerResponse = await fetch('https://api.groq.com/openai/v1/chat/completions', {
        method: 'POST',
        headers: { 'Authorization': `Bearer ${GROQ_API_KEY}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({
          model: 'llama-3.1-70b-versatile', // ÜST VERSİYON
          messages: [{ role: 'user', content: prompt }],
          response_format: { type: "json_object" }
        }),
      });
    } else {
        throw new Error("Geçersiz endpoint türü");
    }

    // Sadece antrenman endpoint'i için bu kısım çalışır
    if (endpoint === 'antrenman') {
      if (!providerResponse.ok) {
        const errorBody = await providerResponse.text();
        throw new Error(`API Hatası: ${providerResponse.status} ${errorBody}`);
      }
      
      const jsonData = await providerResponse.json();
      
      return new Response(
        JSON.stringify(jsonData),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }
  } catch (error) {
    console.error("Fonksiyon Hatası:", error);
    return new Response(
      JSON.stringify({ 
        error: error.message || 'Internal server error',
        details: error.toString(),
        stack: error.stack
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})