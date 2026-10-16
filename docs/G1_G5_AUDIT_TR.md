# G1–G5, PDF ve Rails konvansiyon denetimi

16 Ekim 2026. Genel G1–G5 teslim durumu: **BLOCKED — tam görev tanımları gerekli**. Doğrulanabilen alt kanıtlar aşağıda PASS/PARTIAL olarak ayrılır; beş ölçüt G1–G5'e bire bir eşlenmedi.

## Özgün PDF ve arama kapsamı

`2026-10-12.pdf` yerel Downloads/Documents içinde bulundu: **37 sayfa**, SHA-256 `90ad8ec712b7941df53504ad9c7b34be2d72bfc9fbc6c00545c186e28b1e90c8`. İstenen 15, 17, 25, 26, 31, 34, 35, 36, 37. sayfalar metin ve render görüntüsüyle okundu; G1–G5 için tüm 37 sayfanın metni tarandı. PDF ve yerel render'ları public repoya kopyalanmadı; bu kimlik öğretim görevlisinin özgün dosyasıyla karşılaştırılabilir. PDF için kamuya açık URL sağlanmadı; URL uydurulmadı.

Repo (`README`, `docs/`, `AGENT.md`, uygulama/test kaynakları) ve kullanıcı tarafından sağlanan beş eski/son ek yönerge tarandı. İlk yönergedeki “G2”, müşteri yorum sitesi G2'dir; teslim görevi G2 tanımı değildir. PDF s.35, 85 için G1–G5 + Yapamadıklarım ister; s.37 `docs/ (G1–G5)` teslimini ister. Tam görev listesi bu materyallerde bulunamadı.

