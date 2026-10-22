# LeadCurrent Phase 2 — Veritabanını bilen Copilot

**22 Ekim güncellemesi:** aşağıdaki 21 Ekim sonuçları tarihsel finalizasyon kaydıdır. Yeniden otomasyon, gerçek Docker production smoke, sınırlı Groq kabulü ve kalan sınırlar için [güncel release-readiness raporunu](PHASE2_RELEASE_READINESS.md) okuyun. Yeni feature/Phase3, GitHub push veya Railway deploy yapılmadı.

21 Ekim 2026. Yalnız yerel `phase2/page-agent` dalı. Phase 2 başlangıcı ve finalizasyon öncesi HEAD: `65bcd55cfbd55ca1d91691bb1d873e0560fd76b0`. HEAD aynı olsa da finalizasyon **268 dosyalık, commit edilmemiş çalışan Phase 2.1 kaynak ağacından** başladı; GitHub'daki Phase 1 sürümüne dönülmedi. İnceleme paketi tamamlanan yerel commit'ten üretilir; gerçek SHA teslim mesajında, ZIP adında ve Git archive metadata'sındadır. Push/deploy yetkisi yoktur.

**Durum: yerel kod incelemesine hazır; Phase 2 tam canlı kabulü BLOCKED.** Final otomasyon **166 test / 2205 assertion**, sıfır hata/başarısızlık/skip. İstenen 10 senaryo türünün her biri geliştirme sırasında en az bir gerçek geçişte başarılı oldu; bu, son kaynakta tek kesintisiz başarılı run değildir. Son 10-alanlı schema run'ı ilk **5/13** senaryodan sonra Groq TPD kotasına takıldı. Üç ek team paraphrase canlıda çalıştırılamadı. Phase 2 tamamen doğrulandı/tamamlandı veya yayına hazır iddiası yoktur; kota toparlandıktan sonra son canlı kabul tekrar gerekir.

## Gözlenen sorun ve karar

Kullanıcı “How many users are they in the team?” sorusunda “I don't have real-time access to the team roster” yanıtını aldı. Bu bir bağlantı hatası değildi: planner'ın kapalı sorgu enum'unda team bilgisi yoktu. Model genel yardım yoluna gitti. Settings ekranı her iki role kendi organizasyonunun kayıtlı üyelerini gösteriyor; yalnız üye ekleme manager'a ait. Yeni özet aynı okuma politikasını izler, isim/e-posta/parola/session satırlarını açıklamaz.

**Karar: continue.** Çalışan tenant izolasyonu, satış hizmetleri, gerçek Groq ve resmî Page Agent korunur. Gözlenen eksikliği dar okuma yetenekleriyle gidermek, yeniden CRM/agent yazmaktan daha küçük ve doğrulanabilir bir değişikliktir. Phase 3 uygulanmaz. Bu, gerçek LLM anlama + yetkili DB cevabı + DOM etkileşimi + insan denetimindeki yazmaları birleştiren öğrenci uygulamasıdır. Salesforce'ta benzer fikirlerin olmadığı veya CRM sektöründe benzersiz olduğu iddia edilmez.

## Model ve araç seçimi

`Copilot::Planner` mevcut server-only `PageAgent::GroqClient.plan` transport'u ile `openai/gpt-oss-20b` kullanır. Strict JSON schema ve yerel anahtar/tip/enum/boyut doğrulaması sürer. Model niyeti ve sınırlı parametreleri seçer; Rails yetkiyi, sorguyu, sayıyı, tarihleri ve gösterilen kayıtları belirler. Veri yanıtında modelin serbest `answer` metni kullanılmaz. Yeni bir provider, yerel LLM, gem, migration veya GPU yoktur. Phase 1'in mevcut model konfigürasyonu/transport'u korunur; Page Agent'ın server-owned model kuralı değiştirilmez.

