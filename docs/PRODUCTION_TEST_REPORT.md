# Railway üretim test raporu

## Kimlik, zaman ve kapsam

- Canlı URL: https://leadcurrent-production.up.railway.app
- Tarih: **16 Ekim 2026**, Europe/Istanbul (UTC+03). Son tam browser turu: **16.10.2026 17:21:21–16.10.2026 17:24:17**. HTTP kontrolü: **16.10.2026 17:22:33**.
- Başlangıç kaynak commit'i: `19e5203aec5fb8f44bfa6683a9706b493ff58c4c`. CSP düzeltmesi ve son yerel testlerin kaynak referansı: [217c3bf](https://github.com/Montaserissa20/leadcurrent/commit/217c3bfe2115f14530c86ec290ef493589d55237).
- Railway durumu: **PASS — gerçek HTTPS, bağlı DB ve canlı uçtan uca akış çalışıyor**. CSP düzeltmesinin canlı davranışı **16.10.2026 17:20:46** itibarıyla görüldü; fresh browser tekrar kontrolü **16.10.2026 17:22:33** geçti. Railway paneli/API erişimi olmadığından deployment ID ve çalışan uzak Git SHA bağımsız doğrulanamadı; yukarıdaki SHA incelenen/test edilen kaynak referansıdır.
- Yöntem: doğrudan HTTPS/curl/Node istekleri ve gerçek headless Microsoft Edge/Capybara; localhost üretim yerine kullanılmadı. Web okuma aracı erişemedi, doğrudan ağ ve browser erişimi çalıştı.
- Yalnız yeni, kurgusal QA workspace/kayıtları kullanıldı. Ön denemeler dahil 7 QA workspace oluşturuldu; hiçbir mevcut müşteri/demo kaydı değiştirilmedi, hiçbir üretim kaydı silinmedi. Parolalar yalnız süreç belleğinde kaldı. DB bağlantısı/shell, ortam değişikliği, reset, credential rotasyonu veya production time travel yapılmadı.

Kanıt: [redakte edilmiş HTTP/browser sonuçları](evidence/production-2026-10-16.json). Bu dosya gerçek zaman damgalarını, vaka sonuçlarını ve yalnız güvenli metadata'yı içerir; parola, e-posta, cookie/nonce değeri, token, request body ve production screenshot içermez.

## HTTP ve varlık kontrolleri

| Kontrol | Beklenen | Gözlenen | Durum |
|---|---|---|---|
| Genel HTTPS / | Auth girişine yönlenme | 302 → /login; son login sayfası 200 | PASS |
| /up | DB sorgusu başarılı | 200; status=ok, database=connected; [HealthController](../app/controllers/health_controller.rb) gerçekten SELECT 1 çalıştırır | PASS |
| /login, /signup | Form sayfaları 200 | İkisi de 200; gerçek browser signup/login/logout geçti | PASS |
| Anonim korumalı sayfalar | Login'e yönlendirme | /leads, /opportunities, /tasks, /analytics, /pipeline, /activity, /settings: 302 → /login | PASS |
| CSS / JavaScript | 200 ve doğru content type | 2 stylesheet + 7 JavaScript/importmap modülü: 9/9 HTTP 200 | PASS |
| Session cookie | Secure, HttpOnly, SameSite=Lax | Değer gösterilmeden flag'ler doğrulandı; refresh/login kalıcılığı ayrıca test edildi | PASS |
| HTTP 500 | Normal akışta bulunmaması | Son browser turunda 542 aynı-origin response izlendi, 500/5xx sayısı 0; capture hatası yok | PASS |
| CSP düzeltmesi | Dolu ve eşleşen script/style nonce; unsafe-inline yok | Header/HTML eşleşti; fresh anonymous Turbo gezinmesinde 0 CSP ihlali ve 0 severe console entry | PASS |

Browser turundaki toplam severe console entry sayısı 4; bu sayaç kasıtlı 404/422 yetki retlerinin browser loglarını da kapsar. Bu toplam, tüm uygulama konsolunun kusursuz olduğu iddiası olarak sunulmaz. Ayrı temiz anonymous CSP turunda severe sayısı sıfırdır. Server loglarının tamamına erişilmedi; 500 yokluğu yalnız gözlenen isteklere aittir.

## Üretim vaka sonuçları

