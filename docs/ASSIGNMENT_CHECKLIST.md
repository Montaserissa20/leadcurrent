# Ödev gereksinimleri ve teslim kontrolü

16 Ekim 2026. PASS = kanıtlanan kapsam; PARTIAL = belirtilen kanıt eksikliği; FAIL = gözlenen hata; BLOCKED = eksik yönerge/veri veya erişim nedeniyle tamamlanamayan kontrol. Kullanıcı yönergesine ek olarak özgün 37 sayfalık `2026-10-12.pdf` bulundu; istenen sayfalar ve tüm metindeki G1–G5 atıfları incelendi. S.35 rubriği artık doğrudan doğrulandı; tam G1–G5 görev tanımları bulunmadığından 85/100+ puan garantisi verilmez. [PDF kimliği ve bulgular](G1_G5_AUDIT_TR.md).

| Gereksinim | Durum | Kanıt ve sınır |
|---|---|---|
| Bağımsız Rails 8+ uygulama | PASS | [Gemfile.lock](../Gemfile.lock): Rails 8.1.4; ayrı repo ve [eski proje incelemesi](OLD_PROJECT_INSPECTION.md) |
| Kalıcı PostgreSQL | PASS | [database.yml](../config/database.yml), canlı `/up` 200/connected; [üretim raporu](PRODUCTION_TEST_REPORT.md) P10/P18: refresh ve tekrar login sonrası aynı kayıt/değer |
| Özgün LeadCurrent markası | PASS | [layout](../app/views/layouts/application.html.erb), [ikon](../public/icon.svg); üretimde marka kontrolü P19 |
| Uygulama UI'sinde ilham ürününün markası yok | PASS | P19 görünür metin kontrolü; rakip adı README/araştırma/sunum anlatımında, uygulama UI'sinde değil |
| Çalışan genel URL | PASS | [Railway](https://leadcurrent-production.up.railway.app), `/login` ve `/signup` 200, korumalı sayfalar anonim istekte login'e 302 |
| Tam aort dilimi | PASS | Üretim P03–P10: lead/şirket/kişi → contact → qualified → opportunity → Proposal → Negotiation → Won; kalıcılık doğrulandı |
| 24 saat kuralı | PASS | [servis:2](../app/services/follow_up_deadline.rb#L2); [deadline_test.rb](../test/models/deadline_test.rb); üretimde yeni lead deadline gösterimi ve görevin ilk temas olmaması |
| Gerçek `travel_to` ve sınır davranışı | PASS | [deadline_test.rb:12](../test/models/deadline_test.rb#L12): önce/tam/sonra; timezone/DST; yerel PostgreSQL testleri. Üretim saati değiştirilmedi |
| Üç bağımsız zaman kuralı, PDF s.35 | PASS | 24 saat ilk temas; ≤4 saat uyarı; ≥72 saat fırsat hareketsizliği. Her biri önce/tam/sonra `travel_to`; [kesin kaynak/test satırları ve 8 test / 41 assertion](THREE_TIME_RULES_TR.md) |
| İzinli/reddedilen durum geçişleri | PASS | [LeadTransition](../app/services/lead_transition.rb#L2), [OpportunityTransition](../app/services/opportunity_transition.rb#L2), [workflow_test.rb:26](../test/models/workflow_test.rb#L26); üretimde geçerli akış ve terminal Won |
| Tek conversion ve eşzamanlılık | PASS | [workflow_test.rb:39](../test/models/workflow_test.rb#L39), [concurrent_conversion_test.rb:20](../test/models/concurrent_conversion_test.rb#L20); kilit ve unique lead FK. Üretimde agresif eşzamanlı yazma denenmedi |
| Automated domain/HTTP/browser testleri | PASS | [PDF güncellemesinin gerçek sonuçları](G1_G5_AUDIT_TR.md#son-doğrulama): 56 domain/HTTP + 7 browser = 63 test, 632 assertion; sıfır failure/error/skip; Zeitwerk, Brakeman ve assets PASS |
| GitHub Actions ve gerçek badge | PASS | [workflow](../.github/workflows/ci.yml), README badge; [83b0a85 PDF test run'ı](https://github.com/Montaserissa20/leadcurrent/actions/runs/38946656482) success, gerçek job log'unda 63 test / 632 assertion. Bu kaydı ekleyen son belge HEAD'i push sonrası ayrıca sorgulanır |
| AGENT.md | PASS | [AGENT.md](../AGENT.md): gerçek mimari, iş kuralları, testler, deployment ve güvenlik sınırları |
| İlk/son AGENT diff'i, PDF s.26 | PASS | [Gerçek unified diff](AGENT_FIRST_LAST.diff), [ilk c478f87 → son 83b0a85 commit'leri ve evrim](AGENT_EVOLUTION_TR.md); önceki sürüm üretilmedi |
| Ruby/Rails yasak sihir ve sapmalar | PASS | [Kaynak denetimi](G1_G5_AUDIT_TR.md#kısa-rubyrails-konvansiyon-denetimi); monkey patch/method_missing/default_scope yok; türetilmiş deadline callback'i ve TenantRecord belgeli |
| G1–G5 tam görev teslimi | BLOCKED | PDF'de G1/G5 kısmi atıfları var; tam G1–G5 yönergesi yok. [G1_G5_AUDIT_TR.md](G1_G5_AUDIT_TR.md): özgün görev tanımları gerekiyor; beş ölçüt görevlere eşlenmedi |
| PDF s.31 gerçek agent ölçümleri | PARTIAL | Kaynaklı CI test sayısı var; gerçek çıktı token, toplam düzeltme turu/uydurma ve insan review dakikası dökümü yok. Bilinmeyenler sıfır yazılmadı |
| Fortune 500 ticari müşteri kanıtı | PASS | [Ford ürün hikâyesi](https://www.salesforce.com/ca/customer-stories/ford-reinventing-customer-experience/) + [Fortune profili](https://fortune.com/company/ford-motor/). Kullanım kanıtı var; sözleşme bedeli açıklanmıyor |
| Fortune 500 sayısal araştırması | PARTIAL | [README tablosu](../README.md#fortune-500-araştırması), [araştırma sınırları](RESEARCH_AUDIT_TR.md): kaynaklı şirket örnekleri ve Zylo kurumsal benchmark'ı var; tüm 500 için aynı tarihli kesin nüfus min/max yok |
| Kurumsal SaaS kod büyüklüğü | PARTIAL | [README](../README.md#saas-kod-satırı-tahmini): olgun açık CRM sayımı/yöntemi var; bunlar orijinal kapalı ürünün gerçek LOC veya kanıtlanmış alt sınırı değildir |
| Tahmini agent USD ve süre | PASS | [COSTS_TR.md](COSTS_TR.md): 30 saat/5 gün, açık token varsayımı, $9/$12.50 alternatif API hesabı; abonelik aylık bedel olarak ayrı |
| Gerçek gider ve gerçek emek saati | PARTIAL | Git takvim kanıtı var; fatura/timesheet yok. “Kesin kullanım veya ödeme verisi mevcut değil.” Bilinmeyen değer $0 yazılmadı |
| Gerçek müşteri şikâyeti ve URL | PASS | [Capterra](https://www.capterra.com/p/61368/Salesforce/reviews/), khyan A., 15 Mart 2026; yazar/tarih/karmaşıklık bağlamı arama indeksinde eşleştirildi. [README açıklaması](../README.md#kullanıcı-yorumu-ve-çözüm) |
| Çalışan problem çözümü / NBA | PASS | Üretim P04/P05/P21–P25: açıklama, upcoming 85 → doğal overdue 95, görev tamamlama, contact, doğrudan deal-stage ve refresh kalıcılığı; production CSP fix'i ayrıca tekrar doğrulandı |
| Orijinalde olmayan adaptasyon, PDF s.35 / 100+ | PARTIAL | Salesforce Einstein NBA zaten var. [Gerçek browser ölçümü](ADAPTATION_EVIDENCE_TR.md): 2 click/1 submit/1 POST/0 profile ziyareti; sade akış çalışır. Rakipte yokluk veya karşılaştırmalı üstünlük kanıtlanmadı; dar aday ve sınır açık |
| Customer 360, görev, activity, analytics | PASS | P07/P11–P16: bağlı geçmiş, task create/edit/complete, filtre, gerçek SQL metrikleri, USD/EUR ayrımı, tema ve mobil |
| Yetkilendirme | PASS | P17: iki QA organizasyonu arasında GET/POST 404; P26: aynı workspace salesperson için yetkisiz POST 422; yerel auth/tenant testleri |
| Dürüst Yapamadıklarım | PASS | [README](../README.md#yapamadıklarım): billing, tam nüfus/LOC, üretim operasyonu ve eksik kurumsal özellikler açık |
| Beş dakikalık sunum | PASS | [FINAL_PRESENTATION_TR.md](FINAL_PRESENTATION_TR.md): canlı akış, gerçek dosya/satır, zaman testleri ve açıklanmış sınırlar |

## Sıfır puan riski ve kapanmamış kalemler

Genel URL'nin bozuk olması, aort diliminin gösterilememesi, DB kalıcılığının olmaması veya zorunlu zaman/geçiş/test/CI kanıtının bulunmaması gibi yönergede zorunlu sayılan eksikler ek görsel özelliklerle telafi edilemez. Bu yüzden public health, gerçek akış, tekrar login, boundary/transition testleri ve exact-commit CI ayrı kanıtlanır. Üretim availability tek bir test zamanının gözlemidir; gelecekteki uptime garantisi değildir.

Kalan kararlar: özgün G1–G5 görev tanımlarını ve gerçek agent ölçüm kayıtlarını sağlamak; 100+ için rakipte yokluğu kanıtlanmış adaptasyon kapsamını netleştirmek; gerçek fatura/saat raporunu sağlamak; tam Fortune nüfus uçları ve kapalı kaynak LOC yerine kaynaklı proxy'nin kabulünü netleştirmek; sunumdan hemen önce canlı URL ve güncel CI'ı tekrar açmak. Production release SHA'sı/operasyon paneli, backup/restore ve maliyetler hesap erişimi olmadan doğrulanmış sayılmaz.