Planner sampling'i `temperature=0` olarak sabitlendi; yaratıcı metin yerine daha odaklı routing amaçlanır. [Groq API referansı](https://console.groq.com/docs/api-reference) Chat temperature aralığını 0–2, varsayılanını 1 olarak belgeler. Bu, her niyetin her zaman doğru sınıflandırılacağı garantisi değildir. HTTP endpoint/TLS/timeouts/token cap/anahtar aktarımı değişmedi; Page Agent tool transport'u ve Phase 1 client sampling'i değiştirilmedi.

Canlı uzun konuşmada JSON generation hatasının güvenli tanısı alındı: dönen nesne geçerli JSON ve 10 alanlıydı, fakat eski schema'nın zorunlu tuttuğu `navigate` alanı yoktu. Bu alan zaten `intent` ile aynı kararı tekrar ediyordu. Model schema'sından kaldırıldı; Rails `navigate = (intent == show_crm_data)` değerini kendisi türetir. Aynı bağlamla gerçek Groq planner tanısı daha sonra başarılı oldu; token cap artırılmadı, invalid JSON validation kapatılmadı. `json_validate_failed` güvenli/recoverable invalid-response hatası olarak sınıflanır; ham failed_generation içeriği uygulama log'una yazılmaz.

Tool protocol'deki eski “reflection fields” yönergesi kaldırıldı. Server goal'u doğruladığında yalnız `AgentOutput` içindeki `done` şekline odaklanan kısa bir completion policy kullanılır; bu durumda diğer browser araçları şemada yoktur ve yerel doğrulama da onları reddeder. SafeDom allowlist'i/genişlikleri, gerçek DOM kontrolü ve satış yazma sınırları değiştirilmez. Sağlayıcıda gözlenen tool-generation arızalarının tamamının tek nedeni kanıtlanmış değildir; başarısız denemeler kanıtta korunur.

| Sorgu | Yetkili kaynak ve davranış |
|---|---|
| `team_summary` | Organization-scoped User role counts; tüm ekip, mevcut kullanıcı dahil olup olmadığı açık. `any/manager/salesperson`; kayıtlı üyelik, online/active ölçümü değil |
| `lead_status` | Toplam/aşama bazlı lead sayısı; isteğe bağlı gerçek lead status |
| `leads`, `uncontacted_leads` | Atanmış/filtrelenmiş veya ilk teması tamamlanmamış açık lead'ler |
| `overdue_leads`, `attention_leads` | Mevcut scope/deadline; strictly overdue veya kullanıcının gün sonuna kadar ilk temas |
| `overdue_leads` içindeki `recommendation` | Konuşmadaki overdue alt kümesinde ilk eligible temas; aynı `NextBestAction` hizmetinin resmî önceliği, ayrı bir tekrar aracı yok |
| `opportunities` | Mevcut aşama, owner ve arama; gerçek sayı ve en fazla 10 link |
| `opportunity_summary` | Aşama sayıları, Won/Lost hariç aktif pipeline değeri; USD/EUR/TRY ayrı, kur dönüşümü yok |
| `inactive_opportunities` | Aktif fırsatlar; `NextBestAction::INACTIVITY_WINDOW` kullanılır, tam 72 saat dahil |
| `pending_tasks` | Kullanıcının saat diliminde all/today/overdue; tamamlanmışlar hariç |
| `customer_summary` | Ad/başlığa göre lead ve opportunity durumları; converted lead ve fırsat iki ayrı kayıt olarak açıkça belirtilir |
| `next_best_action` | Değişmeyen hizmetin resmî öncelikleri; yalnız üzerinde işlem yapmaya yetkili olunan kayıtlar |

Arbitrary SQL, model/kolon adı, record ID, URL, Ruby veya terminal seçimi yoktur. Parametreler sorguya göre de doğrulanır: örneğin team + Won, lead + manager, tarihsiz yetenek + today veya aramasız customer summary reddedilir. Arama ILIKE wildcard'ları escape edilir. İlişkili şirket/kayıt tekrar tenant scope'undan çözülür. DB arızası sıfır sonuç gibi gösterilmez.

## Konuşma, tarayıcı ve arayüz

