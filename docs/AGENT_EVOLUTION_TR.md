# AGENT.md: ilk ve son sürümün gerçek Git karşılaştırması

16 Ekim 2026. Durum: **PASS**, PDF s.26'nın ilk/son diff teslimi. [AGENT_FIRST_LAST.diff](AGENT_FIRST_LAST.diff) Git'in ürettiği unified diff'tir; eski dosya yeniden yazılmadı.

| Uç | Gerçek commit | Kapsam |
|---|---|---|
| İlk commit edilmiş AGENT.md | [c478f8730a29a7263ab9d8c71b230df970fd6b36](https://github.com/Montaserissa20/leadcurrent/commit/c478f8730a29a7263ab9d8c71b230df970fd6b36), 14 Ekim 2026 17:13:18 +03:00 | `git log --reverse -- AGENT.md` ile bulunan ilk sürüm; projenin ilk kod commit'iyle aynı olduğu iddia edilmez |
| Son AGENT.md sürümü | [83b0a85e738dbfd82b9d30b52d9efc92f5692cda](https://github.com/Montaserissa20/leadcurrent/commit/83b0a85e738dbfd82b9d30b52d9efc92f5692cda) | Sınır/browser testleri ve gerçek konvansiyon denetimi sonrası sürüm; sonraki rapor commit'lerinde AGENT.md değiştirilmez |

Tekrar üretme:

```bash
git log --reverse --format='%H %aI %s' -- AGENT.md
git diff --no-ext-diff --no-color --full-index c478f8730a29a7263ab9d8c71b230df970fd6b36 83b0a85e738dbfd82b9d30b52d9efc92f5692cda -- AGENT.md
git diff --exit-code 83b0a85e738dbfd82b9d30b52d9efc92f5692cda HEAD -- AGENT.md
```

İkinci komutun stdout byte'ları doğrudan diff dosyasına yazıldı. Son komutun sıfır çıkışı, teslim HEAD'indeki dosyanın raporda seçilmiş son sürümle aynı kaldığını doğrular. Dosya, Git blob index satırları ve gerçek hunk konumlarını içerir; elle eklenmiş değişiklik yoktur. Unified diff'in tek boşluk içeren boş bağlam satırları patch biçiminin parçasıdır; whitespace temizliğiyle değiştirilmedi. Diğer değişikliklerde whitespace kontrolü, diff dosyasında ise Git çıktısıyla bire bir byte karşılaştırması uygulandı.

## İlk mimari ve talimatlar

İlk sürüm bile Ruby 3.4.7/Rails 8.1.4/PostgreSQL, ERB/Turbo/Stimulus, Minitest/Selenium, tenant/sahip yetkisi, süreli DB session, explicit domain services ve CI düzenini anlatıyordu. Domain Organization/User/Company/Contact/Lead/Opportunity/Activity/Task/AuditEvent'ti. Eski proje salt okunur kaynak olarak sınırlandırılmıştı; veri ve anahtar kopyalanması yasaktı. 24 saat ilk temas, durum geçişleri, atomik conversion ve 72 saat hareketsizlik zaten vardı. Deployment tarifi Render içindi. Bunların sonradan icat edilmiş eski bir taslak olduğu söylenemez.

## Ne değişti, neden?

| Dönem / commit | Gerçek değişiklik | Neden ve talimatın gelişimi |
|---|---|---|
| [ab6d575 Pro upgrade](https://github.com/Montaserissa20/leadcurrent/commit/ab6d57516c9edc60d4572a77a07fe201d3765759) | ManageTask, CustomerProfile, SalesMetrics; duplicate followup reuse; NBA'de overdue/today task öncelikleri; Customer 360, analytics ve pro.css | Agent artık yeni davranışın hangi serviste olduğunu bilir; ilk temas/görev ayrımı, lock sırası, tenant yetkisi, para birimlerini karıştırmama ve query sınırı belirginleşti |
| [372113e üretim kanıtı](https://github.com/Montaserissa20/leadcurrent/commit/372113eef6fbdb2680ac240660c30fa1c7f8edab) | Gerçek Railway/Docker URL, üretim raporu, script/style için dolu per-session CSP nonce ve regression konumları | Render alternatifi korunurken gerçek kullanılan ortam görünür oldu. Build ile çalışan üretim birbirine eşit sayılmadı; [217c3bf CSP düzeltmesinden](https://github.com/Montaserissa20/leadcurrent/commit/217c3bfe2115f14530c86ec290ef493589d55237) öğrenilen fresh-session kontrolü kalıcı talimata dönüştü |
| [83b0a85 PDF denetimi](https://github.com/Montaserissa20/leadcurrent/commit/83b0a85e738dbfd82b9d30b52d9efc92f5692cda) | Üç zaman kuralının bağımsız sınır testleri, gerçek browser etkileşim ölçümü, konvansiyon/concern açıklaması ve TR↔EN domain sözlüğü | PDF s.15/17/25/26 gereği sihir/yan etki sınırı görünür oldu; türetilmiş deadline callback'i gerekçesiyle korundu. Mevcut servis/guard tercihleri ve ölçümün Salesforce'a genellenemeyeceği belgelendi |

## Rails konvansiyonları ve sapmalar

Global monkey patch, `method_missing`, `default_scope` veya Rails core override bulunmadı. İsimlendirme/route/model yapısı standart Rails'tir. İş akışlarını explicit `app/services` içinde tutmak proje tercihidir; modelde saklı workflow callback'i değildir. `workflow_change` sunucu içi guard'ı standart Rails API'si değildir, AGENT'te yetkilendirme yerine kullanılamayacağı ve temizlenmesi gerektiği yazılıdır.

`Lead.before_validation :set_deadline, on: :create` türetilmiş başlangıç alanını `FollowUpDeadline` üzerinden saklar; PDF s.25 callback'i türetilmiş alan için kabul eder. `TenantRecord` aynı-workspace association validation'ını açık isimli concern'de toplar ve AGENT'te listelenir; veri yazma yan etkisi yoktur. Login/timezone controller filtreleri standart request davranışıdır. Ayrıntılı [konvansiyon denetimi](G1_G5_AUDIT_TR.md#kısa-rubyrails-konvansiyon-denetimi) bu tercihleri ve gerçek dosyaları gösterir.

AGENT yalnız diff üretmek için değiştirilmedi: son bölüm gerçek kaynak denetiminin bulgularını, mevcut concern/guard tasarımını, yeni test konumlarını ve PDF'nin istediği sözlüğü kaydeder. Uygulamanın iş mantığı, DB yapılandırması veya süreleri bu güncellemede değiştirilmedi.
