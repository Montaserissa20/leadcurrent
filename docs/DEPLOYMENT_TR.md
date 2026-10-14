# Render dağıtımı ve doğrulama

Mevcut durum: hesap bağlantısı doğrulanmadı; genel URL yok. Bağlantı elde edilince yalnızca dağıtım/üretim doğrulamasını tamamlamak gerekir. Yerel testler ve production asset build geçti.

1. GitHub repository: https://github.com/Montaserissa20/leadcurrent. Son LeadCurrent CI workflow'sunun ilgili commit için yeşil olduğunu kontrol edin.
2. https://dashboard.render.com/select-repo?type=blueprint üzerinden repository'yi seçin. render.yaml, Frankfurt web + ayrı PostgreSQL hizmeti tanımlar.
3. DEMO_PASSWORD için en az 12 karakterlik güçlü, production'a özgü parola girin. SECRET_KEY_BASE otomatik; DATABASE_URL Postgres bağlantısı. Eski Fixture .env/keys/veri kullanılmaz.
4. Build bash bin/render-build.sh; start bundle exec puma -C config/puma.rb. Free plan migration'ı build'de çalıştırır. DB şeması ayrı LeadCurrent migration'larından oluşur; seed kurgusal ve idempotenttir.
5. Render'ın gerçek servis URL'sini alın. Tahmini leadcurrent.onrender.com adresini doğrulanmadan README'ye yazmayın.
6. /up: 200 ve database=connected. /login: 200. Login'den sonra tam akışı gerçekleştirin: create → completed contact + takip → qualify → convert → proposal → negotiation → won; her adım DB'de kalıcı.
7. Refresh ve ikinci oturumda kayıt/gelir kalıcılığını kontrol edin. New lead first_contact_deadline ile created_at farkı 86400 saniye; planlanan görev first_contact_at doldurmamalı. Demo overdue lead için NBA temas formunu çalıştırın.
8. Ayrı /signup workspace oluşturup birinci workspace URL/ID'sine erişimde 404, yetkisiz action'da reddetme doğrulayın. Diğer kullanıcının verisi listede görünmemeli.
9. Gerçek URL, kontrol tarihi, ilgili commit ve başarılı/başarısız adımları docs/VERIFICATION_TR.md ve README'ye yazın. Sadece build başarılıysa public workflow başarılı demeyin.

Free Postgres 30 gün sonra sona erer; uzun süreli teslim için paid plan gerekir. Free web 15 dakika inaktiflikte uyuyabilir. Kaynak: https://render.com/docs/free. Hiçbir paid plan bu çalışma sırasında satın alınmadı. Her iki kaynak dosyası hazırdır; eksik olan hesap erişimidir.
