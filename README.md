# LeadCurrent

[![LeadCurrent CI](https://github.com/Montaserissa20/leadcurrent/actions/workflows/ci.yml/badge.svg)](https://github.com/Montaserissa20/leadcurrent/actions/workflows/ci.yml)

## Proje Tanıtımı

LeadCurrent; müşteri adayını ilk temastan kazanılan satış fırsatına taşıyan, üniversite ödevi için geliştirilmiş bağımsız bir CRM SaaS uygulamasıdır. Özgün yeşil/krem görsel kimlik, logo, responsive arayüz, açık/koyu tema ve PostgreSQL kalıcılığı kullanır. Dashboard istatistikleri gerçek veritabanı sorgularından hesaplanır; USD, EUR ve TRY birbirine eklenmez.

Ruby 3.4.7, Rails 8.1.4, PostgreSQL 17, Hotwire/Turbo, Stimulus, Propshaft, Minitest, Capybara/Selenium, GitHub Actions ve Render yapılandırması. React, Redis, mikroservis veya AI sağlayıcısı temel işleyiş için gerekli değildir.

Eski Fixture projesi yalnızca salt okunur referanstır. Lisans dosyası bulunmadığı için uygulama kaynak kodu kopyalanmadı; eski veri/credential kullanılmadı. Yeni repository, DB, migration ve marka bağımsızdır. İnceleme: [OLD_PROJECT_INSPECTION.md](docs/OLD_PROJECT_INSPECTION.md).

## İlham Alınan SaaS

Salesforce Sales Cloud, satış ekiplerinin müşteri bilgilerini, adaylarını, fırsatlarını ve satış faaliyetlerini aynı sistemde yönetmesini sağlar. İşletmeler görünür bir satış hattı, zamanında takip, ekipler arasında bilgi sürekliliği ve ölçülebilir satış süreçleri için bu tür yazılımlar satın alır. LeadCurrent bu ekonomik değerin merkezi akışını uygular; aynı arayüzü veya marka kimliğini kopyalamaz. [Sales Cloud](https://www.salesforce.com/sales/cloud/).

## Fortune 500 Araştırması

Araştırma tarihi: **14 Ekim 2026**. Fortune 500 gelir sıralamasıdır; piyasa değeri sıralaması değildir. [Fortune 500](https://fortune.com/ranking/fortune500/).

Gelir, dönem içindeki satış hasılatıdır. Market capitalization, halka açık özsermayenin piyasa değeridir. Enterprise value borç/nakit düzeltmeleri içerir. Özel şirket değerlemeleri borsa değeriyle aynı ölçüm değildir. Bu çalışma bu kavramları birbirinin yerine kullanmaz.

| Ölçüt | Doğrulanabilen sonuç ve kapsam | Kaynak |
|---|---|---|
| Fortune 500 grup büyüklüğü | 2026 toplam istihdamı yaklaşık 30,5 milyon | [Resmî sıralama](https://fortune.com/ranking/fortune500/) |
| Küçük halka açık üye örneği | Gold.com: 2026 sıra 398; 975 çalışan; piyasa değeri 1,128 milyar USD, 31 Mart 2026 | [Şirket profili](https://fortune.com/company/a-mark-precious-metals/) |
| Büyük işveren örneği | Walmart: 2.100.000 çalışan | [Şirket profili](https://fortune.com/company/walmart/) |
| Büyük piyasa değeri örneği | NVIDIA: 5,445390 trilyon USD, 24 Eylül 2026 | [Şirket profili](https://fortune.com/company/nvidia/) |
| SaaS sayısı, kurumsal benchmark | Zylo 2026 örneklemi: ortalama 305, medyan 240 uygulama | [2026 SaaS Management Index](https://zylo.com/2026-saas-management-index) |
| Yıllık SaaS harcaması, kurumsal benchmark | Aynı örneklem: ortalama 55,7 milyon USD, medyan 20,6 milyon USD | [2026 SaaS Management Index](https://zylo.com/2026-saas-management-index) |

**Aralıkların sınırı:** erişilebilen üye örneklerinde çalışan sayısı 975–2.100.000, piyasa değeri yaklaşık 1,128 milyar–5,445 trilyon USD ölçeğindedir. Bu, 500 şirketin tamamının kanıtlanmış minimum/maksimum aralığı değildir. Piyasa değerlerinin ölçüm tarihleri de farklıdır. Özel üyelerin aynı tarihli değerlemesi açık olmayabilir; tüm üyeleri kapsayan tek bir değerleme aralığı kurulamadı. Çalışan aralığının kesin alt sınırı da tam nüfus verisi olmadan iddia edilmez. Örneklerin amacı tek şirket yerine grubun farklı ölçeklerini görünür kılmaktır.

Zylo verisi Fortune 500 nüfus sayımı değildir; yönetilen müşteri portföylerinden oluşan kurumsal benchmarktır. Fortune 500 başına ortalama uygulama sayısı/abonelik bedeli olarak sunulmaz. Büyük bir kurum için yüzlerce uygulama ve onlarca milyon USD/yıl ancak bu benchmarka dayanan yaklaşık planlama ölçeğidir. [Zylo metodoloji açıklaması](https://zylo.com/2026-saas-management-index).

## Fortune 500 Kullanım Kanıtları

| Şirket | Kullanım kanıtı | Fortune 500 doğrulaması | Kanıtın sınırı |
|---|---|---|---|
| Ford Motor | [Resmî müşteri hikâyesinde](https://www.salesforce.com/ca/customer-stories/ford-reinventing-customer-experience/) Products Used bölümünde Sales Cloud ve metinde müşteri verisi/sipariş iletişimindeki kullanım açıkça belirtilir | [Fortune profili](https://fortune.com/company/ford-motor/): 2026, sıra 22 | 2022 dönüşümünü anlatır. Ticari müşteri kullanımı kanıtıdır; güncel lisans bedeli veya fatura yayımlanmaz |
| American Express | [Resmî müşteri hikâyesi](https://www.salesforce.com/customer-success-stories/american-express/) ortaklığın 2010 yılında Sales Cloud ile başladığını söyler | [Fortune profili](https://fortune.com/company/american-express/) 2026 Fortune 500 üyeliğini gösterir | Tarihsel ürün kullanımı doğrulanır; 2026 sözleşme kapsamı/bedeli açıklanmaz |

[T-Mobile hikâyesi](https://www.salesforce.com/ca/customer-stories/t-mobile/) de Sales Cloud ile pipeline yönetimini açıkça doğrular. Ancak 2016 dönemi içerir; erişilen [Fortune profili](https://fortune.com/company/t-mobile/) güncel Fortune 500 üyeliğini yeterince doğrulamadığından bunu kabul kanıtı tablosuna dahil etmedim.

**Ödeme ayrımı:** ticari müşteri hikâyeleri ürün kullanımını doğrular; açıklanmayan bir kontrat fiyatını veya fatura tutarını kanıtlamaz. Burada “kesin şu bedeli ödüyorlar” iddiası yoktur.

## Kod Satırı ve Yazılım Ölçeği

Salesforce kapalı kaynak olduğundan gerçek satır sayısı kamuya açık değildir. Sayı uydurulmaz. Açık kaynak CRM karşılaştırması:

| Ürün | Kod satırı / toplam fiziksel satır | Analiz ve veri tarihi (UTC) | Kaynak |
|---|---|---|---|
| EspoCRM | 404.831 kod / 678.466 toplam | Analiz: 14 Ekim 2026 02:59:36; veri: 13 Ekim 2026 02:39:29 | [Open Hub dil dökümü](https://openhub.net/p/espocrm/analyses/latest/languages_summary), [repository](https://github.com/espocrm/espocrm) |
| SuiteCRM | 788.846 kod / 1.236.108 toplam | Analiz: 14 Ekim 2026 06:26:00; veri: 13 Ekim 2026 05:38:08 | [Open Hub dil dökümü](https://openhub.net/p/suitecrm/analyses/latest/languages_summary), [repository](https://github.com/salesagility/SuiteCRM) |

Open Hub, Ohcount ile kod/yorum/boş satırları ayırır. [Yöntem](https://openhub.net/tools). Depo kapsamı, dahil edilen bağımlılıklar ve dil sınıflandırması ölçümü etkileyebilir; LOC işlev veya kalite ölçüsü değildir. Eski arama önbelleklerindeki sayılar yerine doğrudan erişilen güncel dil sayfaları kullanıldı.

**Açıkça etiketlenmiş ölçek tahmini:** yaklaşık 0,4–0,8 milyon kod satırlık olgun CRM karşılaştırma bandı, 300.000+ satır sınıfındaki kurumsal CRM karmaşıklığına işaret eder. Bu Salesforce kaynak kodunun ölçümü, alt sınırı veya kesin tahmini değildir. Salesforce'un çoklu tenant, entegrasyon, satış, analiz ve yetkilendirme kapsamı bu sınıfla nitel olarak karşılaştırılabilir. LeadCurrent, bu ürünlerin tüm kapsamı yerine seçilen iş akışını uygular.

## Geliştirme Maliyet Tahmini

Planlama varsayımı: bir haftalık öğrenci projesinde 5 gün × günde 6 odaklı saat = **30 saat**; yaklaşık 6 saat analiz/kurulum, 12 saat iş akışı, 6 saat test/arayüz, 6 saat araştırma/dağıtım. Bu, piyasa araştırması veya gerçekleşmiş insan çalışma saati değildir.

Coding-agent için token tüketimi ve birim ücret sağlanmadığından kesin USD maliyet tahmini yoktur. Formül: giriş tokenı × giriş birim fiyatı + çıkış tokenı × çıkış birim fiyatı; abonelik kullanılıyorsa artan proje maliyeti abonelik modeline göre değerlendirilir. Dışarıya açık AI API maliyeti bu sürümde oluşmaz; uygulamada AI sağlayıcısı yoktur.

## Gerçekleşen Maliyet

Bu çalışma sırasında bir ücretli hosting, domain veya AI API satın alınmadı; agent tarafından başlatılan yeni ücretli satın alma **0 USD**. Kullanıcının mevcut abonelik bedeli ve token faturası görünür olmadığından toplam geliştirme maliyeti “0” diye iddia edilmez. Render hesabında hizmet henüz oluşturulmadığından gerçek hosting faturası yoktur. Zaman kaydı ve gider sınırları: [COSTS_TR.md](docs/COSTS_TR.md).

## Aort Dilimi

**New Lead → tamamlanmış müşteri teması → Contacted → Qualified → Opportunity / Qualification → Proposal → Negotiation → Won / Lost.**

Lead oluşturma şirket ve kişi kayıtlarını aynı işlemde oluşturur. Sahip atanır. Temas/not kaydı ve takip planlama gerçek DB yazmalarıdır. Qualified dönüşümü bağlı şirket, kişi, sahip ve lead ilişkilerini korur; bekleyen lead görevleri fırsata aktarılır. Satış kapanışı zaman damgası ve audit kaydı üretir. Kanban yalnızca izin verilen sonraki aşamaları sunar; drag-and-drop yerine güvenilir form geçişleri kullanır.

## Zaman Kuralı

İlk müşteri teması, kaydın oluşturulmasından itibaren **24 gerçek saat** içinde tamamlanmalıdır. Nitelikli olay: salesperson'ın fiilen tamamladığı çağrı, toplantı veya müşteriye gönderilmiş mesaj için `contact` aktivitesi kaydetmesi. Bu bir kullanıcı beyanıdır; telefon/e-posta sağlayıcısından teslimat doğrulaması yapılmaz. Not, gelecekteki randevu ve görev tamamlama ilk teması karşılamaz.

Deadline DB'de saklanır. Tam deadline anı zamanında kabul edilir; bir saniye sonra gecikir. İlk temas tamamlanınca gecikme kalkar; sonraki temaslar ilk zamanı değiştirmez. Tarihler DB'de UTC, arayüzde profil saat dilimindedir. Gece yarısı ve DST testleri vardır. Süre `24.hours`, takvim günü değildir.

Değişiklik yeri: [FollowUpDeadline](app/services/follow_up_deadline.rb#L2) `FIRST_CONTACT_WINDOW`, `deadline`, `overdue?`. İlk temas işleme: [RecordActivity.call](app/services/record_activity.rb). Gerçek `travel_to` testleri: [deadline_test.rb](test/models/deadline_test.rb#L12). Worker veya AI gerekmez.

## Durum Akışı

| Kayıt | İzinli geçiş |
|---|---|
| Lead New | Contacted (tamamlanmış temas ile) veya Disqualified |
| Lead Contacted | Qualified veya Disqualified |
| Lead Qualified | Ayrı atomik dönüşüm ile Converted veya Disqualified |
| Lead Converted / Disqualified | Terminal; yeniden açılamaz |
| Opportunity Qualification | Proposal veya Lost |
| Opportunity Proposal | Negotiation veya Lost |
| Opportunity Negotiation | Won veya Lost |
| Opportunity Won / Lost | Terminal; yeniden açılamaz |

[LeadTransition.call / TRANSITIONS](app/services/lead_transition.rb#L2), [LeadConversion.call](app/services/lead_conversion.rb), [OpportunityTransition.call / TRANSITIONS](app/services/opportunity_transition.rb#L2). Dönüşüm satır kilidi, transaction ve unique lead FK indeksiyle korunur. İki eşzamanlı istek testi tek fırsat ve tek reddetme üretir. Normal update parametreleri status/deadline/first-contact alanlarını kabul etmez; model de workflow dışı değişiklikleri reddeder.

## Gerçek Kullanıcı Problemi

Capterra, **khyan A.**, Senior Business Development Representative, Computer Software; **15 Mart 2026**, “Powerful but heavy - great once it’s set up properly”. Platform Verified User olarak işaretler; yorum non-incentivized olarak listelenir. Kısa özgün alıntı: **“The main downside is the complexity and cost.”** Arayüzün çok sayıda alan/iş akışıyla kalabalıklaşabilmesi ve başlangıçta sezgisel olmaması eleştiriliyor. [Doğrulanan yorum sayfası](https://www.capterra.com/p/61368/Salesforce/reviews/).

**Çözüm: Next Best Action.** Gecikmiş ilk temas, yaklaşan deadline, 72 saatlik fırsat durgunluğu ve yaklaşan kapanış deterministik olarak sıralanır. Her öneri nedenini açıklar. Dashboard formu tamamlanmış teması ve takip görevini **tek gönderimde** kaydeder. Sadece takip planlama ilk temas deadline'ını kapatmaz. [Öncelik servisi](app/services/next_best_action.rb), [eylem endpoint'i](app/controllers/actions_controller.rb), [testler](test/models/next_best_action_test.rb).

**Ölçülen akış:** dashboard zaten açıkken varsayılan yarın takip zamanı korunursa “What happened?” alanına odaklanma 1 tıklama, sonuç yazma, “Save action” 1 tıklama: **2 fare tıklaması, 1 submit, 0 ek sayfa navigasyonu**. Klavye ile odaklanılırsa fare sayısı daha düşük olabilir. Farklı tarih seçimi ek etkileşim gerektirir. Gerçek Selenium testi bu formu doldurup tek submit ile Activity/Task kalıcılığını doğrular. Salesforce için karşılaştırmalı tıklama sayısı ölçülmedi; ürünler arası sayısal üstünlük iddiası yoktur.

## Kurulum

Windows için mevcut Ruby 3.4.7 ve PostgreSQL 17 kurulumu kullanılır. Eski projede hiçbir komut çalıştırmayın.

```powershell
Set-Location D:\LeadCurrent
bundle install
powershell -ExecutionPolicy Bypass -File bin\local-postgres.ps1
bundle exec rails db:prepare
bundle exec rails db:seed
bundle exec rails server -b 127.0.0.1 -p 3100
```

Yerel adres: **http://127.0.0.1:3100**. Geliştirme demo hesabı: **demo@leadcurrent.test**, parola: **LeadCurrentDemo!2026**. Bunlar kurgusal, yalnızca development demo bilgileridir. Production seed varsayılan parolayı kabul etmez; `DEMO_PASSWORD` ortam değişkeni gerekir. Ya da /signup ile yeni izole workspace oluşturun.

Windows yardımcısı yalnızca proje içindeki `.local/postgres` cluster'ını loopback **55432** portunda başlatır. Trust authentication yalnızca yerel geliştirme içindir. Mevcut PostgreSQL 5432 servisi ve Fixture verisi kullanılmaz. Durdurmak için aynı yardımcıya `-Action stop` verin.

Kendi PostgreSQL kurulumunuzu kullanmak için `PGHOST`, `PGPORT`, `PGUSER`, `PGPASSWORD` ayarlayın. Linux/macOS: bu değişkenleri export edin, `bundle install`, `bundle exec rails db:prepare db:seed` ve `bundle exec rails server` çalıştırın. Varsayılan bağımsız DB isimleri `leadcurrent_development` / `leadcurrent_test`. `.env.example` yalnızca örnektir; env dosyası otomatik yüklenmez.

## Testler

```powershell
bundle exec rails test
bundle exec rails test:system
bundle exec rails zeitwerk:check
bundle exec brakeman --no-pager --quiet
$env:RAILS_ENV='production'
$env:SECRET_KEY_BASE_DUMMY='1'
bundle exec rails assets:precompile
Remove-Item Env:RAILS_ENV
Remove-Item Env:SECRET_KEY_BASE_DUMMY
```

14 Ekim 2026 yerel doğrulama: **37 model/service/integration testi, 401 assertion; 2 gerçek browser testi, 24 assertion; sıfır failure/error/skip**. Brakeman: **0 security warning**. Zeitwerk ve production asset derlemesi geçti. Browser Windows'ta headless Edge, GitHub Linux'ta headless Chrome kullanır. Testler gerçek PostgreSQL'e yazar; deadline sonuçları mock edilmez. Doğrulama raporu: [VERIFICATION_TR.md](docs/VERIFICATION_TR.md).

CI PostgreSQL servisini başlatır, migrate eder, domain/HTTP/browser testlerini, Zeitwerk, Brakeman ve asset build'i çalıştırır. Badge yukarıdaki gerçek repository/workflow'ya aittir; son durum Actions sayfasından kontrol edilmelidir. En son kontrol edilen commit/run ayrıca doğrulama raporunda kayıtlıdır.

## Canlı Uygulama

**Render dağıtımı tamamlanmadı; doğrulanmış genel URL henüz yok.** Yerel adres genel yayın olarak sunulmaz. Render hesabı bağlantısı bu oturumda doğrulanmadı.

[Render Blueprint başlat](https://dashboard.render.com/select-repo?type=blueprint). Repository: `Montaserissa20/leadcurrent`; dosya: [render.yaml](render.yaml). `DEMO_PASSWORD` için production'a özgü güçlü bir değer girin. Blueprint, ayrı Postgres hizmeti ve web hizmeti oluşturur; `SECRET_KEY_BASE` otomatik üretilir. `DATABASE_URL` servis bağıyla gelir. Rails credentials için eski projenin master key'i asla kullanılmaz.

Build: `bash bin/render-build.sh`; start: `bundle exec puma -C config/puma.rb`; health: `/up` DB bağlantısını da kontrol eder. Free plan pre-deploy çalıştırmadığından migration build script'indedir. Paid planda migration ayrı pre-deploy komutuna taşınabilir. [Render Rails rehberi](https://render.com/docs/deploy-rails-8).

Free Postgres 30 gün sonra sona erer; uzun süreli gösterim için süre dolmadan paid plana geçin. Free web hizmeti 15 dakika inaktiflikten sonra uyuyabilir. [Resmî free-plan sınırları](https://render.com/docs/free). Production doğrulama adımları: [DEPLOYMENT_TR.md](docs/DEPLOYMENT_TR.md). Yayın URL'si, login ve DB workflow üretimde doğrulandıktan sonra bu bölüme eklenmelidir.

## GitHub

Gerçek bağımsız repository: **https://github.com/Montaserissa20/leadcurrent**. İnkremental commitler mevcuttur. Eski uygulama aynı repository'ye eklenmedi.

## Yapamadıklarım

- Render hesabı bağlı olmadığı için genel URL ve üretim smoke testi henüz tamamlanmadı. Bu nedenle bütün kabul ölçütleri tamamlandı / 85 veya 100+ puan garanti iddiası yoktur.
- Fortune 500 tam nüfusunun aynı tarihli min/max değerleme ve çalışan aralığı belirlenemedi. Yaklaşık örneklem ve kurumsal SaaS benchmarkları açıkça ayrıldı.
- Ticari kullanım doğrulandı, müşterilerin gerçek lisans faturaları kamuya açık değil.
- Token/maliyet raporu sağlanmadı; gerçek agent USD gideri bilinmiyor.
- AI entegrasyonu, e-posta/telefon gönderimi, dış takvim entegrasyonu, password reset/MFA, hafta sonu hariç SLA ve drag-and-drop eklenmedi. Bunlar temel akışı durdurmaz.
- Liste sayfaları en fazla 100 eşleşme gösterir; büyük veri için gerçek sayfalama ve NBA sorgularının toplu optimizasyonu gerekir.
- Temas tamamlanması kullanıcı beyanıdır. Gelişmiş kurumsal güvenlik (SSO, DB-level RLS, merkezi rate limit, denetim dışa aktarımı) bu öğrenci sürümünün kapsamı dışındadır.

## Kaynakça

Tüm araştırma sayfaları 14 Ekim 2026'da kontrol edildi. Sayısal iddiaların doğrudan URL'leri ilgili tabloda bulunur. Ek başvuru:

- [Fortune sıralama yöntemi](https://fortune.com/ranking/fortune500/)
- [Zylo 2026 ve kapsamı](https://zylo.com/2026-saas-management-index)
- [CRM karmaşıklığı için EspoCRM](https://github.com/espocrm/espocrm), [SuiteCRM](https://github.com/salesagility/SuiteCRM)
- [Open Hub sayım aracı](https://openhub.net/tools)
- [Capterra doğrulanmış kullanıcı yorumları](https://www.capterra.com/p/61368/Salesforce/reviews/)
- [Rails 8.1.4 yayın bilgisi](https://rubyonrails.org/category/releases)
- [Render Rails 8 dağıtımı](https://render.com/docs/deploy-rails-8)

Sunum: [PRESENTATION_TR.md](docs/PRESENTATION_TR.md). Kural haritası: [REQUIREMENTS_TR.md](docs/REQUIREMENTS_TR.md). Kod ajanı rehberi: [AGENT.md](AGENT.md).
