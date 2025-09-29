import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { GoogleGenerativeAI } from "https://esm.sh/@google/generative-ai@0.1.1"
  
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { requestType, data } = await req.json()
    
    const genAI = new GoogleGenerativeAI(Deno.env.get('GEMINI_API_KEY')!)
    const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" })
    
    if (requestType === 'plan') {
      // DİNAMİK BESLENME PLANI PROMPT'U
      const prompt = `
Sen Türkiye'nin en deneyimli ve başarılı diyetisyensin. 20 yıllık tecrüben var ve binlerce kişiye özel beslenme planları hazırladın. Spor beslenmesi, klinik beslenme ve fonksiyonel tıp konularında uzmansın.

KİŞİ PROFİLİ:
${JSON.stringify(data, null, 2)}

BU KİŞİ İÇİN ÖZEL BESLENME PLANI OLUŞTURMA TALİMATLARI:

1. KALORİ HESAPLAMASI:
- Bazal Metabolizma Hızı (BMR) hesapla
- Aktivite faktörünü ekle (sedanter: 1.2, hafif aktif: 1.375, orta aktif: 1.55, çok aktif: 1.725)
- Hedefe göre ayarla:
  * Kilo verme: TDEE - 500 kalori
  * Kas yapma: TDEE + 300-500 kalori
  * Koruma: TDEE

2. MAKRO DAĞILIMI:
- Protein: Vücut ağırlığı x 1.6-2.2g (spor yapıyorsa üst sınır)
- Yağ: Toplam kalorinin %25-30'u
- Karbonhidrat: Geriye kalan kalori

3. ÖĞÜN PLANLAMA:
- Sabah: Günlük kalorinin %25-30'u (metabolizmayı başlat)
- Ara Öğün 1: %10-15 (kan şekerini dengele)
- Öğle: %25-30 (günün ortasında enerji)
- Ara Öğün 2: %10-15 (antrenman öncesi/sonrası)
- Akşam: %20-25 (toparlanma için protein ağırlıklı)

4. GIDA SEÇİMİ KRİTERLERİ:
- Kişinin diyet tercihine uy (vegan, vejetaryen, normal)
- Türk mutfağından yemekler kullan
- Mevsimsel ve ulaşılabilir gıdalar seç
- Bütçe dostu alternatifler sun
- Alerjenleri kesinlikle hariç tut

5. HER ÖĞÜN İÇİN:
- Gerçekçi porsiyon miktarları (gram/adet/bardak)
- Pişirme yöntemini belirt
- Besin değerlerini hassas hesapla
- En az 3-5 malzeme kullan

6. HAFTALIK ÇEŞİTLİLİK:
- Her gün farklı protein kaynağı
- Renkli sebze/meyve çeşitliliği
- Farklı tahıl alternatifleri
- Hiçbir öğünü copy-paste yapma

7. ÖZEL DURUMLAR:
${data.health_conditions ? `Sağlık durumu: ${data.health_conditions}` : ''}
${data.training_days ? `Haftada ${data.training_days} gün antrenman yapıyor - antrenman günleri daha fazla karbonhidrat` : ''}
${data.gender === 'female' ? 'Kadın - Demir açısından zengin gıdalar ekle' : ''}
${data.age > 40 ? 'Yaş 40+ - Antioksidan zengin, anti-inflamatuar gıdalar' : ''}

MUTLAKA BU JSON FORMATINI KULLAN (değerleri dinamik hesapla):
{
  "days": [
          {
            "day": 1,
      "dayName": "Pazartesi",
      "meals": {
        "sabah": {
          "name": "[Kahvaltı yemeği adı]",
          "calories": [hesaplanan kalori],
          "protein": [gram protein],
          "carbs": [gram karbonhidrat],
          "fats": [gram yağ],
          "ingredients": [
            {"name": "[gıda adı]", "amount": "[miktar + birim]"},
            {"name": "[gıda adı]", "amount": "[miktar + birim]"}
          ]
        },
        "ara_ogun_1": {
          "name": "[Ara öğün adı]",
          "calories": [hesaplanan kalori],
          "protein": [gram protein],
          "carbs": [gram karbonhidrat],
          "fats": [gram yağ],
          "ingredients": [
            {"name": "[gıda adı]", "amount": "[miktar + birim]"}
          ]
        },
        "ogle": {
          "name": "[Öğle yemeği adı]",
          "calories": [hesaplanan kalori],
          "protein": [gram protein],
          "carbs": [gram karbonhidrat],
          "fats": [gram yağ],
          "ingredients": [
            {"name": "[gıda adı]", "amount": "[miktar + birim]"}
          ]
        },
        "ara_ogun_2": {
          "name": "[İkindi ara öğün]",
          "calories": [hesaplanan kalori],
          "protein": [gram protein],
          "carbs": [gram karbonhidrat],
          "fats": [gram yağ],
          "ingredients": [
            {"name": "[gıda adı]", "amount": "[miktar + birim]"}
          ]
        },
        "aksam": {
          "name": "[Akşam yemeği adı]",
          "calories": [hesaplanan kalori],
          "protein": [gram protein],
          "carbs": [gram karbonhidrat],
          "fats": [gram yağ],
          "ingredients": [
            {"name": "[gıda adı]", "amount": "[miktar + birim]"}
          ]
        }
      },
      "totalCalories": [günlük toplam],
      "macros": {
        "protein": [günlük protein],
        "carbs": [günlük karb],
        "fats": [günlük yağ]
      }
    }
  ],
  "totalCalories": [haftalık ortalama],
  "macros": {
    "protein": [ortalama protein],
    "carbs": [ortalama karb],
    "fats": [ortalama yağ]
  },
  "nutritionTips": [
    "Kişiye özel 3-5 beslenme tavsiyesi"
  ]
}

ÇOK ÖNEMLİ KURALLAR:
1. 7 günün HEPSİNİ doldur
2. Her gün FARKLI yemekler olsun
3. Kalori ve makrolar MATEMATİKSEL olarak doğru olsun
4. Türk damak tadına uygun yemekler seç
5. Gerçekçi porsiyonlar kullan
6. Tüm sayısal değerler INTEGER olmalı
7. JSON dışında hiçbir şey yazma, sadece JSON döndür`;

      const result = await model.generateContent(prompt)
      let planText = result.response.text()
      
      // JSON temizleme
      planText = planText.replace(/```json/gi, '').replace(/```/gi, '')
      const jsonMatch = planText.match(/\{[\s\S]*\}/)
      
      if (jsonMatch) {
        const plan = JSON.parse(jsonMatch[0])
        return new Response(
          JSON.stringify({ success: true, plan }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }
      
    } else if (requestType === 'antrenman') {
      // PROFESYONEL ANTRENMAN PLANI
      const prompt = `
Sen Türkiye'nin en iyi kişisel antrenörü ve spor koçusun. NSCA-CPT, NASM-CES sertifikaların var. Olimpik sporcular yetiştirdin.

KİŞİ PROFİLİ:
${JSON.stringify(data, null, 2)}

ANTRENMAN PLANI OLUŞTURMA:

1. SEVİYE ANALİZİ:
- Beginner: Temel compound hareketler, düşük hacim
- Intermediate: Compound + izolasyon, orta hacim  
- Advanced: Periodizasyon, yüksek hacim

2. SPLIT SEÇİMİ:
- 3 gün: Full Body (her kas grubu her antrenman)
- 4 gün: Upper/Lower (üst gövde/alt gövde)
- 5 gün: Push/Pull/Legs/Upper/Lower
- 6 gün: Push/Pull/Legs x2

3. HACIM HESAPLAMASI:
- Büyük kaslar: Haftada 12-20 set
- Küçük kaslar: Haftada 8-12 set
- Başlangıç seviye: Alt limit
- İleri seviye: Üst limit

4. YÜKLENME PARAMETRELERİ:
- Güç: 1-5 tekrar, 3-5 dk dinlenme
- Hipertrofi: 6-12 tekrar, 60-90 sn dinlenme
- Dayanıklılık: 12-20 tekrar, 30-60 sn dinlenme

5. HER EGZERSİZ İÇİN BELİRT:
- Set sayısı (3-5 arası)
- Tekrar aralığı (örn: 8-10)
- Dinlenme süresi (saniye cinsinden tam sayı)
- RPE (1-10 zorluk derecesi)
- Tempo (eksantrik-duraklama-konsantrik-duraklama)
- Form ipucu (yaralanmayı önleyici)

HEDEF: ${data.goal || 'genel fitness'}
SEVİYE: ${data.fitness_level || 'beginner'}
GÜN SAYISI: ${data.training_days || 3}

ZORUNLU JSON FORMATI:
{
  "trainingPlan": {
    "programName": "[Program adı]",
    "level": "[seviye]",
    "duration": "8 hafta",
    "frequency": [gün sayısı],
    "split": "[split tipi]",
    "weeklyVolume": {
      "chest": [set sayısı],
      "back": [set sayısı],
      "shoulders": [set sayısı],
      "legs": [set sayısı],
      "arms": [set sayısı]
    },
    "days": [
            {
              "day": 1,
        "name": "[Gün adı - örn: Push Day]",
        "focus": "[Hedef kaslar]",
        "warmup": "[5-10 dk ısınma önerisi]",
              "exercises": [
                {
            "name": "[Egzersiz adı]",
            "targetMuscle": "[Hedef kas]",
            "sets": [3-5 arası sayı],
            "reps": "[tekrar - örn: 8-10]",
            "rest": [60, 90 veya 120],
            "rpe": [1-10 arası],
            "tempo": "[2-0-2-0 formatında]",
            "formTip": "[Doğru form için ipucu]",
            "notes": "[Ek notlar]"
          }
        ],
        "cooldown": "[5 dk soğuma önerisi]"
      }
    ],
    "progressionTips": [
      "İlerleme için 3-5 öneri"
    ]
  }
}

KURALLAR:
1. Her gün için EN AZ 5-6 egzersiz
2. Compound hareketler önce, izolasyon sonra
3. Rest MUTLAKA tam sayı (60, 90, 120, 180)
4. Türkçe egzersiz isimleri veya bilinen İngilizce terimler
5. Gerçekçi ve uygulanabilir program
6. JSON dışında hiçbir şey yazma`;

      const result = await model.generateContent(prompt)
      let planText = result.response.text()
      
      planText = planText.replace(/```json/gi, '').replace(/```/gi, '')
      const jsonMatch = planText.match(/\{[\s\S]*\}/)
      
      if (jsonMatch) {
        const antrenman = JSON.parse(jsonMatch[0])
        return new Response(
          JSON.stringify({ success: true, antrenman }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }
    }
    
  } catch (error) {
    console.error('Hata:', error)
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: error.message 
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500 
      }
    )
  }
})