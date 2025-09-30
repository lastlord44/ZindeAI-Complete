# 🔒 Güvenlik Rehberi

## API Key Yönetimi

### ⚠️ ÖNEMLİ: API Key'ler GitHub'a Push Edilmez!

Bu proje güvenlik için API key'leri database'de saklar. Hardcoded key'ler yasaktır.

### Kurulum

1. **Environment Variables:**
   ```bash
   cp env.example .env
   # .env dosyasını düzenle
   ```

2. **Database'de API Key Ekle:**
   ```sql
   INSERT INTO api_keys (name, value, description) VALUES 
   ('gemini_api_key', 'YOUR_REAL_GEMINI_API_KEY', 'Gemini AI API Key');
   ```

3. **Supabase Environment Variables:**
   - `SUPABASE_URL`: Supabase proje URL'i
   - `SUPABASE_ANON_KEY`: Supabase anon key
   - `SUPABASE_SERVICE_ROLE_KEY`: Supabase service role key

### Güvenlik Önlemleri

- ✅ API key'ler database'de şifrelenmiş saklanır
- ✅ RLS (Row Level Security) etkin
- ✅ Sadece service role API key'lere erişebilir
- ✅ Hardcoded key'ler kaldırıldı
- ✅ GitHub'a sensitive data push edilmez

### API Key Ekleme

Production'da gerçek API key'leri eklemek için:

```sql
UPDATE api_keys 
SET value = 'YOUR_REAL_GEMINI_API_KEY' 
WHERE name = 'gemini_api_key';
```

### Test Modu

API key yoksa sistem otomatik olarak test planları oluşturur.














