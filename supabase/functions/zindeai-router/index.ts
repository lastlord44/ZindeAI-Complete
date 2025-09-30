import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { GoogleGenerativeAI } from "https://esm.sh/@google/generative-ai@0.21.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    console.log("Request received:", req.method, req.url);

    // Test endpoint
    if (req.url.includes("test")) {
      return new Response(
        JSON.stringify({
          success: true,
          message: "Edge Function çalışıyor!",
          timestamp: new Date().toISOString(),
        }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const { requestType, data } = await req.json();
    console.log("Request data:", { requestType, data });

    const apiKey = Deno.env.get("GEMINI_API_KEY");
    console.log("API Key exists:", !!apiKey);

    if (!apiKey) {
      throw new Error("GEMINI_API_KEY not found");
    }

     const genAI = new GoogleGenerativeAI(apiKey);
     const model = genAI.getGenerativeModel({
       model: "gemini-2.0-flash-exp",
       generationConfig: {
         temperature: 0.1, // ÇOK DÜŞÜK = kurallara %100 uyar
         topP: 0.7,
         topK: 20,
         maxOutputTokens: 8192,
       },
       systemInstruction: "Sen bir profesyonel diyetisyen ve fitness koçusun. Verilen hedef kalori ve protein değerlerini KESINLIKLE tutturmalısın. Düşük değerler KABUL EDİLMEZ. Yasak besinleri ASLA ÖNERMEYECEKSİN.",
     });

    if (requestType === "plan") {
      // Kullanıcı bilgilerini al
      const userWeight = data.weight_kg || data.weight || 70;
      const userGoal = (data.goal || data.primary_goal || "").toLowerCase();
      const targetCalories = data.calories || 2000; // FRONTENDden GELEN HESAPLANMIŞ KALORİ!

      console.log(
        "🔍 BESLENME PLANI - Gelen Veri:",
        JSON.stringify(data, null, 2),
      );
      console.log("📊 Kullanıcı Bilgileri:", {
        weight: userWeight,
        goal: userGoal,
        targetCalories: targetCalories,
      });

      // KALORİ KONTROL - Eğer çok düşükse uyar!
      if (targetCalories < 1500) {
        console.warn("⚠️ UYARI: Kalori çok düşük!", targetCalories);
      }

      // Protein hesapla (KILO BAZLI - Bilimsel Standart: 1.8-2.2g/kg)
      let proteinMultiplier = 1.8; // varsayılan
      let minProteinPerMeal = 25;

      if (
        userGoal.includes("muscle") || userGoal.includes("gain") ||
        userGoal.includes("kazanma") || userGoal.includes("alma")
      ) {
        // Kas kazanma/Kilo alma: 2.0-2.2g protein/kg
        proteinMultiplier = 2.2;
        minProteinPerMeal = 30;
      } else if (
        userGoal.includes("fat") || userGoal.includes("loss") ||
        userGoal.includes("verme")
      ) {
        // Kilo verme: 1.8-2.0g protein/kg (kas koruma için)
        proteinMultiplier = 2.0;
        minProteinPerMeal = 25;
      }

      const minDailyProtein = Math.round(userWeight * proteinMultiplier);
      const maxDailyProtein = Math.round(userWeight * 2.2); // Maksimum 2.2g/kg

      console.log("🎯 Hedefler:", {
        calories: targetCalories,
        protein: `${minDailyProtein}-${maxDailyProtein}g`,
      });

       // PROMPT - Profesyonel Diyetisyen - Beslenme Planı
       const prompt = `
🔴🔴🔴 UYARI: BUNLARI YAPMAZSAN PLAN KULLANILMAZ VE SİLİNİR! 🔴🔴🔴

📊 ZORUNLU HEDEFLER (DEĞİŞTİRİLEMEZ):
1️⃣ GÜNLÜK KALORİ: MİNİMUM ${targetCalories - 100} kcal - MAKSİMUM ${targetCalories + 100} kcal
2️⃣ GÜNLÜK PROTEİN: MİNİMUM ${minDailyProtein}g - MAKSİMUM ${maxDailyProtein}g
3️⃣ YASAK BESİNLER: Simit, gözleme, börek, pide, lahmacun, pizza ASLA!

⚠️ Bu değerlerin altında plan = YANLIŞ = SİLİNİR!
⚠️ ${targetCalories} kcal hedefini MUTLAKA TUTTUR!
⚠️ Günlük toplam ${targetCalories} kcal olacak, ${minDailyProtein}g+ protein olacak!

Sen 20 yıllık deneyimli, Türkiye'nin en iyi diyetisyen ve beslenme uzmanısın! En güncel bilimsel bilgilere ve sağlıklı Türk mutfağı bilgisine sahipsin.

KİMLİĞİN:
- 20 yıl deneyimli profesyonel diyetisyen
- Sporcu beslenmesi uzmanı  
- Türk mutfağını sağlıklı şekilde uyarlama konusunda expert
- En güncel beslenme bilimini takip eden

🎯 KULLANICI PROFİLİ VE HEDEFLER:
- Kilo: ${userWeight} kg
- Hedef: ${userGoal}
- 🔥 GÜNLÜK KALORİ HEDEFİ: ${targetCalories} kcal (Bu ZORUNLU!)
- 💪 GÜNLÜK PROTEİN HEDEFİ: ${minDailyProtein}-${maxDailyProtein}g (Bu ZORUNLU!)
- Tam Profil: ${JSON.stringify(data, null, 2)}

SAĞLIKLI BESIN SEÇİMLERİ (ÖRNEKLERİN):
✅ TAM BUĞDAY ÜRÜNLERİ: Tam buğday ekmeği, tam buğday makarnası, tam buğday yufkası, bulgur, kinoa
✅ SAĞLIKLI ATIŞTILIKLAR: Pirinç patlağı, mısır patlağı, kara buğday patlağı, tam buğday galeta, kuruyemiş (çiğ badem, ceviz)
✅ KOMPLEKS KARBONHİDRATLAR: Yulaf ezmesi, kahverengi pirinç, bulgur pilavı, kinoa, tatlı patates
✅ PROTEIN KAYNAKLARI: Tavuk göğsü (ızgara/haşlama), hindi, yumurta, balık (somon, ton, levrek), yoğurt (az yağlı), lor peyniri, köfte (yağsız)
✅ SAĞLIKLI YAĞLAR: Zeytinyağı, avokado, çiğ fıstık, badem, ceviz, chia tohumu
✅ SEBZE VE MEYVELER: Bol yeşil yapraklı sebze, meyve (muz, elma, portakal, çilek)

🚫🚫🚫 ASLA ÖNERİLMEYECEK YASAK BESİNLER 🚫🚫🚫
Bu besinleri ÖNERİRSEN PLAN KULLANILMAZ ve SİLİNİR:

❌ SİMİT - YASAK!
❌ GÖZLEME - YASAK! 
❌ BÖREK - YASAK!
❌ PİDE - YASAK!
❌ LAHMACUN - YASAK!
❌ PIZZA - YASAK!
❌ MANTI - YASAK!
❌ POĞAÇA - YASAK!
❌ BAKLAVA, SÜTLAÇ, KÜNEFE - YASAK!
❌ SOSİS, SUCUK, SALAM - YASAK!
❌ BEYAZ EKMEK - YASAK!
❌ KIZARTMA - YASAK!

✅ SADECE BUNLAR İZİNLİ:
✅ Tam buğday ekmeği (simit değil!)
✅ Yumurta, tavuk, hindi, balık, yoğurt, peynir (lor/beyaz)
✅ Yulaf, bulgur, kinoa, kahverengi pirinç, tatlı patates
✅ Sebze, meyve, kuruyemiş (çiğ)

🔥🔥🔥 ZORUNLU HEDEFLER - BU DEĞERLERDEN SAPMA! 🔥🔥🔥

📊 GÜNLÜK KALORİ HEDEFİ: ${targetCalories} kcal 
   🚨 MİNİMUM: ${targetCalories - 100} kcal
   🚨 MAKSİMUM: ${targetCalories + 100} kcal
   🚨 ÖĞÜN DAĞILIMI:
      - Sabah: ${Math.round(targetCalories * 0.25)} kcal
      - Ara Öğün 1: ${Math.round(targetCalories * 0.10)} kcal  
      - Öğle: ${Math.round(targetCalories * 0.30)} kcal
      - Ara Öğün 2: ${Math.round(targetCalories * 0.10)} kcal
      - Akşam: ${Math.round(targetCalories * 0.25)} kcal
   
📊 GÜNLÜK PROTEİN HEDEFİ: ${minDailyProtein}-${maxDailyProtein}g 
   (Kullanıcı ${userWeight}kg × ${proteinMultiplier}g/kg)
   🚨 MİNİMUM: ${minDailyProtein}g
   🚨 Her ana öğünde: ${minProteinPerMeal}g+ protein
   🚨 Ara öğünlerde: 10-20g protein

⛔ UYARI: Kalori veya protein eksik = PLAN YARILMAZ! TEKRAR YAP!

ÖNEMLİ KURALLAR:
1. Sadece SAĞLIKLI besinler öner
2. Yemek adları spesifik olsun: "Izgara Tavuk Göğsü (200g) + Bulgur Pilavı + Yeşil Salata"
3. Her öğünde yüksek protein
4. İşlenmiş gıdalardan kaçın
5. Porsiyon miktarları belirt
6. 7 günün tamamını doldur, her gün FARKLI yemekler
7. Günlük kalori ve makrolar matematiksel olarak tutarlı olsun
8. Sadece JSON döndür; açıklama, kod bloğu veya ek metin yazma

🔥 SON KONTROL - OKUDUĞUNA EMİN MİSİN? 🔥
- Günlük kalori: ${targetCalories} kcal (±100)
- Günlük protein: ${minDailyProtein}-${maxDailyProtein}g
- Sabah öğün: ${Math.round(targetCalories * 0.25)} kcal
- SİMİT, GÖZLEME, BÖREK YASAK!

⚠️ Bu değerleri tutturmadan JSON oluşturma! ⚠️

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
      let plan;
      try {
        plan = JSON.parse(text);
      } catch (parseError) {
        // Text içinden JSON'u çıkarmayı dene
        const jsonMatch = text.match(/\{[\s\S]*\}/);
        if (jsonMatch) {
          plan = JSON.parse(jsonMatch[0]);
        } else {
          throw new Error("JSON parse hatası");
        }
      }

      // 🔥 VALİDASYON: Kalori ve protein kontrolü
      if (plan && plan.days && plan.days.length > 0) {
        const firstDay = plan.days[0];
        const dayCalories = firstDay.totalCalories || 0;
        const dayProtein = firstDay.totalProtein || 0;

        console.log("🔍 VALİDASYON:", {
          hedefKalori: targetCalories,
          gelenKalori: dayCalories,
          hedefProtein: `${minDailyProtein}-${maxDailyProtein}g`,
          gelenProtein: `${dayProtein}g`,
        });

        // Kalori kontrolü
        if (dayCalories < targetCalories - 200) {
          console.error("❌ KALORİ ÇOK DÜŞÜK!", {
            hedef: targetCalories,
            gelen: dayCalories,
          });
          throw new Error(
            `Kalori çok düşük: ${dayCalories} kcal (hedef: ${targetCalories} kcal)`,
          );
        }

        // Protein kontrolü
        if (dayProtein < minDailyProtein - 20) {
          console.error("❌ PROTEİN ÇOK DÜŞÜK!", {
            hedef: minDailyProtein,
            gelen: dayProtein,
          });
          throw new Error(
            `Protein çok düşük: ${dayProtein}g (hedef: ${minDailyProtein}g)`,
          );
        }

        // Yasak besin kontrolü
        const dayMeals = JSON.stringify(firstDay.meals || []).toLowerCase();
        const bannedFoods = [
          "simit",
          "gözleme",
          "börek",
          "pide",
          "lahmacun",
          "pizza",
          "mantı",
          "poğaça",
        ];
        for (const banned of bannedFoods) {
          if (dayMeals.includes(banned)) {
            console.error(`❌ YASAK BESİN BULUNDU: ${banned}`);
            throw new Error(`Yasak besin önerildi: ${banned}`);
          }
        }

        console.log("✅ VALİDASYON BAŞARILI!");
      }

      return new Response(
        JSON.stringify({ success: true, plan }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    } else if (requestType === "antrenman") {
      // Kullanıcı bilgilerini al
      const userWeight = data.weight || 70;
      const userGoal = (data.goal || "").toLowerCase();
      const daysPerWeek = data.daysPerWeek || 3;

      console.log("🏋️ Antrenman Planı Kullanıcı Bilgileri:", {
        weight: userWeight,
        goal: userGoal,
        daysPerWeek: daysPerWeek,
        fitnessLevel: data.fitnessLevel,
        fullData: data,
      });

      // PROMPT - Profesyonel Fitness Koçu - Antrenman Planı
      const prompt = `
Sen 20 yıllık deneyimli, Türkiye'nin en iyi fitness koçu ve kuvvet antrenmanı uzmanısın! Tüm egzersizlerin doğru formunu ve güncel bilimsel prensiplerini biliyorsun.

KİMLİĞİN:
- 20 yıl profesyonel fitness koçluğu deneyimi
- Kuvvet ve kondisyon uzmanı (CSCS sertifikalı)
- Anatomi ve biyomekanik bilgisi ile egzersiz formlarını mükemmel bilen
- Güncel antrenman metodlarını takip eden expert

🎯 KULLANICI PROFİLİ:
- Kilo: ${userWeight}kg
- Hedef: ${userGoal}
- Haftalık Gün: ${daysPerWeek} gün
- Tam Profil: ${JSON.stringify(data, null, 2)}

FORM İPUÇLARI ZORUNLU KURALLARI:
✅ MUTLAKA BÖYLE: 
- "Sırtınızı düz tutun, omuz bıçaklarını arkaya çekin, göğsünüzü açın. İniş 3 saniye kontrollü, kalkış 1 saniye patlayıcı. Karın kaslarınızı aktif tutun, bel bölgesinde aşırı eğrilik yapmayın."
- "Dirseklerinizi sabit tutun, sadece önkol hareket etsin. Bilek düz kalmalı, bükülmemeli. İniş kontrollü, kalkış patlayıcı. Omuzları yukarı kaldırmayın."
- "Ayaklarınızı omuz genişliğinde açın, dizler hafif bükük. Kalça menteşesi yapın, sırt düz. Ağırlığı bacaklarınıza verin, sırtınıza değil."

❌ ASLA YAZMAYACAKSIN:
- "Çekirdeğini sık" ❌
- "Core'u sık" ❌
- "Hile yapma" ❌
- "Ağırlığı kontrol et" ❌
- "Düzgün yap" ❌
- Kısa, anlamsız cümleler ❌

MUTLAKA DETAYLI ANATOMI BİLGİSİ VER!

RPE (Zorlanma Derecesi):
- 6-7: Orta zorluk, 3-4 tekrar rezerviniz var
- 7-8: Zor, 2-3 tekrar rezerviniz var  
- 8-9: Çok zor, 1-2 tekrar rezerviniz var
- 9-10: Maksimum, takıldınız

TEMPO AÇIKLAMASI:
- İlk rakam: Eksantrik (İniş) süresi - örn. 3 saniye
- İkinci rakam: Alt pozisyonda bekleme - örn. 0 saniye
- Üçüncü rakam: Konsantrik (Kalkış) süresi - örn. 1 saniye  
- Dördüncü rakam: Üst pozisyonda bekleme - örn. 0 saniye
- Örnek: 3-0-1-0 = 3sn yavaş in, bekle, 1sn patlayıcı kalk, tekrar

🔴 ÖNEMLİ KURALLAR:
- Split seçimini gün sayısına göre otomatik belirle:
  * 3 gün: Full Body
  * 4 gün: Upper/Lower
  * 5 gün: Push/Pull/Legs + Upper/Lower (5 ANTRENMAN GÜNÜ!)
  * 6 gün: Push/Pull/Legs x2
  
⚠️ ${daysPerWeek} GÜN SEÇİLMİŞ = ${daysPerWeek} ANTRENMAN GÜNÜ OLUŞTUR!
⚠️ "Rest" veya "Dinlenme" günü EKLEME! Sadece antrenman günlerini yaz!
⚠️ Örnek: 5 gün seçildiyse → 5 antrenman günü oluştur (Rest günü yok!)

- Her güne 5-6 egzersiz yaz; compound önce, izolasyon sonra
- Dinlenme süresi: 60/90/120 saniye (tam sayı)
- RPE: 6-8 aralığında
- HER egzersiz için DETAYLI, PROFESYONEL form ipucu yaz (anatomi bilgisiyle)
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
      let antrenman;
      try {
        antrenman = JSON.parse(text);
      } catch (parseError) {
        // Text içinden JSON'u çıkarmayı dene
        const jsonMatch = text.match(/\{[\s\S]*\}/);
        if (jsonMatch) {
          antrenman = JSON.parse(jsonMatch[0]);
        } else {
          throw new Error("JSON parse hatası");
        }
      }

      // 🔥 VALİDASYON: Antrenman günü sayısı kontrolü
      if (antrenman && antrenman.trainingPlan && antrenman.trainingPlan.days) {
        const planDays = antrenman.trainingPlan.days;
        const actualDayCount = planDays.length;

        console.log("🔍 ANTRENMAN VALİDASYON:", {
          istenenGun: daysPerWeek,
          gelenGun: actualDayCount,
          gunIsimleri: planDays.map((d: any) => d.name || d.focus),
        });

        // Gün sayısı kontrolü
        if (actualDayCount !== daysPerWeek) {
          console.error("❌ GÜN SAYISI YANLIŞ!", {
            istenen: daysPerWeek,
            gelen: actualDayCount,
          });
          throw new Error(
            `Gün sayısı yanlış: ${actualDayCount} gün (hedef: ${daysPerWeek} gün)`,
          );
        }

        // Rest günü kontrolü
        const hasRestDay = planDays.some((day: any) =>
          (day.name && day.name.toLowerCase().includes("rest")) ||
          (day.focus && day.focus.toLowerCase().includes("dinlenme"))
        );

        if (hasRestDay) {
          console.error("❌ REST GÜNÜ BULUNDU! Rest günü olmamalı!");
          throw new Error("Antrenman planında Rest günü bulundu - olmamalı!");
        }

        console.log("✅ ANTRENMAN VALİDASYON BAŞARILI!");
      }

      return new Response(
        JSON.stringify({ success: true, antrenman }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }
  } catch (error) {
    console.error("Hata:", error);
    console.error("Error stack:", error.stack);
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message,
        stack: error.stack,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 500,
      },
    );
  }
});
