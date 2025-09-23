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

interface WorkoutPlanRequest {
  age: number
  gender: string
  weight: number
  height: number
  fitnessLevel: string
  goal: string
  mode: string
  daysPerWeek: number
  preferredSplit?: string
  equipment?: string[]
  injuries?: string[]
  timePerSession?: number
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
              model: 'llama-3.1-70b-versatile', // EN İYİ MODEL
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
                  text: `Sen ZindeAI fitness uzmanısın. Evde yapılabilecek, etkili antrenman planları hazırlarsın. TÜM egzersiz isimlerini TÜRKÇE yaz. JSON formatında detaylı plan ver.\n\n${prompt}`
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
    const {
      age,
      gender,
      weight,
      height,
      fitnessLevel,
      goal,
      mode,
      daysPerWeek,
      preferredSplit,
      equipment,
      injuries,
      timePerSession
    }: WorkoutPlanRequest = await req.json()
    
    console.log('Workout plan request:', {
      age, gender, weight, height, fitnessLevel, goal, mode, daysPerWeek
    })
    
    const prompt = `Hedef: ${goal || 'genel fitness'}. 
    Seviye: ${fitnessLevel || 'başlangıç'}. 
    Yaş: ${age || 25}. 
    Cinsiyet: ${gender || 'erkek'}. 
    Kilo: ${weight || 70}kg. 
    Boy: ${height || 170}cm. 
    Haftalık gün: ${daysPerWeek || 3}. 
    Mod: ${mode || 'ev'}. 
    Ekipman: ${equipment?.join(', ') || 'yok'}. 
    Yaralanma: ${injuries?.join(', ') || 'yok'}.
    Süre: ${timePerSession || 45} dakika.

    TÜM egzersiz isimlerini TÜRKÇE yaz. JSON formatında döndür:
    {
      "userId": "user_123",
      "weekNumber": 1,
      "splitType": "${preferredSplit || 'fullbody'}",
      "mode": "${mode || 'ev'}",
      "goal": "${goal || 'genel fitness'}",
      "days": [
        ${Array.from({length: daysPerWeek}, (_, i) => `
        {
          "dayName": "${['Pazartesi','Salı','Çarşamba','Perşembe','Cuma','Cumartesi','Pazar'][i]}",
          "exercises": [
            {
              "name": "Türkçe egzersiz adı",
              "sets": 3,
              "reps": "10-12",
              "rest": 60,
              "notes": "Türkçe not"
            }
          ]
        }`).join(',')}
      ],
      "progressionNotes": "Türkçe notlar"
    }`
    
    // AI'yi çağır
    const aiResponse = await callAIWithFallback(prompt)
    const workoutPlan = parseAIResponse(aiResponse)
    
    return new Response(
      JSON.stringify(workoutPlan),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      },
    )
    
  } catch (error) {
    console.error('Error:', error)
    return new Response(
      JSON.stringify({ 
        error: 'Antrenman planı oluşturulamadı', 
        details: error.message 
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      },
    )
  }
})