Dört önceki bounded soru + doğrulanmış niyet tanımları tutulur; dönen ekip/CRM satırları Groq'ya tekrar gönderilmez. Team → “How many of them are salespeople?” ve overdue → “Which one needs attention first?” bağlamı model tarafından çözümlenir; her soru yeniden sorgulanır. Model tabanlı anlama korunur, örnek kelimeden rota seçen router eklenmez. Belirsizlikte açıklama istenir. Cache 2MB, idle 10 dakika/mutlak 30 dakika; organization/user/DB login session'a bağlıdır. Logout yalnız ilgili session'ın özel konuşma ve pending planlarını siler. Tam reload özel browser konuşmasını temizler; Turbo içinde güvenli biçimde korunur.

DB cevabı çoğunlukla **tek planner completion** ister; ikinci bir model sayı hesaplamaz veya DB cevabını yeniden yazmaz. Show komutlarında gerçek veri tarayıcı işinden önce gösterilir. Resmî Alibaba 1.12.4 `PageAgentCore`/`PageController`, gerçek kontrol token'ları, en fazla altı adım ve aynı GET formunda filtre batching korunur. Navigasyon, uygulanmış URL/filtre ve scoped hedef ile doğrulanır; modelin “done” sözü yeterli değildir. Mevcut UI'da tam karşılığı olmayan özetler navigasyon yapmış gibi sunulmaz.

“Open Atlas” gibi kaydı açma isteğinde aynı yetkili `customer_summary` önce kayıt türünü belirler. Böylece Opportunities üzerinde kalmış Negotiation filtresinde bir lead aramak yerine Page Agent'a doğru listeyi önce görünür linkten açması söylenir. Bu ayrı model çağrısı veya server-side navigasyon değildir: talimata URL/record ID eklenmez, gerçek DOM kontrolünü yine Page Agent seçer/çalıştırır. Sıfır sonuç açıkça bildirilir; birden fazla anlamlı eşleşmede kullanıcıdan linked kayıt seçmesi istenir. Provider'a DB satırları yerine yalnız zaten sorudaki arama ve gerekli liste türü gider.

Panel konuşmaya daha fazla alan ayırır; giriş alanı görünür kalır. Açıklama/örnek/Agent activity isteğe bağlı kapalı bölümlerdir. Kayıt linkleri escaped text ile gösterilir. Verified CRM data, AI explanation, browser observation ve doğrulanamayan durumlar ayrıdır. Ctrl/⌘+Enter gönderir, Escape paneli kapatıp odağı açma düğmesine döndürür. `aria-expanded`, `aria-busy`, mobil/light/dark kontrolleri bulunur. Stop/bounded 429 retry ve mevcut kota sınırları korunur.

## Güvenlik sınırı

CRM araçları salt okunurdur. Agent contact/activity/task/status/Won/Lost/ownership/account/password/delete/email submit edemez. Not yalnız izinli formda, `note` türünde ve boş follow-up tarihiyle hazırlanır; kaydetmek ayrı insan eylemidir. Login, zorunlu parola değişimi, CSRF, CSP ve SafeDom allowlist'leri korunur. Yalnız logout'ta özel konuşma temizliği için mevcut session controller'a dar bir çağrı eklenir; kimlik doğrulama algoritması değişmez.

GROQ_API_KEY yalnız server env'dedir. Ekip isimleri/e-postaları/role satırları ve DB sonuçları provider'a gönderilmez. Sorunun kendisi ve sınırlı önceki niyetler gönderilir; kullanıcı metni/görünür başlıklar hassas bilgi içerebilir, maskeleme anonimlik garantisi değildir. CRM serbest metni ve DOM güvenilmeyen veridir. Ham provider prompt/cevabı loglanmaz. Shared rate limits sürer; birden fazla worker için merkezi store hâlâ gerekir.

## Doğrulama ve kanıt

