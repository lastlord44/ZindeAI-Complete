import { create } from "https://deno.land/x/djwt@v2.9.1/mod.ts";

// 1. ADIM: Supabase'den kopyaladığın JWT_SECRET'ı buraya yapıştır
const jwtSecret = "dIkO5x+UGUFt2c1TSXcnUCqdqBkzULXEtyVkFKqO0SQiF6FLzkXzwxIQgqu+PPudD3MiehFPc08nmVz4NZKjQw==";

// 2. ADIM: Payload verileri (bunlar standarttır, değiştirme)
const payload = {
  iss: "supabase",
  ref: "uhlbpbwgvnvasxlvcohr", // Senin proje referansın
  role: "anon",
  exp: 1983888600, // Uzak bir gelecek tarihi
};

// Anahtarı oluştur
async function generateAnonKey() {
  const header = {
    alg: "HS256",
    typ: "JWT",
  };

  // CryptoKey'i oluştur
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(jwtSecret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign", "verify"],
  );

  const jwt = await create(header, payload, key);

  console.log("\n✅ YENİ ve GEÇERLİ anon key'in aşağıdadır:\n");
  console.log(jwt);
  console.log("\nBu anahtarı kopyalayıp test script'inde kullanabilirsin.");
}

generateAnonKey();