| Teslim | Gerçekte bulunabilen tanım/atıf | İlgili mevcut kanıt | Durum |
|---|---|---|---|
| G1 | s.12 token farkını ölçmeye G1 atfı; s.36 zaman kuralı ve durum geçişi kodunun G1 tablosundan gösterilmesi. Tam görev ve tablo şeması yok | [Üç kural/dosya/satır tablosu](THREE_TIME_RULES_TR.md), [durum kodu tablosu](FINAL_PRESENTATION_TR.md#230330--üç-zaman-kuralı-ve-geçiş-testleri); gerçek token sayısı yok | PARTIAL; tam tanım eksik |
| G2 | Görev tanımı bulunamadı | Uygulama varlığı G2'nin içeriğini tanımlamaz | BLOCKED |
| G3 | Görev tanımı bulunamadı | Bu raporda yapay görev eşlemesi yapılmadı | BLOCKED |
| G4 | Görev tanımı bulunamadı | Bu raporda yapay görev eşlemesi yapılmadı | BLOCKED |
| G5 | s.31 “Yakalanan uydurma (G5)” bağlantısı var; kapsam/örnek/teslim biçimi yok | Kaynaklı araştırma, [kanıt sınırları](ADAPTATION_EVIDENCE_TR.md), gerçek hata/fix geçmişi var; sistematik uydurma sayımı yok | PARTIAL; tam tanım eksik |

Özgün **G1–G5 görev yönergesi veya öğretim görevlisinin açıklaması gerekiyor**. Bu eksik, tamamlanan kod/test/dokümantasyon işlerini engellemez; G1–G5 tamamlandı veya 85/100+ kazanıldı denemez. S.34'te Salesforce için 30 günlük dokunulmama örneği verilmiştir; mevcut 72 saat kuralını değiştiren zorunlu süre olarak yorumlanmadı. S.35 üç testli kural ister; süreleri zorunlu olarak 30 güne sabitlemez.

## Sayfa 31 ölçümleri: gerçek kayıt ve bilinmeyenler

| Ölçüt | Gerçek veri / sınır | Durum |
|---|---|---|
| Coding-agent çıktı token sayısı | Agent arayüzü kullanım dökümü yok. Maliyet raporundaki varsayımsal token bütçesi gerçek tüketim değildir | BLOCKED — doğrulanabilir veri mevcut değil |
| Düzeltme turu sayısı | Tam konuşma/iterasyon sayacı yok. Git commit sayısı düzeltme turu sayısı değildir. Aşağıdaki iki somut fix toplam iterasyon hesabı değildir | BLOCKED — toplam bilinmiyor |
| CI'da yeşil test sayısı | [83b0a85 exact-commit CI](https://github.com/Montaserissa20/leadcurrent/actions/runs/38946656482), success: gerçek job log'unda 56 domain/HTTP + 7 Chrome browser = **63 test / 632 assertion**, sıfır failure/error/skip. Önceki [1d1fa6d CI](https://github.com/Montaserissa20/leadcurrent/actions/runs/38916369041): 60 test / 601 assertion | PASS — gerçek CI log'u |
| Yakalanan uydurma (G5) | Sistematik etiketlenmiş kayıt yok; “0” yazılamaz. CSP/Docker hatası otomatik olarak uydurma sayılmaz. Bu denetimde Salesforce'ta NBA yokluğu iddiası reddedildi; bu da geçmişte kaç uydurma olduğunu ölçmez | BLOCKED — sayı mevcut değil |
| Kodu okuyup onaylama süresi, dakika | Review timesheet yok. Git zaman aralığı veya ajan komut süresi insanın review süresi değildir | BLOCKED — doğrulanabilir veri mevcut değil |
| Sınıf arkadaşının diğer yığın ölçümleri | PDF'nin karşılaştırma sütunu var; aynı görev/ajan için ölçüm sağlanmadı | BLOCKED |

Belgeli düzeltme örnekleri: [19e5203 Docker mkdir](https://github.com/Montaserissa20/leadcurrent/commit/19e5203aec5fb8f44bfa6683a9706b493ff58c4c), [217c3bf fresh-session CSP](https://github.com/Montaserissa20/leadcurrent/commit/217c3bfe2115f14530c86ec290ef493589d55237). Bunlar doğrulanabilir değişikliklerdir; toplam düzeltme, hata veya uydurma sayısı değildir. Gerçek ödeme/kullanım için [COSTS_TR.md](COSTS_TR.md): “Kesin kullanım veya ödeme verisi mevcut değil.”

## Kısa Ruby/Rails konvansiyon denetimi

PDF s.15/17/25/26 esas alındı. `app/`, `lib/`, `config/` içindeki Ruby kaynakları `rg` ile tarandı; model/concern, initializer, controller filtreleri ve iş akışı servisleri ayrıca okundu. Kapsam uygulama kaynaklarıdır; Rails/gem iç koduna genel bir sihirsizlik garantisi verilmez.

| Kontrol | Bulgular / dosya | Durum |
|---|---|---|
| Global monkey patch / core sınıf yeniden açma | Uygulama kaynağında bulunmadı; `class_eval`, `instance_eval`, `define_method`, `refine`, prepend ile gizli override da bulunmadı | PASS |
| Gereksiz `method_missing` | Uygulamada yok | PASS |
| `default_scope` | Uygulamada yok; `active`, `pending`, `overdue` adlandırılmış scope | PASS |
| Gizli domain yan etkili callback | [Lead:11](../app/models/lead.rb#L11) tek model initialization callback'i; [set_deadline:20](../app/models/lead.rb#L20) türetilmiş alanı açık servisten hesaplar. S.25'in türetilmiş alan istisnasına uygundur; kaldırılmadı. Contact/conversion/stage/task yazmaları açık servislerde | PASS |
| Concern görünürlüğü | [TenantRecord:3](../app/models/concerns/tenant_record.rb#L3): organization ilişkisi ve aynı-tenant association validation; kayıt yazmaz. Kullanılan tek model concern, [AGENT](../AGENT.md#convention-audit-and-explicit-design-choices) içinde listelendi | PASS |
| Standart controller filtreleri | [ApplicationController:3](../app/controllers/application_controller.rb#L3): login before_action ve timezone around_action; domain işlemi gizlemez | PASS |
| Belgelenmiş proje tercihleri | `app/services` orkestrasyonu, server-only `workflow_change` guard, lock içinde tekrar auth, bounded NBA sorguları, timezone; global Rails override yok | PASS |

## Diğer PDF kanıtları

Üç bağımsız zaman kuralı: **PASS**, [rapor](THREE_TIME_RULES_TR.md). İlk/son AGENT diff: [gerçek Git diff](AGENT_FIRST_LAST.diff), [mimari evrim](AGENT_EVOLUTION_TR.md). 100+ özgün adaptasyon şartı: **PARTIAL**, [mevcut rakip işlevi ve gerçek browser ölçümü](ADAPTATION_EVIDENCE_TR.md). Beş dakikalık plan: [FINAL_PRESENTATION_TR.md](FINAL_PRESENTATION_TR.md), s.36 süre dağılımı korunur. Mevcut Fortune/tam LOC/gerçek fatura PARTIAL maddeleri [kontrol listesinde](ASSIGNMENT_CHECKLIST.md) durur.

## Son doğrulama

16 Ekim 2026, yerel Windows/Ruby 3.4.7/Rails 8.1.4/PostgreSQL 17:

| Komut | Gerçek sonuç |
|---|---|
| `bundle exec rails test` | seed 48369; 56 runs, 566 assertions, 0 failures/errors/skips |
| `bundle exec rails test:system` | seed 57899; gerçek headless Edge; 7 runs, 66 assertions, 0 failures/errors/skips |
| Toplam | **63 test, 632 assertion**, sıfır failure/error/skip |
| `bundle exec rails zeitwerk:check` | All is good |
| `bundle exec brakeman --no-pager --quiet` | Brakeman 8.1.0: Errors 0, Security Warnings 0; exit 0. Windows fork/Ractor/Forwardable fallback diagnostics stderr'de görülür; son rapor sonucu sıfırdır |
| Production asset derlemesi | `RAILS_ENV=production SECRET_KEY_BASE_DUMMY=1 bundle exec rails assets:precompile`; exit 0. Child process env ile gerçek production DB'ye dokunulmadı; yalnız ignored yerel manifest temizlenerek development asset lookup geri yüklendi |
| Güncel salt-okunur public sağlık kontrolü | 16 Ekim 2026 21:21:19 +03:00: Railway `/up` 200 / database connected; `/login` 200; dolu script/style nonce. Yeni release SHA'sı veya deployment paneli doğrulanmadı |

**Doğrulanmış GitHub CI:** [run 38946656482](https://github.com/Montaserissa20/leadcurrent/actions/runs/38946656482), `83b0a85e738dbfd82b9d30b52d9efc92f5692cda`, workflow **LeadCurrent CI**, conclusion **success**. Job `117127379770` gerçek log'unda 16 Ekim 18:21:48 UTC domain/HTTP: 56/566; 18:22:07 UTC Chrome browser: 7/66; sıfır failure/error/skip. PostgreSQL hazırlığı, Zeitwerk, güvenlik ve production assets adımları da success. Bu CI kaydını içeren son dokümantasyon commit'i push sonrası ayrıca exact-HEAD sorgulanır ve sonucu teslim mesajında bildirilir; yukarıdaki run son belge commit'inin run'ı olarak sunulmaz.

Önceki [Railway üretim raporu](PRODUCTION_TEST_REPORT.md) tarihli kanıt olarak korunur; bu güncellemede üretim saati/DB/env değiştirilmedi, manuel redeploy yapılmadı. Yerel test başarısı yeni Railway release başarısı olarak sunulmaz. Bu çalışmada uygulama/DB/dependency kodu değiştirilmedi; iki yeni test dosyası ve kaynaklı belgeler eklendi.