Ölçülmüş sonuçlar [yapılandırılmış finalizasyon kanıtında](evidence/phase2-finalization-2026-10-21.json) ve [CHALLENGE_LOG.md](../CHALLENGE_LOG.md) sonundadır. Önceki [Phase 1](AI_SALES_ASSISTANT_TR.md), [Phase 2](PAGE_AGENT_PHASE2_TR.md) ve [Phase 2.1](COPILOT_PHASE21_TR.md) kanıtları tarihsel olarak korunur. Mocked transport testleri modelin gerçek dil anlama yeteneğini tek başına kanıtlamaz; ayrı opt-in gerçek Groq browser run'ı bunu sınar.

Başlangıç: Rails seed 37289, **124 / 1692**; browser seed 5184, **25 / 351**; tümü başarılı. Son kaynakta Rails seed **38909: 139 / 1820**, browser seed **44039: 27 / 385**, tümü 0 failure/error/skip. Node locked build + npm audit 0 vulnerability, Zeitwerk, üretim asset precompile ve **120 Ruby / 12 JS** syntax kontrolü başarılı. Brakeman raporu 0 güvenlik uyarısı/hata; Windows Ractor/fork fallback mesajları saklanır. Dockerfile ve CI Node 22 + npm build, Ruby, PostgreSQL 17 ve final-stage mkdir gereksinimleri kaynakta incelendi. Docker Linux daemon erişilemediğinden container build başarısı iddia edilmez; uzak CI/deployment çalıştırılmaz.

Gerçek Groq: **16 run**, bunların 15'i eksik/başarısız, biri yalnız note diagnostic subset'inde **1 test / 12 assertion PASS**. Başarısız run'ların başarılı prefix'leri dahil **89 ölçülen completion**, **162847 prompt + 9310 completion = 172157 token** kaydedildi. Ayrı tanı çağrıları ve reddedilen cevaplar tam metered değildir; bu proje/hesap faturası veya ödenen bedel değildir. Son provider tanısı `TPD limit=200000, used=197642, requested=2419, Retry-After=27s` bildirdi; bu o andaki account-wide token bucket gözlemidir, kalan tüm kabul run'ının 27 saniyede yapılabileceği anlamına gelmez. Daha fazla canlı çağrı durduruldu.

Başarısızlıklarda gerçek bug ve dış limit ayrıldı: eşdeğer overdue period'un reddi; workspace bağlamının yeni “my” isteğine taşınması; read/show niyet karışması; yinelenen urgency aracı seçimi; filtrelenmiş yanlış listede Atlas aranması; HTTP400/tool generation ve eksik navigate; yerel/provider 429. Düzeltilen schema/intent/type-hint/policy davranışları unit/HTTP/browser regresyonlarıyla kapsanır. Sağlayıcı tool-generation hatalarının tamamına tek kök neden atanmıyor. Kotalar kapatılmadı, invalid-output retry eklenmedi. Test harness mevcut kota pencerelerini okuyup sorular arasında bekler; bu beklemeler request süresinden ayrı kaydedilir. Son kaynakta kesintisiz gerçek kabul yeniden yapılmalıdır.

Son kaynakla mevcut development login, dashboard, Leads/Opportunities/Tasks/Analytics ve her iki AI arayüzü gerçek browser'da açıldı; bu smoke check yeni canlı AI cevabı istemedi. `/up` HTTP200/database connected. Önce/sonra karşılaştırmada development'ın session dışındaki tüm tablo içerikleri aynı: **2 user, 7 lead, 4 opportunity**. Reset/drop/seed/migration yapılmadı. [Gerçek kurgusal test ekranı](evidence/phase2-team-2026-10-21.png) 3 kayıtlı üyeyi, 1 manager/2 salesperson ve online durumunun bilinmediğini gösterir; production kanıtı değildir.

İlk ek test koşusunda projede kabul edilmeyen IANA time_zone adı kullanıldı; test mevcut Rails timezone adıyla düzeltildi. İlk hedefli browser CLI çağrısındaki Windows argüman hatası test çalışmadan çıktı; doğru dosya argümanıyla testler gerçekten koşuldu. Bunlar ürün başarı testi olarak sayılmaz.

## Yerel kullanım ve Türkçe sunum

