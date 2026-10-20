# LeadCurrent AI Sales Assistant — Phase 1

20 Ekim 2026. İlk yerel doğrulamadan sonra kullanıcı GitHub push ve mevcut Railway dağıtımının kontrolüne açık onay verdi. Önceki ödevin canlı uygulama kanıtları bu özelliğin üretimde çalıştığını göstermez. Özgün görev ve güncel teslim/doğrulama durumu: [CHALLENGE_LOG.md](../CHALLENGE_LOG.md).

## Kullanım ve gerçek AI akışı

Mevcut lead veya opportunity sayfasındaki LeadCurrent AI paneli dört işlem sunar: müşteri analizi, mevcut Next Best Action açıklaması, aktivite özeti ve takip mesajı taslağı. İsteğe bağlı soru 600 karakterdir. Sonuçlar kaynak CRM bilgileri, riskler, sonraki adım, açıklama ve varsayımları ayırır. Copy draft yalnızca panoya kopyalar; mesaj göndermez.

Tarayıcı oturum ve CSRF korumasıyla Rails'e POST yapar. `Ai::AdviceController` URL'deki kaydı kullanıcının workspace kapsamında bulur. `Ai::CustomerContext` PostgreSQL'den sınırlı veri ve mevcut `NextBestAction` sonucunu okur. `Ai::SalesAdvisor`, sabit sistem politikası ile JSON olarak kodlanmış güvenilmeyen müşteri verisini ayrı mesajlarda gönderir. `Ai::GroqClient`, gerçek Groq HTTPS Chat Completions API'sini çağırır. Yanıt şekli ve kaynak kimlikleri doğrulanır; ERB metni escape ederek Turbo Frame içinde gösterir. Hatalarda aynı müşteri sayfasında anlaşılır mesaj görünür; sahte AI yanıtı kullanılmaz.

AI kendi öncelik puanını hesaplamaz. Resmi öncelik/neden doğrudan Rails'in deterministik sonucundan ayrı gösterilir. 24 saat ilk temas, 4 saat uyarı, 72 saat hareketsizlik ve tüm aşama geçişleri değişmedi. Aynı workspace'teki okunabilir meslektaş kayıtları mevcut okuma yetkisiyle erişilebilir; bu kullanıcı için uygun NBA yoksa puan uydurulmaz.

## Yerel çalıştırma

Mevcut PostgreSQL kümesini başlatın; veritabanını resetlemeyin. Yeni gem, migration veya seed gerekmez. Windows kullanıcı değişkenindeki anahtarı yalnızca sunucu sürecine alın:

```powershell
Set-Location D:\LeadCurrent
powershell -ExecutionPolicy Bypass -File bin/local-postgres.ps1 -Action start
$env:GROQ_API_KEY = [Environment]::GetEnvironmentVariable('GROQ_API_KEY', 'User')
$env:GROQ_MODEL = 'openai/gpt-oss-20b'
bundle exec rails server -b 127.0.0.1 -p 3100
```

http://127.0.0.1:3100 adresinde mevcut hesabınızla giriş yapıp bir müşteri açın ve Analyze customer seçin. Anahtarın değerini yazdırmayın. Rails `.env.example` dosyasını kendiliğinden yüklemez. Anahtar eksikse CRM kullanılabilir, AI paneli yapılandırma hatası gösterir.

## Sağlayıcı ve sınırlar