| ID | Beklenen test | Gerçek gözlem | Sonuç | Europe/Istanbul saati |
|---|---|---|---|---|
| P01 | Login/signup gerçek browser'da yüklenir; korumalı sayfa login'e yönlendirir | Korunan lead sayfası login’e döndü; login/signup formları yüklendi. | PASS | 16.10.2026 17:21:23 |
| P02 | Ayrı QA organizasyonu oluşturulur; başlangıç metrikleri sıfır | Yeni izole A workspace, başlangıçta 0 lead. | PASS | 16.10.2026 17:21:25 |
| P03 | Lead + şirket/kişi oluşturulur ve listede görünür | Yeni kurgusal lead/şirket/kişi kayıtları ve lead listesi doğrulandı. | PASS | 16.10.2026 17:21:28 |
| P04 | Yeni lead NBA'da açıklama ve doğrudan contact formuyla görünür | Yeni lead önerisi ve first-contact gerekçesi/formu görüldü. | PASS | 16.10.2026 17:21:28 |
| P05 | Dashboard'da tek submit tamamlanmış temas kaydeder ve öneriyi kaldırır | Dashboard contact submit sonrası öneri kalktı; profilde Contacted ve görüşme kaydı görüldü. | PASS | 16.10.2026 17:21:30 |
| P06 | Lead qualified olur; değer/tarih ile tek fırsata dönüştürülür | Qualified → USD 12.345 değerli Qualification opportunity; gelecekte kapanış tarihi seçildi. | PASS | 16.10.2026 17:21:33 |
| P07 | Customer 360 eski lead, kişi/şirket ve contact geçmişini birleştirir | Kişi/şirket, eski lead bağlantısı ve onun contact geçmişi fırsat profilinde görüldü. | PASS | 16.10.2026 17:21:34 |
| P08 | Fırsat Proposal → Negotiation → Won; kapanış kalıcı | Proposal → Negotiation → Won notice/status ve kapalı kayıt açıklaması görüldü. | PASS | 16.10.2026 17:21:37 |
| P09 | Dashboard 1 won/$12,345; analytics %100 conversion ve 0 aktif gösterir | Won 1 / $12.345, aktif 0; conversion %100. | PASS | 16.10.2026 17:21:38 |
| P10 | Refresh, logout ve tekrar login sonrası Won/değer korunur | Refresh ve logout/login sonrası aynı fırsat Won / $12.345 kaldı; logout sonrası korunan kayıt login’e yönlendi. | PASS | 16.10.2026 17:21:42 |
| P11 | Görev oluşturma, düzenleme ve tamamlama çalışır; ilk teması karşılamaz | Görev create/edit/complete geçti; lead New ve ilk temas bekliyor olarak kaldı. | PASS | 16.10.2026 17:21:48 |
| P12 | Not ve görüşme yöntemi activity filtrelerinde görünür | Not kaydedildi; note+arama filtresi yalnız eşleşen notu gösterdi. | PASS | 16.10.2026 17:21:49 |
| P13 | USD Won ve EUR aktif tutarları ayrı hesaplanır; doğru conversion oranı | Aktif pipeline €2.345, kazanılan $12.345 ayrı; 2 converted / 3 lead = %66,7. | PASS | 16.10.2026 17:21:56 |
| P14 | Lead/opportunity filtreleri ve pipeline doğru QA kayıtlarını gösterir | New/active filtreleri ve Won/Qualification pipeline sütunları eşleşti. | PASS | 16.10.2026 17:21:58 |
| P15 | Light/dark tercihi değişir ve refresh sonrası korunur | Tema butonuyla dark oldu; refresh sonrası korundu. | PASS | 16.10.2026 17:21:59 |
| P16 | 390px overview/analytics/profil taşmaz; mobil navigasyon çalışır | Overview/analytics/profil 390px’de yatay taşmadı; mobil menüden Leads açıldı. | PASS | 16.10.2026 17:22:01 |
| P17 | İkinci organizasyon QA A verisini okuyamaz veya değiştiremez | QA B, A kaydını listede görmedi; A kaydına GET/POST 404. | PASS | 16.10.2026 17:22:06 |
| P18 | A oturumuna dönünce QA kayıtları ve gelir kalıcıdır | A’ya tekrar login sonrası Won 1 ve EUR pipeline korundu. | PASS | 16.10.2026 17:22:09 |
| P19 | Oturum cookie'si Secure/HttpOnly/SameSite; UI özgün marka | Secure/HttpOnly cookie; HTTP envanterinde SameSite=Lax; görünür UI özgün marka. | PASS | 16.10.2026 17:22:09 |
| P20 | CSS/JS browser'da çalışır; normal sayfalarda 500 hata metni yok | CSS computed-style, Stimulus tema/menü ve Turbo formları çalıştı; normal akışlarda 500 görülmedi. | PASS | 16.10.2026 17:22:10 |
| P21 | Bugünkü yaklaşan follow-up priority 85 ve açıklamayla görünür | Gerçek bugünkü vade ile priority 85 ve takip açıklaması görüldü. | PASS | 16.10.2026 17:22:13 |
| P22 | Saat değiştirmeden gerçek zaman geçince aynı görev overdue priority 95 olur | Production saati değiştirilmeden vade doğal olarak geçti; öneri priority 95 / overdue oldu. | PASS | 16.10.2026 17:24:03 |
| P23 | NBA'dan görev tamamlama overdue uyarısını temizler; temas ayrı kalır | NBA Complete follow-up sonrası overdue açıklaması kalktı; ayrı ilk temas önerisi kaldı. | PASS | 16.10.2026 17:24:04 |
| P24 | NBA contact işlemi refresh sonrasında da tamamlanmış ve öneriden kalkmış kalır | Dashboard contact sonrası bu lead öneriden kalktı; refresh ve profil Contacted bunu doğruladı. | PASS | 16.10.2026 17:24:06 |
| P25 | NBA deal-stage eylemi Proposal'a ilerler ve dashboard'a döner | Yakın kapanışlı EUR deal NBA formundan Proposal’a ilerledi; dashboard’a döndü ve profilde kalıcı kaldı. | PASS | 16.10.2026 17:24:09 |
| P26 | Satış temsilcisi aynı workspace'te başkasının kaydını değiştiremez; NBA yetkili eylem sunar | Aynı workspace salesperson için NBA boş; manager-owned lead’e yetkisiz POST 422. | PASS | 16.10.2026 17:24:17 |