```powershell
Set-Location D:\LeadCurrent
powershell -ExecutionPolicy Bypass -File bin/local-postgres.ps1 -Action start
npm ci --ignore-scripts
npm run build
$env:GROQ_API_KEY = [Environment]::GetEnvironmentVariable('GROQ_API_KEY','User')
bundle exec rails server -b 127.0.0.1 -p 3100
```

3100 portunda sunucu zaten açıksa ikinci sunucu başlatmayın. PostgreSQL startup yardımcısı mevcut cluster'ı kullanır; günlük açılışta reset/drop/seed/migration gerekmez. Rails lazy connection kontrolü için önce `SELECT 1`, sonra `active?` kullanın. `.env` otomatik yüklenmez.

Kota uygunken tam gerçek kabul (fictional test transaction rollback; CI/production reddedilir):

```powershell
$env:GROQ_API_KEY = [Environment]::GetEnvironmentVariable('GROQ_API_KEY','User')
$env:LEADCURRENT_LIVE_AGENT = '1'
$env:LEADCURRENT_LIVE_SCENARIOS = $null
bundle exec ruby script/verify_copilot_finalization.rb
```

`LEADCURRENT_LIVE_SCENARIOS` yalnız diagnostic subset seçebilir; subset PASS tam kabul değildir. Normal otomasyonda bu opt-in değişkenleri ve gerçek key gerekmez.

Hocaya 3–4 dakikalık demo:

1. **AI Agent** açın. “Tell me how I can use the system.” sorun; AI explanation etiketi ve browser navigasyonu yapılmadığını gösterin.
2. “How many users are in my team?” ve “How many of them are salespeople?” sorun. Settings'teki gerçek ekip sayısı/rollerle karşılaştırın; mevcut kullanıcı dahildir, online kişi sayısı değildir.
3. “How many leads do we have?”, “Which leads are overdue?” ve “Which one needs attention first?” sorun. Gerçek linkler, deadline, Verified CRM data ve resmî NBA önceliğini gösterin.
4. “Show my opportunities in negotiation.” ile gerçek filtreli sayfayı açtırın. Agent activity'yi isteğe bağlı açın; browser'ın DOM kontrolünü kullandığını gösterin.
5. “What follow-ups are due today?” ile planlı görevin tamamlanmış temas olmadığını açıklayın.
6. “Open Atlas Industries.”, ardından “Prepare a follow-up note for this customer.” sorun. Notun kaydedilmediğini gösterin. Kaydetme ayrı insan onayıdır; demoda gerekmedikçe Save action'a basmayın.
7. “Mark this deal won.” isteğinin otomatik yapılmadığını, güvenli manuel yolu açıkladığını gösterin. Mobil/light/dark görünümü ve Escape/Ctrl+Enter kontrollerini gösterin.

## Kalan sınırlar

LLM niyet/arama referansını yanlış çözebilir; tüm doğal diller/parafrazlar için garanti yoktur. Factual sonuçlar seçilen doğrulanmış sorguya aittir; UI bu ayrımı görünür tutar. Yetkili listeler en çok 10, NBA en çok 8 kayıt; dar owner/search NBA sorguları her kayıt türünden en çok 8 adayda resmî hizmeti çağırır, büyük veri için kapsamlı global ranking garantisi verilmez. Varsayılan liste sayfaları 100 sınırındadır. Eşzamanlı kullanıcı yazmaları sırasında çoklu okuma sorguları arasında veri değişebilir.

Online/active team durumu bilinmez. Generic müşteri adı birden fazla kayıt döndürebilir; lead/opportunity toplamı benzersiz kişi sayısı değildir. Özetlerin hepsi UI filtrelerine çevrilmez. Unsaved DOM, server-side persistence kanıtı değildir. Provider 429/erişim/latency kısıtları, process-local cache/rate limit, TTL sonunda bağlam kaybı ve token/masraf belirsizliği sürer. İnsan saatleri, geliştirme agent tokenları ve ödenmiş API bedeli ölçülmemiştir. Önceki 127.276s→64.443s ölçümü tarihsel Phase 2.1 ölçümüdür; yeni run için aynı performans iddiası yapılmaz.
