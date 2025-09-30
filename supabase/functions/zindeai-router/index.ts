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
# GÖREV TANIMI
Sen, Türkiye'nin en iyi diyetisyenlerinden ve spor koçlarından oluşan bir ekibin beynisin. Adın ZindeAI. Görevin, SANA SUNULAN KULLANICI BİLGİLERİNE VE KURALLARA %100 SADIK KALARAK, JSON formatında bir beslenme veya antrenman planı oluşturmaktır. YARATICILIK KULLANMA. SADECE KURALLARI UYGULA.

# KURAL 1: MATEMATİKSEL ZORUNLULUK (EN ÖNEMLİ KURAL)
BU BİR TAVSİYE DEĞİL, MATEMATİKSEL BİR EMİRDİR. OLUŞTURULACAK BESLENME PLANININ TOPLAM KALORİSİ, KULLANICININ HEDEFİ OLAN \`${targetCalories} kcal\` DEĞERİNE EŞİT OLMALIDIR. MAKSİMUM SAPMA PAYI SADECE +/- 50 KCAL'DİR. AYNI ŞEKİLDE, TOPLAM PROTEİN MİKTARI, HEDEF OLAN \`${minDailyProtein}g\` DEĞERİNE EŞİT OLMALIDIR. MAKSİMUM SAPMA PAYI SADECE +/- 5 GRAMDIR. BU KURALA UYMAYAN BİR PLAN KESİNLİKLE KABUL EDİLEMEZ VE OLUŞTURULMAMALIDIR.

# KURAL 2: YASAKLI GIDALAR LİSTESİ (DOKUNULMAZ LİSTE)
AŞAĞIDAKİ LİSTEDE YER ALAN HİÇBİR GIDA, MALZEME VEYA TARİF, PLANIN HİÇBİR YERİNDE KESİNLİKLE KULLANILAMAZ:
- Simit, poğaça, açma, börek, gözleme gibi tüm pastane ürünleri.
- Beyaz undan yapılmış ekmek, makarna, erişte.
- Şekerli tüm içecekler (kola, gazoz, hazır meyve suları).
- İşlenmiş et ürünleri (salam, sosis, sucuk).
- Cips, çikolata, gofret gibi tüm paketli abur cuburlar.
- Pizza, lahmacun gibi hamur işi ağırlıklı fast-food ürünleri.
- Kızartmalar.

# KURAL 3: SAĞLIKLI BESLENME PRENSİPLERİ
- Plan, Türk mutfağına uygun, bulunabilir ve mevsiminde malzemelerden oluşmalıdır.
- Her öğün dengeli makrolar içermelidir (protein, sağlıklı karbonhidrat, sağlıklı yağ).
- Ara öğünler basit ve sağlıklı olmalıdır (meyve, kuruyemiş, yoğurt gibi).
- Tarifler net olmalı: gramaj, pişirme yöntemi (haşlama, fırın, ızgara) ve tahmini süre belirtilmelidir.
- Sütlaç gibi şekerli ve besin değeri düşük tatlılar önerilmemelidir.

# KULLANICI BİLGİLERİ
- Yaş: ${data.age || 'Belirtilmemiş'}
- Boy: ${data.height_cm || 'Belirtilmemiş'} cm
- Kilo: ${userWeight} kg
- Cinsiyet: ${data.sex || 'Belirtilmemiş'}
- Fitness Seviyesi: ${data.activity_level || 'Belirtilmemiş'}
- Ana Hedef: ${userGoal}
- Haftalık Antrenman Sıklığı: ${data.daysOfWeek || 7} gün
- Beslenme Tercihi: ${data.diet || 'balanced'}
- Günlük Kalori Hedefi: ${targetCalories} kcal (ZORUNLU!)
- Günlük Protein Hedefi: ${minDailyProtein}g (ZORUNLU!)

# ÇIKTI FORMATI (ZORUNLU)
Çıktı, sadece ve sadece aşağıda belirtilen yapıya sahip, yorum satırı içermeyen, geçerli bir JSON objesi olmalıdır. Başka hiçbir metin, açıklama veya selamlama ekleme.

\`\`\`json
{
  "planTitle": "Kişiselleştirilmiş Beslenme Planı",
  "totalDays": 7,
  "dailyCalorieGoal": ${targetCalories},
  "dailyProteinGoal": ${minDailyProtein},
  "days": [
    {
      "day": 1,
      "dayName": "Pazartesi",
      "meals": [
        {
          "mealName": "Kahvaltı",
          "time": "08:00",
          "totalCalories": "INTEGER_VALUE",
          "totalProtein": "INTEGER_VALUE",
          "recipeName": "Yulaf Lapası",
          "ingredients": [
            "50g yulaf ezmesi",
            "200ml süt",
            "1 adet muz",
            "10 adet badem"
          ],
          "instructions": "Tüm malzemeleri karıştırıp pişirin.",
          "isConsumed": false
        }
      ],
      "dailyTotals": {
        "calories": "INTEGER_VALUE",
        "protein": "INTEGER_VALUE",
        "carbs": "INTEGER_VALUE",
        "fat": "INTEGER_VALUE"
      }
    }
  ]
}
\`\`\`

# SON KONTROL
JSON çıktısını oluşturmadan önce, KURAL 1'de belirtilen kalori ve protein hedeflerini tutturup tutturmadığını bir kez daha kontrol et. Eğer tutmuyorsa, planı revize et ve hedeflere uygun hale getir. SADECE hedeflere uygun planı JSON olarak döndür.
`;

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
