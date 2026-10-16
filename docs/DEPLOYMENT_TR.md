# Railway üretimi ve alternatif Render dağıtımı

**Güncel üretim:** https://leadcurrent-production.up.railway.app — 16 Ekim 2026: `/up` 200/connected ve izole QA ile tam canlı satış akışı doğrulandı. Bulunan CSP fix'i push sonrası yeniden gözlendi; [gerçek test raporu](PRODUCTION_TEST_REPORT.md), [gereksinim durumu](ASSIGNMENT_CHECKLIST.md) ve [sunum](FINAL_PRESENTATION_TR.md) güncel kanıttır. Railway paneline erişilmediği için release ID/uzak SHA, plan/fatura ve operasyonel backup iddiası yoktur.

Railway bu depodaki [Dockerfile](../Dockerfile) ile çalışır. Son aşamada rails kullanıcısından sonra `mkdir -p db log tmp` ve `chown` vardır. Mevcut `bin/docker-entrypoint` database hazırlığını yapar; üretim verisini reset/seed ederek test etmeyin. Yeni app release'i için commit push edilir, public health ve ilgili gerçek akış tekrar kontrol edilir; build/CI başarısı tek başına production kanıtı değildir.

## Render alternatifi

Aşağıdaki korunmuş Render tarifi alternatif dağıtım içindir; Railway servisinin planı, DB süresi veya faturası değildir. Render hesabı/dağıtımı bu çalışmada doğrulanmadı.

1. GitHub repository: https://github.com/Montaserissa20/leadcurrent. Son LeadCurrent CI workflow'sunun ilgili commit için yeşil olduğunu kontrol edin.
2. https://dashboard.render.com/select-repo?type=blueprint üzerinden repository'yi seçin. render.yaml, Frankfurt web + ayrı PostgreSQL hizmeti tanımlar.
3. DEMO_PASSWORD için en az 12 karakterlik güçlü, production'a özgü parola girin. SECRET_KEY_BASE otomatik; DATABASE_URL Postgres bağlantısı. Eski Fixture .env/keys/veri kullanılmaz.
4. Build bash bin/render-build.sh; start bundle exec puma -C config/puma.rb. Free plan migration'ı build'de çalıştırır. DB şeması ayrı LeadCurrent migration'larından oluşur; seed kurgusal ve idempotenttir.
5. Render'ın gerçek servis URL'sini alın. Tahmini leadcurrent.onrender.com adresini doğrulanmadan README'ye yazmayın.
6. /up: 200 ve database=connected. /login: 200. Login'den sonra tam akışı gerçekleştirin: create → completed contact + takip → qualify → convert → proposal → negotiation → won; her adım DB'de kalıcı.
7. Refresh ve ikinci oturumda kayıt/gelir kalıcılığını kontrol edin. New lead first_contact_deadline ile created_at farkı 86400 saniye; planlanan görev first_contact_at doldurmamalı. Demo overdue lead için NBA temas formunu çalıştırın.
8. Ayrı /signup workspace oluşturup birinci workspace URL/ID'sine erişimde 404, yetkisiz action'da reddetme doğrulayın. Diğer kullanıcının verisi listede görünmemeli.
9. Gerçek URL, kontrol tarihi, ilgili commit ve başarılı/başarısız adımları docs/VERIFICATION_TR.md ve README'ye yazın. Sadece build başarılıysa public workflow başarılı demeyin.

Render Free Postgres 30 gün sonra sona erer; uzun süreli teslim için paid plan gerekir. Free web 15 dakika inaktiflikte uyuyabilir. Kaynak: https://render.com/docs/free. Buradaki Render kısıtları Railway'e uygulanmaz; gerçek Railway ödeme/tüketim verisi erişilebilir değildir. Bu çalışmada yeni paid plan satın alınmadı.
