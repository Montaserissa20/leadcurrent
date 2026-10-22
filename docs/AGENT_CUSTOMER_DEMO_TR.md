# Phase 3 kısa sunum — Müşteri bir AI agent olsaydı?

**Durum: 22 Ekim 2026, yerel inceleme dalı `phase3/agent-customer`. GitHub push / Railway deploy yapılmadı. Production kabulü PENDING.** Önceki Phase 1/2 kanıtları korunur. [Teknik rapor ve testler](AGENT_CUSTOMER_PHASE3.md), [ölçülmüş kanıt](evidence/phase3-agent-customer-2026-10-22.json).

## Bir dakikalık açıklama

“LeadCurrent'te müşteri bir AI agent olsaydı, satın alma hedefini alan ayrı bir Python programı Groq ile yapılandırılmış talep hazırlar ve gerçekten Rails API'sine gönderirdi. Workspace'e ait anahtar yalnız talep bırakmaya izin verir. Şirket adı, bütçe ve yetki hâlâ doğrulanmamış iddiadır. İnsan yönetici talebi inceler, isterse Groq'tan yorum alır ve ancak kendi onayıyla normal CRM lead'i oluşturur. İlk temas için 24 saat o anda başlar. Agent satış aşaması değiştiremez, satın alma yapamaz veya onay veremez.”

Genel sohbet ekranından farkı: ayrı çalışan müşteri programı, gerçek HTTP, kalıcı inquiry, tekrar gönderim koruması, workspace izolasyonu ve denetlenebilir insan kararı vardır. Phase 1 satış temsilcisine analiz sağlar; Phase 2 CRM içinde okuma/navigasyon sağlar; Phase 3 dışarıdan gelen alıcı agent'ı kontrollü kabul eder. Rakip sistemlerde bunun bulunmadığı iddia edilmez. Problem kaynağı hocanın sorusu ve kullanıcının brief'idir; müşteri görüşmesi veya ticari tasarruf ölçümü yapılmadı.

## 1. Mevcut yerel uygulamayı hazırlayın

```powershell
Set-Location D:\LeadCurrent
git branch --show-current
powershell -NoProfile -ExecutionPolicy Bypass -File bin/local-postgres.ps1 -Action start
bundle install
npm ci --ignore-scripts
npm run build
bundle exec rails db:migrate
$env:GROQ_API_KEY = [Environment]::GetEnvironmentVariable('GROQ_API_KEY', 'User')
$env:GROQ_MODEL = 'openai/gpt-oss-20b'
bundle exec rails server -b 127.0.0.1 -p 3100
```

Mevcut 3100 sunucusu çalışıyorsa ikinci sunucu başlatmayın. PostgreSQL verisini reset/drop/seed etmeyin. Migration yalnız iki ek tablo ve tenant referanslarını koruyan index/constraint ekler. Groq anahtarını yazdırmayın; Rails başlamadan önce süreçte bulunmalıdır. Yerel Windows kullanıcı değişkeni Railway'e otomatik taşınmaz.

Yönetici olarak `http://127.0.0.1:3100` adresinde giriş yapın. **Agent Inquiries → Manage agent credentials** ekranında kısa ömürlü demo credential üretin. Anahtar yalnız bir kere görünür; ekran görüntüsü veya projeye kayıt almayın. Gerçek şirket/veri kullanmayın.

## 2. Ayrı PowerShell'de dış agent

Aşağıdaki giriş komutu token değerini shell history'ye yazmadan süreç değişkenine alır:

```powershell
Set-Location D:\LeadCurrent
$credentialInput = Read-Host 'Agent credential (hidden)' -AsSecureString
$credentialPtr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($credentialInput)
try {
  $env:LEADCURRENT_AGENT_TOKEN = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($credentialPtr)
} finally {
  [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($credentialPtr)
}
$env:LEADCURRENT_BASE_URL = 'http://127.0.0.1:3100'
$env:GROQ_API_KEY = [Environment]::GetEnvironmentVariable('GROQ_API_KEY', 'User')
```

**Mode A — LLM olmadan gerçek API:**

```powershell
python examples/purchasing_agent/client.py --mode deterministic --idempotency-key fictional-mode-a-0001
python examples/purchasing_agent/client.py --mode deterministic --idempotency-key fictional-mode-a-0001
```