20 Ekim 2026 tarihinde [resmi API referansı](https://console.groq.com/docs/api-reference), [model sayfası](https://console.groq.com/docs/model/openai/gpt-oss-20b), [model listesi](https://console.groq.com/docs/models), [rate limits](https://console.groq.com/docs/rate-limits) ve [structured outputs](https://console.groq.com/docs/structured-outputs) kontrol edildi. Gerçek yerel doğrulamada kullanılan model `openai/gpt-oss-20b`; `GROQ_MODEL` ile değiştirilebilir. Llama 3.1 8B model listesinde Enterprise olarak belirtildiği için varsayılan seçilmedi. Başka modellerin JSON-object/araç kapatma desteği ayrıca doğrulanmalıdır.

İstek: sabit `https://api.groq.com/openai/v1/chat/completions`, `max_completion_tokens=1200`, `tool_choice=none`, GPT-OSS için düşük reasoning effort. GPT-OSS 20b/120b için strict JSON schema kullanılır: gerçek kaynak kimlikleri enum ile sınırlandırılır ve draft dışındaki modlarda draft alanı boş olmalıdır. Diğer yapılandırılabilir modeller JSON-object kullanır; bu mod şema garantisi vermez. Her durumda Rails yerel şema/boyut/kaynak kontrolü yapar; tamamlanmamış veya geçersiz yanıt reddedilir. Otomatik tekrar deneme yoktur. Toplam mesaj içeriği en çok 6.000 byte, sağlayıcı yanıtı 32KB; bağlantı/okuma/yazma süreleri 3/15/5 saniye, toplam süre 25 saniyedir.

Bağlam: şirket adı/sektörü, seçili kaydın durum/başlık/tarih/deal bilgileri, en çok 500-byte lead notu, son 6 aktiviteden 200-byte alıntılar ve 5 açık görevden 100-byte başlıklar. Opportunity için yalnızca aynı tenant/şirket/kişiye bağlı özgün lead geçmişi eklenir. Tüm müşteri geçmişi gönderilmez. Kayıtlı deal değeri onaylanmış bütçe sayılmaz.

Uygulama her hesapta bir eşzamanlı istek ve dakikada 5 hesap / 10 workspace / 20 sağlayıcı isteği sınırı uygular. Sayaçlar süreç belleğindedir, yeniden başlatmada sıfırlanır. Çoklu worker/instance öncesinde ortak limiter gerekir. Groq ücretsiz plan belgesinde bu model için 30 RPM, 1.000 RPD, 8.000 TPM, 200.000 TPD belirtilir; hesap limitleri ve diğer uygulamaların tüketimi sonucu 429 gelebilir. Uygulamanın istek sayacı sağlayıcı token kotasını garanti etmez.

## Güvenlik ve mahremiyet

- `GROQ_API_KEY` yalnızca sunucudadır; frontend, prompt, kaynak kod veya hata mesajında bulunmaz. Soru parametreleri filtrelenir; sağlayıcı gövdeleri loglanmaz. Metrik bildirimi yalnızca model ve sayısal token kullanımını içerir.
- Login, zorunlu parola değişikliği, CSRF ve tenant okuma kapsamı korunur. Gönderilen body içindeki kayıt kimliği/bağlam URL kaydını değiştiremez. Cross-workspace erişim sağlayıcı çağrısından önce reddedilir.
- Yapılandırılmış kişi e-posta/telefon ve aktör bilgileri alınmaz. Serbest metinde bilinen sırlar, e-posta ve bazı telefon biçimleri en iyi çabayla redakte edilir. Bu tam anonimleştirme değildir: müşteri notları kişisel/ticari bilgi içerebilir ve sınırlı metin Groq'a gönderilir. Gerçek müşteri verisi için kuruluşun sağlayıcı/veri işleme politikasını değerlendirin.
- Notlar ve soru güvenilmeyen veri olarak ayrılır; modelin araç, kod yürütme veya yazma yetkisi yoktur. Yanıt plain text olarak escape edilir; CSP gevşetilmez. Prompt injection ve hallucination tamamen ortadan kalkmaz; her öneri/taslak insan tarafından gözden geçirilmelidir.
- AI hiçbir CRM kaydı, görev, aşama, deadline veya audit satırı yazmaz; e-posta göndermez ve konuşma geçmişini veritabanında saklamaz. Turbo önbelleğine alınmadan soru/yanıt temizlenir, yanıtlar `no-store` kullanır.

## Otomatik ve gerçek doğrulama ayrımı

Normal testlerde yalnızca HTTP transport sahtedir; gerçek controller, PostgreSQL yetkilendirme/bağlam, ERB, Turbo ve tarayıcı akışları çalışır. Gerçek API anahtarı veya ağ gerekmez. Coverage: tenant kaçışı, CSRF, roller/okunabilir meslektaş kaydı, eksik anahtar, 429, timeout, bozuk yanıt, prompt/veri ayrımı, kaynak kimliği, XSS, redaksiyon, değişmeyen veritabanı, duplicate prevention, copy, light/dark ve 390px mobil.

```powershell
bundle exec rails test
bundle exec rails test:system
bundle exec rails zeitwerk:check
bundle exec brakeman --no-pager --quiet
```

Gerçek API testi normal suite ve CI'dan ayrıdır. Yalnızca yerel test veritabanında kurgusal bir müşteri oluşturur ve transaction sonunda geri alır. Dört gerçek tarayıcı isteği arasında ücretsiz kota için bekler. Production/CI'da çalışmayı reddeder. Sağlayıcı tokenları, sonuç ve değişmeyen CRM kontrolü ignored `.local/ai-live-verification.json` dosyasına yazılır; ekran görüntüsü `.local/ai-preview/analysis-live-desktop.png` altındadır. Bunlar üretim ekran görüntüsü değildir.

```powershell
$env:RAILS_ENV = 'test'
$env:LEADCURRENT_LIVE_AI = '1'
bundle exec ruby script/verify_groq.rb
Remove-Item Env:LEADCURRENT_LIVE_AI
Remove-Item Env:RAILS_ENV
```

Gerçek sonuç/count ve başarısız denemeler [challenge log](../CHALLENGE_LOG.md) içinde ayrı kaydedilir. Mock fixture'daki token sayıları gerçek tüketim değildir. İnsan emeği, coding-agent tokenları ve ödenen toplam ücret ölçülmedi; fiyat listesi gerçek fatura değildir.

## Üretim öncesi

Bu phase için açık kullanıcı onayı olmadan GitHub'a push veya Railway'e deploy yapılmaz. Onaydan sonra gerçek değişiklik commit'i için LeadCurrent CI doğrulanmalı; Railway web service runtime Variables içine `GROQ_API_KEY` ve isteğe bağlı `GROQ_MODEL=openai/gpt-oss-20b` eklenmelidir. Windows kullanıcı ortamı Railway'e aktarılmaz. Mevcut `DATABASE_URL`, `SECRET_KEY_BASE` ve DB ayarları değiştirilmez; anahtar build argümanı değildir.

Worker sayısı, ortak limiter ihtiyacı, sağlayıcı kotası ve müşteri verisi paylaşım politikası gözden geçirilmeli. Sonra yetkili canlı kullanıcıyla müşteri analizi, diğer üç işlem, tenant/CSRF sınırları ve eski satış akışı gerçek Railway URL'sinde doğrulanmalı. Yerel test, asset build veya GitHub push üretim başarısı kanıtı değildir.