**Sonuç:** son turda 26/26 browser vakası PASS. P09/P13 tutarları yalnız o adımın yeni QA workspace snapshot'ıdır; sonraki QA kayıtları oranı değiştirebilir, global demo performansı veya satış sonucu değildir. İlk temas formundaki tamamlanmış görüşme bir kullanıcı beyanıdır; gerçek telefon/e-posta sağlayıcısı doğrulanmaz.

## Zaman kuralı ve yerel/CI sınırı

| Davranış | Yerel/CI kanıtı | Üretim kanıtı ve sınır |
|---|---|---|
| Oluşumdan 24 gerçek saat, tam deadline zamanında | [deadline_test.rb:4](../test/models/deadline_test.rb#L4), [satır 12](../test/models/deadline_test.rb#L12): travel_to ile önce/tam/sonra | Yeni lead deadline gösterimi geçti; üretimde 24 saat beklenmedi ve saat değiştirilmedi |
| Contact gecikmeyi kaldırır; not/görev ilk temas sayılmaz | [deadline_test.rb:19](../test/models/deadline_test.rb#L19), [satır 32](../test/models/deadline_test.rb#L32) | P05/P11/P23/P24: contact ve görev ayrımı doğrulandı |
| 4 saat uyarı ve 72 saat inactivity | [pro_upgrade_test.rb:24](../test/models/pro_upgrade_test.rb#L24) | Yeni QA verisi için 4/72 saatlik yaşlandırma yapılmadı: production-specific kontrol BLOCKED, yerel/CI boundary testi PASS |
| Today → overdue follow-up | [pro_upgrade_test.rb:6](../test/models/pro_upgrade_test.rb#L6) | P21/P22 gerçek kısa vade doğal olarak geçti, priority 85 → 95 |
| Geçerli/geçersiz geçiş ve terminal durum | [workflow_test.rb:26](../test/models/workflow_test.rb#L26), [satır 60](../test/models/workflow_test.rb#L60) | P08 geçerli tam yol ve terminal Won; tüm geçersiz kombinasyonlar üretime saldırarak denenmedi |
| Tek conversion / eşzamanlı istekler | [workflow_test.rb:39](../test/models/workflow_test.rb#L39), [concurrent_conversion_test.rb:20](../test/models/concurrent_conversion_test.rb#L20) | Üretimde tek dönüşüm akışı; duplicate/concurrent testler yalnız izole test DB'sinde |

## Bulunan hata ve güvenli düzeltme

**CSP-01 — düzeltildi, canlıda tekrar doğrulandı.** Fresh cookie'siz /login veya /signup açıldığında eski generator henüz oluşmamış session ID'den boş nonce üretiyordu; header geçersiz nonce kaynağı taşıyor, inline importmap/module script'leri bloke ediliyordu. style-src nonce yetkisi de olmadığı için Turbo progress stylesheet'i reddediliyordu. Ana satış akışı sonraki oturumlarda çalışsa da fresh-session JavaScript yüklenmesi güvenilir değildi.

Yalnız [content_security_policy.rb:11](../config/initializers/content_security_policy.rb#L11) değişti: session içinde kriptografik rastgele nonce ve script-src/style-src direktifleri. unsafe-inline eklenmedi; authentication, iş kuralları, DB şeması veya production env değiştirilmedi. [HTTP regresyon testi](../test/integration/content_security_policy_test.rb#L4) eski kodda boş nonce nedeniyle fail oldu, yeni kodda geçti; [gerçek browser regresyonu](../test/system/content_security_policy_test.rb#L4) fresh Stimulus/Turbo başlangıcını doğrular. [Düzeltme CI](https://github.com/Montaserissa20/leadcurrent/actions/runs/38914594060) success; push sonrası Railway'de yeni header davranışı ve temiz browser konsolu görüldü, tam akış tekrarlandı.

QA otomasyonunda iki ayrı yöntem hatası düzeltildi: Turbo ile kaldırılmış recommendation içinde flash beklemek stale-element üretiyordu; native tarih alanına string yazmak yanlış yıl giriyordu. Bunlar uygulama veri modeli veya zaman kuralı hatası sayılmadı. Final turunda tarih değeri exact native setter + input/change event ile kontrol edildi ve 26 vaka tekrar geçti. Ön denemelerin FAIL'leri sessizce PASS'e çevrilmedi; final tur ayrı yeniden çalıştırıldı.

## Yerel otomatik doğrulama ve GitHub Actions

| Komut | Gerçek sonuç |
|---|---|
| bundle exec rails test | Seed 10744: 54 runs, 547 assertions, 0 failures, 0 errors, 0 skips |
| bundle exec rails test:system | Seed 50096; Edge: 6 runs, 54 assertions, 0 failures, 0 errors, 0 skips |
| Toplam | 60 test, 601 assertion; PostgreSQL tabanlı |
| bundle exec rails zeitwerk:check | All is good |
| bundle exec brakeman --no-pager --quiet | Brakeman 8.1.0: 0 error, 0 security warning |
| RAILS_ENV=production SECRET_KEY_BASE_DUMMY=1 bundle exec rails assets:precompile | Başarılı; yalnız yerel build, production migration/seed değil |

İlk yerel çalıştırmada yerel PostgreSQL durmuştu; var olan cluster başlatıldı, reset yapılmadı ve testler tekrar geçti. Windows Ruby/fork fallback uyarıları scanner sonucunda error değildir. Son doküman commit'inin exact-HEAD CI sonucu push sonrasında ayrıca kontrol edilir; en son doğrulanmış link aşağıdaki teslim kaydına eklenir.

## Sınırlar ve teslim kaydı

Üretim kanıtı ve raporlar `372113eef6fbdb2680ac240660c30fa1c7f8edab` ile `main` dalına push edildi. [LeadCurrent CI run 38916046091](https://github.com/Montaserissa20/leadcurrent/actions/runs/38916046091): **completed / success**; domain/HTTP, gerçek Chrome browser, autoload, security ve production assets adımları başarılı. GitHub API, README ve üç istenen rapor ile redakte evidence JSON'u için HTTP 200 ve commit blob SHA eşleşmesini doğruladı. Markdown/yerel anchor kontrolleri ve redakte staged/history secret taramaları geçti; `.local` ve secret/runtime dosyaları commit edilmedi. Bu teslim kaydını ekleyen sonraki yalnız belge commit'inin exact-HEAD CI sonucu teslim mesajında ayrıca verilir.

- Uzak deployment SHA/ID, Railway paneli, fatura ve operasyon logları hesabı erişilebilir değil; public davranış ve yeni CSP fix'i gerçekten gözlendi. Yeni release'in farklı sonraki SHA'sı tahmin edilmez.
- Production 4/24/72 saatlik sınırlar yapay olarak değiştirilmedi; yerel/CI travel_to kanıtı üretim zaman testi diye sunulmaz.
- Backup/restore, yük/uzun süreli uptime, e-posta/telefon/calendar provider'ları, MFA ve parola kurtarma bu testin tamamladığı işler değildir.
- [Ödev kontrol listesi](ASSIGNMENT_CHECKLIST.md) araştırma proxy/kapalı LOC ve eksik gerçek gider kayıtlarını PARTIAL gösterir. Bu rapor puan garantisi değildir.
- Gerçek QA verileri silinmedi; generated hesap erişim sırları yayımlanmadı. Yetki testleri yalnız bize ait iki QA workspace/kayıtları üzerinde sınırlı GET/POST denemeleridir.
