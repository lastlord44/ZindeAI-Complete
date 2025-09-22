import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// AI Provider API Keys (Environment Variables)
const GROQ_API_KEY = Deno.env.get('GROQ_API_KEY')
const GEMINI_API_KEY = Deno.env.get('GEMINI_API_KEY')
const HF_API_KEY = Deno.env.get('HF_API_KEY')

interface MealPlanRequest {
  calories: number
  goal: string
  diet: string
  daysPerWeek: number
  preferences?: Record<string, boolean>
}

// AI Fallback Chain
async function callAIWithFallback(prompt: string): Promise<string> {
  const providers = ['groq', 'gemini', 'hf']
  
  for (const provider of providers) {
    try {
      let response: Response
      
      switch (provider) {
        case 'groq':
          response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
            method: 'POST',
            headers: {
              'Authorization': `Bearer ${GROQ_API_KEY}`,
              'Content-Type': 'application/json',
            },
            body: JSON.stringify({
              messages: [
                {
                  role: 'system',
                  content: 'Sen ZindeAI beslenme uzmanısın. Türk mutfağına uygun, sağlıklı ve pratik yemek planları hazırlarsın. TÜM yemek isimlerini TÜRKÇE yaz. JSON formatında detaylı plan ver.'
                },
                {
                  role: 'user',
                  content: prompt
                }
              ],
              temperature: 0.7,
              max_tokens: 2000
            }),
          })
          break
          
        case 'gemini':
          response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${GEMINI_API_KEY}`, {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
            },
            body: JSON.stringify({
              contents: [{
                parts: [{
                  text: `Sen ZindeAI beslenme uzmanısın. Türk mutfağına uygun, sağlıklı ve pratik yemek planları hazırlarsın. TÜM yemek isimlerini TÜRKÇE yaz. JSON formatında detaylı plan ver.\n\n${prompt}`
                }]
              }],
              generationConfig: {
                temperature: 0.7,
                maxOutputTokens: 2000
              }
            }),
          })
          break
          
        case 'hf':
          response = await fetch('https://api-inference.huggingface.co/models/microsoft/DialoGPT-medium', {
            method: 'POST',
            headers: {
              'Authorization': `Bearer ${HF_API_KEY}`,
              'Content-Type': 'application/json',
            },
            body: JSON.stringify({
              inputs: prompt,
              parameters: {
                max_new_tokens: 500
              }
            }),
          })
          break
          
        default:
          continue
      }
      
      if (!response.ok) {
        console.log(`Provider ${provider} failed: ${response.status}`)
        continue
      }
      
      const data = await response.json()
      let content = ''
      
      // Parse response based on provider
      switch (provider) {
        case 'groq':
          content = data.choices?.[0]?.message?.content || ''
          break
        case 'gemini':
          content = data.candidates?.[0]?.content?.parts?.[0]?.text || ''
          break
        case 'hf':
          content = data[0]?.generated_text || ''
          break
      }
      
      if (content) {
        console.log(`Success with provider: ${provider}`)
        return content
      }
      
    } catch (error) {
      console.log(`Provider ${provider} error:`, error)
      continue
    }
  }
  
  throw new Error('Tüm AI servisleri başarısız oldu')
}

// Parse AI response to JSON
function parseAIResponse(aiResponse: string): any {
  try {
    // Extract JSON from markdown code blocks
    let jsonString = aiResponse
    if (aiResponse.includes('```json')) {
      const start = aiResponse.indexOf('```json') + 7
      const end = aiResponse.indexOf('```', start)
      jsonString = aiResponse.substring(start, end).trim()
    } else if (aiResponse.includes('```')) {
      const start = aiResponse.indexOf('```') + 3
      const end = aiResponse.indexOf('```', start)
      jsonString = aiResponse.substring(start, end).trim()
    }
    
    // Remove comments
    jsonString = jsonString.replace(/\/\/.*$/gm, '')
    
    return JSON.parse(jsonString)
  } catch (error) {
    console.error('JSON parse error:', error)
    throw new Error('AI yanıtı parse edilemedi')
  }
}

serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { calories, goal, diet, daysPerWeek, preferences }: MealPlanRequest = await req.json()
    
    console.log('Meal plan request:', { calories, goal, diet, daysPerWeek })
    
    // Preferences'ı string'e çevir
    const preferencesStr = preferences ? 
      Object.entries(preferences)
        .filter(([_, value]) => value === true)
        .map(([key, _]) => key)
        .join(', ') : 'yok'
    
    const dayNames = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar']
    
    const prompt = `${daysPerWeek} günlük yemek planı hazırla:
    - Günlük kalori: ${calories || 1500}
    - Hedef: ${goal === 'lose' ? 'kilo verme' : goal === 'gain' ? 'kilo alma' : 'kilo koruma'}
    - Diyet tipi: ${diet || 'dengeli'}
    - Tercihler: ${preferencesStr}
    
    ${daysPerWeek === 7 ? 'Haftalık plan' : `${daysPerWeek} günlük plan`} oluştur.
    TÜM yemek isimlerini TÜRKÇE yaz. JSON formatında döndür:
    {
      "totalCalories": ${calories || 1500},
      "totalProtein": <hedefe göre hesapla>,
      "totalCarbs": <hesapla>,
      "totalFat": <hesapla>,
      "weeklyPlan": [
        ${Array.from({length: daysPerWeek}, (_, i) => `
        {
          "day": "${dayNames[i]}",
          "meals": [
            {
              "name": "Kahvaltı",
              "type": "breakfast",
              "calories": <sayı>,
              "items": ["türkçe yemek1", "türkçe yemek2"],
              "notes": "opsiyonel not"
            },
            {
              "name": "Öğle Yemeği",
              "type": "lunch",
              "calories": <sayı>,
              "items": ["türkçe yemek1", "türkçe yemek2"],
              "notes": "opsiyonel not"
            },
            {
              "name": "Akşam Yemeği",
              "type": "dinner",
              "calories": <sayı>,
              "items": ["türkçe yemek1", "türkçe yemek2"],
              "notes": "opsiyonel not"
            },
            {
              "name": "Ara Öğün",
              "type": "snack",
              "calories": <sayı>,
              "items": ["türkçe yemek1"],
              "notes": "opsiyonel not"
            }
          ]
        }`).join(',')}
      ]
    }`
    
    // AI'yi çağır
    const aiResponse = await callAIWithFallback(prompt)
    const mealPlan = parseAIResponse(aiResponse)
    
    return new Response(
      JSON.stringify(mealPlan),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      },
    )
    
  } catch (error) {
    console.error('Error:', error)
    return new Response(
      JSON.stringify({ 
        error: 'Yemek planı oluşturulamadı', 
        details: error.message 
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      },
    )
  }
})
