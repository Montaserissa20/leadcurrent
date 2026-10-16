# LeadCurrent

[![LeadCurrent CI](https://github.com/Montaserissa20/leadcurrent/actions/workflows/ci.yml/badge.svg)](https://github.com/Montaserissa20/leadcurrent/actions/workflows/ci.yml)

## Proje Tanıtımı

LeadCurrent; müşteri adayını ilk temastan kazanılan satış fırsatına taşıyan, üniversite ödevi için geliştirilmiş bağımsız bir CRM SaaS uygulamasıdır. Özgün yeşil/krem görsel kimlik, logo, responsive arayüz, açık/koyu tema ve PostgreSQL kalıcılığı kullanır. Dashboard istatistikleri gerçek veritabanı sorgularından hesaplanır; USD, EUR ve TRY birbirine eklenmez.

**Pro geliştirmesi:** etkileşimli günlük satış merkezi, Customer 360 kişi/şirket/deal geçmişi, profil içinde düzenleme ve görev oluşturma, çağrı/toplantı/not kaydı, görev düzenleme/tamamlama ve filtreler, SQL tabanlı Analytics sayfası eklendi. Next Best Action bugün/gecikmiş takipleri de sıralar; görev tamamlama ve geçerli sonraki aşama işlemleri dashboard'a dönerek önerileri yeniler. Otomasyon kayıtlı verilerden hesaplanır; kendiliğinden satış durumu değiştirmez veya reminder kaydı üretmez. [Kısa ilerleme ve doğrulama kaydı](docs/UPGRADE_PROGRESS.md).

## Teknolojiler

Ruby 3.4.7, Rails 8.1.4, PostgreSQL 17, Hotwire/Turbo, Stimulus, Propshaft, Minitest, Capybara/Selenium, GitHub Actions; canlıda Railway/Docker, alternatif Render yapılandırması. Sürüm kanıtı: [Gemfile.lock](Gemfile.lock), [CI](.github/workflows/ci.yml). React, Redis, mikroservis veya AI sağlayıcısı temel işleyiş için gerekli değildir.

Eski Fixture projesi yalnızca salt okunur referanstır. Lisans dosyası bulunmadığı için uygulama kaynak kodu kopyalanmadı; eski veri/credential kullanılmadı. Yeni repository, DB, migration ve marka bağımsızdır. İnceleme: [OLD_PROJECT_INSPECTION.md](docs/OLD_PROJECT_INSPECTION.md).

## İlham Alınan SaaS

Salesforce Sales Cloud, satış ekiplerinin müşteri bilgilerini, adaylarını, fırsatlarını ve satış faaliyetlerini aynı sistemde yönetmesini sağlar. İşletmeler görünür bir satış hattı, zamanında takip, ekipler arasında bilgi sürekliliği ve ölçülebilir satış süreçleri için bu tür yazılımlar satın alır. LeadCurrent bu ekonomik değerin merkezi akışını uygular; aynı arayüzü veya marka kimliğini kopyalamaz. [Sales Cloud](https://www.salesforce.com/sales/cloud/).

## Fortune 500 Araştırması

Yeniden kontrol: **15 Ekim 2026**; ilgili liste **2026 Fortune 500**. Sıralama ölçütü gelirdir. Grubun toplam istihdamı yaklaşık **30,5 milyon**. [Fortune 500](https://fortune.com/ranking/fortune500/).

Gelir, dönem içindeki satış hasılatıdır. Market capitalization, halka açık özsermayenin piyasa değeridir. Enterprise value borç/nakit düzeltmeleri içerir. Özel şirket değerlemeleri borsa değeriyle aynı ölçüm değildir. Bu çalışma bu kavramları birbirinin yerine kullanmaz.

| Metrik | Minimum | Maksimum / Ortalama | Kaynak | Açıklama |
|---|---|---|---|---|
| Değerleme yerine halka açık şirket piyasa değeri proxy'si | Gözlenen örnek: Gold.com **1,128 milyar USD**, 31 Mart 2026 | Gözlenen örnek: NVIDIA **5,445390 trilyon USD**, 24 Eylül 2026 | [Gold.com](https://fortune.com/company/a-mark-precious-metals/), [NVIDIA](https://fortune.com/company/nvidia/) | Tam nüfus uçları değil; farklı tarihli özsermaye piyasa değerleri. Özel şirket değerlemeleri ve enterprise value dahil değil |
| Çalışan sayısı | Gözlenen örnek: Gold.com **975** | Gözlenen örnek: Walmart **2.100.000** | [Gold.com](https://fortune.com/company/a-mark-precious-metals/), [Walmart](https://fortune.com/company/walmart/) | Kesin nüfus min/max değil; raporlama dönemleri farklı şirket profilleri |
| Şirket başına SaaS uygulaması | Fortune 500 nüfus minimumu yayımlanmıyor | Zylo örnekleminde **ortalama 305**, **medyan 240** | [Zylo 2026](https://zylo.com/2026-saas-management-index) | Kurumsal benchmark; Fortune 500'e özel ölçüm değil |
| Şirket başına yıllık SaaS harcaması | Fortune 500 nüfus minimumu yayımlanmıyor | Zylo örnekleminde **ortalama 55,7 milyon USD/yıl**, **medyan 20,6 milyon USD/yıl** | [Zylo 2026](https://zylo.com/2026-saas-management-index) | Kurumsal benchmark; şirket faturası veya Fortune 500 ortalaması değil |

**Aralıkların sınırı:** erişilebilen üye örneklerinde çalışan sayısı 975–2.100.000, piyasa değeri yaklaşık 1,128 milyar–5,445 trilyon USD ölçeğindedir. Bu, 500 şirketin tamamının kanıtlanmış minimum/maksimum aralığı değildir. Piyasa değerlerinin ölçüm tarihleri de farklıdır. Özel üyelerin aynı tarihli değerlemesi açık olmayabilir; tüm üyeleri kapsayan tek bir değerleme aralığı kurulamadı. Çalışan aralığının kesin alt sınırı da tam nüfus verisi olmadan iddia edilmez. Örneklerin amacı tek şirket yerine grubun farklı ölçeklerini görünür kılmaktır.

Zylo verisi Fortune 500 nüfus sayımı değildir; yönetilen müşteri portföylerinden oluşan kurumsal benchmarktır. Fortune 500 başına ortalama uygulama sayısı/abonelik bedeli olarak sunulmaz. Büyük bir kurum için yüzlerce uygulama ve onlarca milyon USD/yıl ancak bu benchmarka dayanan yaklaşık planlama ölçeğidir. [Zylo metodoloji açıklaması](https://zylo.com/2026-saas-management-index).

## Fortune 500 Kullanım Kanıtları

| Şirket | Kullanım kanıtı | Fortune 500 doğrulaması | Kanıtın sınırı |
|---|---|---|---|
| Ford Motor | [Resmî müşteri hikâyesinde](https://www.salesforce.com/ca/customer-stories/ford-reinventing-customer-experience/) Products Used bölümünde Sales Cloud ve metinde müşteri verisi/sipariş iletişimindeki kullanım açıkça belirtilir | [Fortune profili](https://fortune.com/company/ford-motor/): 2026, sıra 22 | 2022 dönüşümünü anlatır. Ticari müşteri kullanımı kanıtıdır; güncel lisans bedeli veya fatura yayımlanmaz |
| American Express | [Resmî müşteri hikâyesi](https://www.salesforce.com/customer-success-stories/american-express/) ortaklığın 2010 yılında Sales Cloud ile başladığını söyler | [Fortune profili](https://fortune.com/company/american-express/) 2026 Fortune 500 üyeliğini gösterir | Tarihsel ürün kullanımı doğrulanır; 2026 sözleşme kapsamı/bedeli açıklanmaz |

[T-Mobile hikâyesi](https://www.salesforce.com/ca/customer-stories/t-mobile/) de Sales Cloud ile pipeline yönetimini açıkça doğrular. Ancak 2016 dönemi içerir; erişilen [Fortune profili](https://fortune.com/company/t-mobile/) güncel Fortune 500 üyeliğini yeterince doğrulamadığından bunu kabul kanıtı tablosuna dahil etmedim.

**Ödeme ayrımı:** ticari müşteri hikâyeleri ürün kullanımını doğrular; açıklanmayan bir kontrat fiyatını veya fatura tutarını kanıtlamaz. Burada “kesin şu bedeli ödüyorlar” iddiası yoktur.

## SaaS Kod Satırı Tahmini

Salesforce kapalı kaynak olduğundan gerçek satır sayısı kamuya açık değildir. Sayı uydurulmaz. Açık kaynak CRM karşılaştırması:

| Ürün | Kod satırı / toplam fiziksel satır | Analiz ve veri tarihi (UTC) | Kaynak |
|---|---|---|---|
| EspoCRM | 404.831 kod / 678.466 toplam | Analiz: 14 Ekim 2026 02:59:36; veri: 13 Ekim 2026 02:39:29 | [Open Hub dil dökümü](https://openhub.net/p/espocrm/analyses/latest/languages_summary), [repository](https://github.com/espocrm/espocrm) |
| SuiteCRM | 788.846 kod / 1.236.108 toplam | Analiz: 14 Ekim 2026 06:26:00; veri: 13 Ekim 2026 05:38:08 | [Open Hub dil dökümü](https://openhub.net/p/suitecrm/analyses/latest/languages_summary), [repository](https://github.com/salesagility/SuiteCRM) |

Open Hub, Ohcount ile kod/yorum/boş satırları ayırır. [Yöntem](https://openhub.net/tools). Depo kapsamı, dahil edilen bağımlılıklar ve dil sınıflandırması ölçümü etkileyebilir; LOC işlev veya kalite ölçüsü değildir. Eski arama önbelleklerindeki sayılar yerine doğrudan erişilen güncel dil sayfaları kullanıldı.

**Açıkça etiketlenmiş ölçek tahmini:** yaklaşık 0,4–0,8 milyon kod satırlık olgun CRM karşılaştırma bandı, 300.000+ satır sınıfındaki kurumsal CRM karmaşıklığına işaret eder. Bu Salesforce kaynak kodunun ölçümü, alt sınırı veya kesin tahmini değildir. Salesforce'un çoklu tenant, entegrasyon, satış, analiz ve yetkilendirme kapsamı bu sınıfla nitel olarak karşılaştırılabilir. LeadCurrent, bu ürünlerin tüm kapsamı yerine seçilen iş akışını uygular.

Bu ürünün kurumsal ölçek seçim gerekçesi; [resmî ürün sayfasındaki](https://www.salesforce.com/sales/cloud/) lead, account/opportunity, activity, pipeline ve raporlama kapsamı ile ölçülmüş olgun CRM referanslarıdır. Orijinal kapalı kod için savunulabilir bir nokta tahmini veya kanıtlanmış satır alt sınırı yoktur. Öğretmen doğrudan orijinal kaynak sayımı isterse bu kanıt mevcut değildir. Open Hub sayıları 15 Ekim'de yeniden kontrol edildi; tabloda hizmetin bildirdiği analiz/veri tarihleri korunmuştur.

## Geliştirme Süresi ve Maliyet Tahmini

Planlama varsayımı: bir haftalık öğrenci projesinde 5 gün × günde 6 odaklı saat = **30 saat**; yaklaşık 6 saat analiz/kurulum, 12 saat iş akışı, 6 saat test/arayüz, 6 saat araştırma/dağıtım. Bu, piyasa araştırması veya gerçekleşmiş insan çalışma saati değildir.

**Tablo A — Tahmini geliştirme maliyetleri.** Aşağıdaki token ve süreler bütçe varsayımıdır; gerçekleşmiş kullanım değildir. Fiyat kontrolü: **15 Ekim 2026**. USD liste fiyatları vergi, kur farkı, araç çağrısı ve ilave kredi bedellerini içermez.

| Kalem | Tahmin / hesap varsayımı | USD tutarı | Kaynak / sınır |
|---|---|---|---|
| Agent destekli geliştirme süresi | Analiz + kod + test + belge için 30 odaklı saat | İnsan emeğine parasal değer atanmadı | Proje planı varsayımı; modelin çalışır durumda kaldığı ölçülmüş süre değil |
| Takvim süresi | Günde 6 saat ile 5 çalışma günü; yaklaşık 1 hafta | — | Planlama varsayımı |
| Toplam token bütçesi | Tüm iterasyonlar ve tekrarlanan bağlam dahil **2.000.000 input + 500.000 faturalanabilir output** | Aşağıda hesaplanır | Projeye ait tahmin; ölçülmüş token sayısı değil |
| GPT-5.4, Standard API | 1 milyon input **2,50 USD**, output **15 USD**; `2 × 2,50 + 0,5 × 15` | **12,50 USD / proje** | [Resmî model fiyatı](https://developers.openai.com/api/docs/models/gpt-5.4); cached input indirimi varsayılmadı; her isteğin input'u en fazla 272K |
| GPT-6.1 Sol, Standard kısa bağlam API alternatifi | 1 milyon input **2 USD**, output **10 USD**; `2 × 2 + 0,5 × 10` | **9,00 USD / proje** | [Resmî model fiyatı](https://developers.openai.com/api/docs/models/gpt-6.1-sol), [tarife](https://developers.openai.com/api/docs/pricing); cache/write kullanımı yok varsayımı |
| Token belirsizliği, GPT-5.4 | 1M/0,25M ile 4M/1M input/output senaryoları | **6,25–25,00 USD** | Aynı fiyatlarla türetilmiş duyarlılık hesabı; süre garantisi değil |
| Abonelik alternatifi: ChatGPT Plus + Codex | **20 USD/ay**; Pro **100 / 200 / 500 USD/ay** seçenekleri | Bir aylık abonelik; proje token tutarı değil | [Resmî abonelik fiyatı](https://learn.chatgpt.com/docs/pricing). Limitler ve model erişimi plana bağlı; API senaryolarıyla aynı model/kota varsayılmaz |
| Ek geliştirme giderleri | Haricî görsel, alan adı ve e-posta servisi satın alınmadığı bütçe senaryosu | **0 USD planlanan ek satın alma** | Plan kapsamı; gerçekleşmiş toplam gider iddiası değil. Bilgisayar/elektrik/insan emeği dahil değil |
| Render Free demo dağıtımı | Free web + Free Postgres; kota ve süre kısıtlarıyla | **0 USD/ay liste compute bedeli** | [Free plan](https://render.com/docs/free), [fiyat](https://render.com/pricing); veritabanı 30 gün sonra sona erer |
| Render ücretli alternatif | Küçük web **7 USD/ay** + Postgres compute **6 USD/ay** | **13 USD/ay compute alt toplamı**, disk/traffic/vergi eklenir | [Render'ın resmî Rails maliyet rehberi](https://render.com/articles/production-rails-hosting-guide), [fiyat](https://render.com/pricing) |

API matematiği: `(input / 1.000.000 × input fiyatı) + (output / 1.000.000 × output fiyatı)`. Output bütçesi faturalanan reasoning tokenlarını da kapsamalıdır. Uzun bağlam, Fast/Ultrafast, bölgesel işlem ve ücretli araçlar ek maliyet doğurabilir. GPT-5.4 için uzun input ek tarifesi bulunduğundan belirtilen istek sınırı önemlidir. API veya abonelik senaryoları **alternatiftir**, toplanmaz. Bir haftalık projeye aylık aboneliğin kesirli bedeli fatura gibi yazılmaz.

## Gerçekleşen Geliştirme Maliyeti

**Tablo B — Gerçekleşen geliştirme maliyetleri.** Kanıt: [başlangıç commit'i](https://github.com/Montaserissa20/leadcurrent/commit/96bd09f63c339b669188d29d2bce1491829f5b0e), [ilk teslimin son commit'i](https://github.com/Montaserissa20/leadcurrent/commit/9949b3d8bb65e1ff1703b63f0cd6f032511faedf), [gider kayıt sınırları](docs/COSTS_TR.md).

| Kalem | Gözlenen gerçek bilgi | Kanıt / eksik kayıt |
|---|---|---|
| Takvim tarihleri | İlk geliştirme/teslim Git kayıtları **14 Ekim 2026**; bu belge/güvenlik denetimi **15 Ekim 2026** | Commit tarihleri ve bu denetimin kayıtları. İlk commit'ten önceki başlangıç saati doğrulanamaz |
| İlk teslimin commit zaman aralığı | 14 Ekim **16:57:57–17:17:48 +03:00** | Yukarıdaki iki commit; bu aralık toplam çalışma süresi değildir |
| Gerçek odaklı çalışma saati / agent çalışma süresi | **Kesin kullanım veya ödeme verisi mevcut değil.** | Timesheet veya güvenilir çalışma-süresi dökümü yok; 30 saat gerçekleşmiş gibi sunulmaz |
| Gerçekte kullanılan araç/model | Oturum bağlamında Codex ile geliştirildi; faturalandırılan model kimliği doğrulanamadı | Repo/billing içinde doğrulanabilir model kullanım dökümü yok; fiyat senaryosundaki modeli kullanılmış saymayın |
| Ödenmiş abonelik bedeli | **Kesin kullanım veya ödeme verisi mevcut değil.** | Makbuz veya hesap billing raporu sağlanmadı |
| Gerçek input/output ve API tahsilatı | **Kesin kullanım veya ödeme verisi mevcut değil.** | Tahmini 2M/0,5M token gerçek ölçüm değildir |
| Gerçek hosting/alan adı/diğer tahsilatlar | **Kesin kullanım veya ödeme verisi mevcut değil.** | Bu agent oturumlarında ücretli satın alma/Render deploy başlatılmadı; bu gözlem kullanıcının toplam hesap faturasını doğrulamaz |
| Toplam gerçekleşen USD maliyeti | **Kesin kullanım veya ödeme verisi mevcut değil.** | Bilinmeyen gider sıfır yazılmadı |

Karşılaştırma: **9,00 / 12,50 USD**, aynı varsayımsal token bütçesinin farklı modellerle API tahminidir; **20 USD/ay** ayrı bir abonelik alternatifidir. Gerçek billing ve saat kaydı olmadığı için tahminin altında/üstünde harcandığı veya zaman kazancı ölçüldüğü söylenemez. Uygulamanın çalışan CRM özelliğinde AI sağlayıcısı bulunmaması, geliştirme agent'ının ücretsiz olduğu anlamına gelmez.

## Aort Dilimi

**New Lead → tamamlanmış müşteri teması → Contacted → Qualified → Opportunity / Qualification → Proposal → Negotiation → Won / Lost.**

Lead oluşturma şirket ve kişi kayıtlarını aynı işlemde oluşturur. Sahip atanır. Temas/not kaydı ve takip planlama gerçek DB yazmalarıdır. Qualified dönüşümü bağlı şirket, kişi, sahip ve lead ilişkilerini korur; bekleyen lead görevleri fırsata aktarılır. Satış kapanışı zaman damgası ve audit kaydı üretir. Kanban yalnızca izin verilen sonraki aşamaları sunar; drag-and-drop yerine güvenilir form geçişleri kullanır.

## Zaman Kuralı

İlk müşteri teması, kaydın oluşturulmasından itibaren **24 gerçek saat** içinde tamamlanmalıdır. Nitelikli olay: salesperson'ın fiilen tamamladığı çağrı, toplantı veya müşteriye gönderilmiş mesaj için `contact` aktivitesi kaydetmesi. Bu bir kullanıcı beyanıdır; telefon/e-posta sağlayıcısından teslimat doğrulaması yapılmaz. Not, gelecekteki randevu ve görev tamamlama ilk teması karşılamaz.

Deadline DB'de saklanır. Tam deadline anı zamanında kabul edilir; bir saniye sonra gecikir. İlk temas tamamlanınca gecikme kalkar; sonraki temaslar ilk zamanı değiştirmez. Tarihler DB'de UTC, arayüzde profil saat dilimindedir. Gece yarısı ve DST testleri vardır. Süre `24.hours`, takvim günü değildir.

Değişiklik yeri: [FollowUpDeadline](app/services/follow_up_deadline.rb#L2) `FIRST_CONTACT_WINDOW`, `deadline`, `overdue?`. İlk temas işleme: [RecordActivity.call](app/services/record_activity.rb). Gerçek `travel_to` testleri: [deadline_test.rb](test/models/deadline_test.rb#L12). Worker veya AI gerekmez.

## Durum Geçişleri

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

## Kullanıcı Yorumu ve Çözüm

Capterra, **khyan A.**, Senior Business Development Representative, Computer Software; **15 Mart 2026**, “Powerful but heavy - great once it’s set up properly”. Platform Verified User olarak işaretler; yorum non-incentivized olarak listelenir. Kısa özgün alıntı: **“The main downside is the complexity and cost.”** Arayüzün çok sayıda alan/iş akışıyla kalabalıklaşabilmesi ve başlangıçta sezgisel olmaması eleştiriliyor. [Doğrulanan yorum sayfası](https://www.capterra.com/p/61368/Salesforce/reviews/).

**Çözüm: Next Best Action.** Gecikmiş ilk temas, yaklaşan deadline, 72 saatlik fırsat durgunluğu ve yaklaşan kapanış deterministik olarak sıralanır. Her öneri nedenini açıklar. Dashboard formu tamamlanmış teması ve takip görevini **tek gönderimde** kaydeder. Sadece takip planlama ilk temas deadline'ını kapatmaz. [Öncelik servisi](app/services/next_best_action.rb), [eylem endpoint'i](app/controllers/actions_controller.rb), [testler](test/models/next_best_action_test.rb).

Pro öncelikleri: gecikmiş temas 100, gecikmiş görev 95, dört saat içinde temas 90, bugünkü görev 85, 72 saat hareketsiz fırsat 80, yedi gün içinde kapanış 70, yeni temas 50. Aynı kayıt için en öncelikli öneri gösterilir; en fazla sekiz öneri vardır. Bugünün sınırı kullanıcının saat dilimidir. Uygun kayıtlar SQL'de sınırlandırılır, ilişkiler eager load edilir. Planlı takip bulunan fırsata ikinci otomatik planlama önerilmez; aynı başlık/tarihteki pending takip tekrar gönderilirse aynı görev kullanılır.

15 Ekim denetiminde yorumun yazar/tarih/şikâyet bilgisi Capterra'nın arama indeksindeki ayrıntıyla yeniden eşleştirildi; doğrudan sayfa açılışı araçta içerik-türü hatası verdi. Bu erişim sınırı [kaynak kontrol kaydında](docs/RESEARCH_AUDIT_TR.md) tutulur. Başka yorumcunun “fazla tıklama” cümlesi bu kişiye atfedilmedi. Salesforce'un [resmî sayfası](https://www.salesforce.com/sales/cloud/) da önceliklendirme ve süreç araçlarını listeler; LeadCurrent'ın iddiası sade bir günlük akış sunmaktır, rakipte ilgili özelliklerin bulunmadığı değildir.

**Ölçülen akış:** dashboard zaten açıkken varsayılan yarın takip zamanı korunursa “What happened?” alanına odaklanma 1 tıklama, sonuç yazma, “Save action” 1 tıklama: **2 fare tıklaması, 1 submit, 0 ek sayfa navigasyonu**. Klavye ile odaklanılırsa fare sayısı daha düşük olabilir. Farklı tarih seçimi ek etkileşim gerektirir. Gerçek Selenium testi bu formu doldurup tek submit ile Activity/Task kalıcılığını doğrular. Salesforce için karşılaştırmalı tıklama sayısı ölçülmedi; ürünler arası sayısal üstünlük iddiası yoktur.

## Güvenlik

CSRF, bcrypt, süreli DB session, production secure/HttpOnly/SameSite cookie, SSL ve workspace/sahip yetkisi kaynakta kontrol edildi. Ayrıntılı bulgular, tarama kapsamı, iki dar kapsamlı Gitleaks yanlış-pozitif değerlendirmesi ve manuel müdahale sınırları: [SECURITY_AUDIT.md](docs/SECURITY_AUDIT.md).

Public GitHub ana dalında `config/master.key`, production key ve `.env` için 404; görünür path geçmişinde kayıt yok. Yerel anahtar ve PostgreSQL verisi korunmuştur. **Çalışma klasörünü doğrudan ZIP'lemeyin:** `.gitignore` bir klasör ZIP'inin içeriğini filtrelemez. Yalnızca gözden geçirilip commit edilmiş kaynak için `bundle exec ruby script/package_source.rb` kullanın. Script Git ağacını, dosya adlarını ve içerikleri doğrular; anahtar, DB, log/cache veya Git metadata içeren paketi reddeder. Çıktı `.local/packages/` içinde oluşur. Paketleme negatif testleri ve gerçek paylaşım adımları güvenlik raporundadır.

Önceden anahtar/DB içeren bir paket dışarıya verildiyse ignore düzeltmesi bu kopyaları veya geçmişi temizlemez. Kopyanın geri çekilmesi, etkilenmiş sırların belirlenmesi ve etki analizi sonrası yetkili rotasyon gerekir. Bu denetimde anahtar silinmedi/değiştirilmedi; veri veya Git geçmişi yeniden yazılmadı. 16 Ekim Railway testinde fresh-session CSP nonce ve Turbo style sorunu dar kapsamlı olarak düzeltildi; redeploy sonrası header/browser kontrolü geçti. [Üretim raporu](docs/PRODUCTION_TEST_REPORT.md).

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

## Testler ve GitHub Actions

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

15 Ekim denetiminde aynı suite yeniden çalıştırıldı: **39 test, 425 assertion, sıfır failure/error/skip**; Zeitwerk ve Brakeman tekrar geçti. Denetim commit'i `845bef9` için [gerçek LeadCurrent CI run'ı](https://github.com/Montaserissa20/leadcurrent/actions/runs/38742014762) success olarak doğrulandı. Paketleme, hash ve tarama kayıtları: [AUDIT_VERIFICATION_TR.md](docs/AUDIT_VERIFICATION_TR.md).

**Pro sürümünün son yerel kontrolü:** 53 model/service/HTTP testi ve 5 gerçek browser testi; toplam **58 test, 588 assertion, sıfır failure/error/skip**. Customer 360, görev CRUD/tamamlama, otomasyon zaman sınırları, NBA eylemleri, SQL metrikleri, tenant/owner yetkisi ve 390px mobil görünüm dahil. Güncel upgrade/CI kaydı: [UPGRADE_PROGRESS.md](docs/UPGRADE_PROGRESS.md). Önceki doğrulama raporlarının test sayıları tarihî snapshot'lardır.

**16 Ekim 2026 son kontrol:** CSP regresyonları dahil **54 domain/HTTP testi / 547 assertion + 6 gerçek browser testi / 54 assertion = 60 test, 601 assertion**; sıfır failure/error/skip. Zeitwerk, Brakeman (0 warning/error) ve production assets geçti. Ayrıca localhost yerine gerçek Railway URL'sinde **26/26 browser vakası** geçti; 542 gözlenen response içinde 5xx yok. [CSP düzeltmesi için doğrulanmış CI run'ı](https://github.com/Montaserissa20/leadcurrent/actions/runs/38914594060) success. Son doküman commit'inin CI sonucu ve test kapsamı [PRODUCTION_TEST_REPORT.md](docs/PRODUCTION_TEST_REPORT.md) teslim kaydındadır.

CI PostgreSQL servisini başlatır, migrate eder, domain/HTTP/browser testlerini, Zeitwerk, Brakeman ve asset build'i çalıştırır. Badge yukarıdaki gerçek repository/workflow'ya aittir; son durum Actions sayfasından kontrol edilmelidir. En son kontrol edilen commit/run ayrıca doğrulama raporunda kayıtlıdır.

## Canlı Uygulama

**Canlı Railway URL:** https://leadcurrent-production.up.railway.app

**Durum: PASS — 16 Ekim 2026, 17:21–17:24 Europe/Istanbul** tam browser turu. `/up` HTTP 200 ve `database=connected`; login/signup, izole QA workspace, lead → completed contact → qualified → opportunity → Proposal → Negotiation → Won, dashboard/analytics ve logout/login sonrası kalıcılık gerçekten test edildi. NBA upcoming/overdue task, tamamlama/contact ve stage eylemleri; Customer 360, USD/EUR ayrımı, tema, mobil ve organizasyon/owner yetkisi geçti. Üretim saati değiştirilmedi; 24/72 saat sınırları yerel/CI `travel_to` testleriyle doğrulandı.

Bulunan CSP sorunu push sonrası canlıda yeniden test edildi; dolu script/style nonce ve fresh browser'da sıfır CSP ihlali doğrulandı. Railway panelindeki deployment ID/uzak Git SHA için erişim yoktur; public uygulamanın yeni davranışı gözlendi, panel durumu tahmin edilmedi.

- [Üretim test raporu ve redakte kanıt](docs/PRODUCTION_TEST_REPORT.md)
- [Ödev gereksinimleri: PASS / PARTIAL / BLOCKED](docs/ASSIGNMENT_CHECKLIST.md)
- [Beş dakikalık son sunum](docs/FINAL_PRESENTATION_TR.md)
- [Railway doğrulaması ve alternatif Render tarifi](docs/DEPLOYMENT_TR.md)

Yerel `127.0.0.1` adresi canlı yayın değildir. [render.yaml](render.yaml) ve Render maliyet satırları korunmuş alternatiflerdir; bu canlı hizmetin planı/faturası olarak yorumlanmamalıdır. Mevcut üretim sırları veya demo/customer verisi bu çalışmada değiştirilmedi.

## GitHub Deposu

Gerçek bağımsız repository: **https://github.com/Montaserissa20/leadcurrent**. İnkremental commitler mevcuttur. Eski uygulama aynı repository'ye eklenmedi.

## Yapamadıklarım

- Railway public akış doğrulandı; deployment panelindeki uzak release SHA/ID, backup/restore, yük testi ve uzun süreli uptime bu testle doğrulanmadı. [Ödev kontrol listesindeki](docs/ASSIGNMENT_CHECKLIST.md) PARTIAL kalemleri nedeniyle bütün kabul ölçütleri tamamlandı / puan garantisi iddiası yoktur.
- Fortune 500 tam nüfusunun aynı tarihli min/max değerleme ve çalışan aralığı belirlenemedi. Yaklaşık örneklem ve kurumsal SaaS benchmarkları açıkça ayrıldı.
- Ticari kullanım doğrulandı, müşterilerin gerçek lisans faturaları kamuya açık değil.
- Gerçek token/saat/fatura raporu sağlanmadı; agent USD gideri bilinmiyor. Sayısal tahmin ve gerçekleşen kayıt eksikleri ayrı tablolardadır.
- AI entegrasyonu, e-posta/telefon gönderimi, dış takvim entegrasyonu, password reset/MFA, hafta sonu hariç SLA ve drag-and-drop eklenmedi. Bunlar temel akışı durdurmaz.
- Liste sayfaları en fazla 100 eşleşme gösterir; büyük veri için gerçek sayfalama ve NBA sorgularının toplu optimizasyonu gerekir.
- Temas tamamlanması kullanıcı beyanıdır. Gelişmiş kurumsal güvenlik (SSO, DB-level RLS, merkezi rate limit, denetim dışa aktarımı) bu öğrenci sürümünün kapsamı dışındadır.

## Kaynakça

Kaynaklar 15 Ekim 2026 denetiminde yeniden kontrol edildi; doğrudan erişim/arama indeksi ayrımı ve ulaşılamayan sayfalar [RESEARCH_AUDIT_TR.md](docs/RESEARCH_AUDIT_TR.md) içinde kayıtlıdır. Sayısal iddiaların doğrudan URL'leri ilgili tabloda bulunur. Ek başvuru:

- [Fortune sıralama yöntemi](https://fortune.com/ranking/fortune500/)
- [Zylo 2026 ve kapsamı](https://zylo.com/2026-saas-management-index)
- [CRM karmaşıklığı için EspoCRM](https://github.com/espocrm/espocrm), [SuiteCRM](https://github.com/salesagility/SuiteCRM)
- [Open Hub sayım aracı](https://openhub.net/tools)
- [Capterra doğrulanmış kullanıcı yorumları](https://www.capterra.com/p/61368/Salesforce/reviews/)
- [Rails 8.1.4 yayın bilgisi](https://rubyonrails.org/category/releases)
- [Render Rails 8 dağıtımı](https://render.com/docs/deploy-rails-8)
- [OpenAI API tarifesi](https://developers.openai.com/api/docs/pricing), [GPT-5.4](https://developers.openai.com/api/docs/models/gpt-5.4), [GPT-6.1 Sol](https://developers.openai.com/api/docs/models/gpt-6.1-sol)
- [Codex / ChatGPT abonelik listesi](https://learn.chatgpt.com/docs/pricing)
- [Render fiyat listesi](https://render.com/pricing), [resmî Rails barındırma maliyeti](https://render.com/articles/production-rails-hosting-guide)

Sunum: [PRESENTATION_TR.md](docs/PRESENTATION_TR.md). Kural haritası: [REQUIREMENTS_TR.md](docs/REQUIREMENTS_TR.md). Kod ajanı rehberi: [AGENT.md](AGENT.md).
