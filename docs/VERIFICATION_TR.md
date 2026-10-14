# Doğrulama raporu — 14 Ekim 2026

Yeni uygulama `D:\LeadCurrent`; Fixture `D:\ruby_project` salt okunur incelendi. Eski uygulama, migration veya test çalıştırılmadı; veritabanına bağlanılmadı. Uygulama kodu bağımsız yazıldı. Eski projenin lisans dosyası bulunmadığından kod kopyalanmadı.

## Gerçek yerel kontroller

Ruby 3.4.7, Rails **8.1.4**, PostgreSQL 17.5, bağımsız loopback cluster / 55432; `leadcurrent_development` ve `leadcurrent_test`.

| Çalıştırılan kontrol | Sonuç |
|---|---|
| `bundle exec rails db:migrate` | Yeni PostgreSQL şeması başarılı |
| `bundle exec rails db:seed` | Kurgusal Current Studio workspace; tekrar çalıştırmada mevcut veriyi değiştirmiyor |
| `bundle exec rails test` | **37 runs, 401 assertions, 0 failures, 0 errors, 0 skips** |
| `bundle exec rails test:system` | **2 runs, 24 assertions, 0 failures, 0 errors, 0 skips** — gerçek headless Edge; gerçek 390px viewport assertion |
| `bundle exec rails zeitwerk:check` | All is good |
| `bundle exec brakeman --no-pager --quiet` | **0 errors, 0 security warnings** |
| Production env / `SECRET_KEY_BASE_DUMMY=1` / assets:precompile | Başarılı; Rails 8.1.4 |
| `GET http://127.0.0.1:3100/up` | 200; status=ok, database=connected |
| `GET http://127.0.0.1:3100/login` | 200 |

Deadline testleri gerçek `travel_to` kullanır: oluşturma, 24 saatten önce/tam an/sonra, completed contact, not/görev ayrımı, İstanbul/UTC gece yarısı ve DST. Durum testleri bütün lead ve opportunity durum çiftlerini denetler; invalid request, terminal state, tenant/owner izni, duplicate conversion ve transaction rollback içerir. Eşzamanlı dönüşüm testi iki gerçek PostgreSQL bağlantısı ile tek Opportunity ve tek WorkflowError doğrular.

Browser testleri girişten yeni lead, completed contact + task, qualification, conversion, proposal/negotiation/won, dashboard ve refresh kalıcılığına kadar ilerler. Diğer browser testi dashboard'daki tek submit eylemini, DB kayıtlarını, theme/localStorage ve mobile navigation/overflow'u doğrular.

## GitHub Actions

Gerçek repository: https://github.com/Montaserissa20/leadcurrent.

Doğrulanan uygulama CI commit'i: **2df2d1370b84ebbdf44b298b651d7f67ba17b888**. Named workflow: **LeadCurrent CI**. Sonuç: **success**.

Gerçek run: https://github.com/Montaserissa20/leadcurrent/actions/runs/38576922384.

Kontrol edilen adımların tamamı başarılı: PostgreSQL hazırlama; domain/HTTP tests; headless Chrome system tests; Zeitwerk; Brakeman; production assets. Dependabot sonuçları uygulama CI kanıtı sayılmadı. İlk browser run'ında testler arasında kalan dar viewport sorunu görüldü; viewport reset düzeltmesi sonraki run'da doğrulandı.

Son uygulama/screenshot commit'i **1872bad593b6204ac5ae24667f4b428e765957d1** ayrıca doğrulandı: **LeadCurrent CI / success**. [Son başarılı uygulama run'ı](https://github.com/Montaserissa20/leadcurrent/actions/runs/38578911109). 390px assertion dahil **37 + 2 = 39 test, 401 + 24 = 425 assertion**. Bu kayıt eklenirken uygulama kodu değiştirilmedi.

## Deployment

Render hesabı bağlantısı doğrulanmadı; gerçek public URL ve production smoke testi yok. `render.yaml`, `bin/render-build.sh`, DB binding, secret handling, fictional/idempotent production seeds ve DB health endpoint hazır. Genel dağıtımın tamamlandığı iddia edilmez. Eksik adım: Render bağlantısı ile Blueprint oluşturma, production demo parolası ve public akış doğrulaması.

## Araştırma ve gider

README'de verifiable links: Fortune ranking ve şirket profilleri, üç resmî ürün kullanım hikâyesi (yalnızca Ford/Amex kabul kanıtı), Zylo 2026, Open Hub güncel dil sayımı, 15 Mart 2026 khyan A. Capterra yorumu. Açık olmayan fiyat/nüfus aralığı/token gideri uydurulmadı. Yeni ücretli satın alma başlatılmadı; gerçek mevcut abonelik/token faturası bilinmiyor.