İlk yanıtta HTTP 201/pending_review/unverified; ikinci yanıtta aynı inquiry_id ile HTTP 200/replayed:true gösterin. Aynı anahtarla farklı içerik 409 olur. JSON çıktısında gerçek talep ve receipt vardır; Authorization değeri gösterilmez. Henüz lead oluşmadığını anlatın.

**Mode B — gerçek Groq alıcı agent:**

```powershell
python examples/purchasing_agent/client.py --mode ai --goal 'We are a fictional startup requesting pricing for 50 software subscriptions with team management and reporting. Proposed budget is 10000 USD, not approved. Desired timeline is within 30 days. Request a quotation, not a purchase.' --company 'Fictional Meridian Procurement' --contact-name 'Fictional Alex Buyer' --contact-email buyer@example.test --idempotency-key fictional-mode-b-0001
```

Bu komut gerçek model kullanır; başarılı cevabı uydurmaz. Model ek bilgi isterse istemci gönderim yapmadan durur. Kota/timeout hatasını başarı diye sunmayın. Yeni demo için yeni idempotency key seçin; model çıktısı değişebileceği için aynı key ile AI komutunu tekrar çalıştırmak 409 oluşturabilir. Modelin URL/shell/dosya/ödeme aracı yoktur. Maliyet ve günlük kota için gereksiz tekrar yapmayın.

## 3. İnsan kararını gösterin

1. Inbox'ı yenileyin; **External AI Agent**, **Identity: Unverified**, pending durumunu gösterin. Talep ayrı tabloda, normal lead listesinde değildir.
2. Detayı açın: şirket/bütçe birer iddia, original JSON ve geliş zamanı görünür. **Analyze with AI** yalnız bir defa seçin. Yorum ve kaynak alanları ayrı; bu işlem pending durumunu değiştirmez. Groq yoksa elle inceleme sürer.
3. İletişim adı/e-posta ve aynı workspace'te owner seçimini kontrol edin. **Accept Inquiry** seçin. Eksik bilgi varsa uydurmayın; **Request more information** kullanın. Bu buton e-posta göndermez; yeni tam inquiry gerekir.
4. Yeni lead'de source inquiry linkini, owner/workspace'i, New durumunu ve yaratılıştan başlayan 24 saatlik deadline'ı gösterin. Agent mesajı completed contact değildir; fırsat/Won/satın alma oluşmaz.
5. Phase 1'de **Analyze customer** çalıştırın. Phase 2 Copilot'a “Which leads do we have?” sorun; yeni lead yetkili kapsamda bulunur. Eski güvenli navigasyon/not hazırlama yetenekleri regresyon testleriyle korunur. Yeni credential/review ekranları Page Agent'a açık değildir.
6. Sonunda credential'ı **Revoke** edin; demo terminalindeki değişkenleri temizleyin. Gerçek müşteri kayıtlarını topluca silmeyin.

```powershell
Remove-Item Env:LEADCURRENT_AGENT_TOKEN -ErrorAction SilentlyContinue
Remove-Item Env:GROQ_API_KEY -ErrorAction SilentlyContinue
```

## Gerçekte ne doğrulandı?

22 Ekim gerçek yerel demoda ayrı Python alıcısı → gerçek HTTP → inbox → gerçek Groq qualification → insan kabulü → gerçek Phase 1 analizi → gerçek Phase 2 sorgusu **PASS**: 1 test/48 assertion. Dört gerçek completion, **4.808 ölçülmüş token**; finansal ücret ve geliştirme saati ölçülmedi. İlk denemede gerçek buyer isteği 403 verdi; kayıt korundu. Doğru uygulama User-Agent eklendikten sonraki tam tur geçti; 429 görülmedi. Gerçek ekran görüntüleri teknik raporda bulunur; token ekranı kaydedilmedi. Bu verifier kurgusal test transaction'ını geri alır; yukarıdaki elle demo ise yerelde gerçek kurgusal kayıt bırakır.

Son otomatik sonuç: **193 Rails+browser testi / 2.544 assertion**, ayrıca **7 Python testi**, hepsi PASS. Docker'ın izole PostgreSQL ile production-start kontrolü geçti. Bunlar Railway deploy veya production kabulü değildir. Çoklu replica için ortak rate limiter, yayın öncesi kullanıcı onayı, exact-commit GitHub CI ve mevcut Railway servisinde kontrollü production testi hâlâ gereklidir.
