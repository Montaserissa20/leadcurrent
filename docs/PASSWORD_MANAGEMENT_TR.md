# Güvenli parola yönetimi

17 Ekim 2026. Kapsam yalnız parola yönetimidir. Mevcut manager/salesperson login, CRM yetkileri ve **24 saat ilk temas dahil üç zaman kuralı değiştirilmedi**. Canlı adres: https://leadcurrent-production.up.railway.app.

## Kullanıcı akışı

Her iki rol **Settings → Your profile → Security & Password** bölümünden mevcut parola, yeni parola ve tekrarını girer. Yeni parola en az 12 karakter, bcrypt sınırı gereği en çok 72 byte olmalıdır; mevcut parola ile aynı olamaz. Her alanın erişilebilir Show/Hide düğmesi vardır. Yanlış mevcut parola, kısa/uzun parola, boş tekrar ve uyuşmazlık 422 hata ekranı verir; alanlar boş döner. Başarılı işlem 303 ile Settings'e döner ve başarı bildirimi gösterir. Parola formunda korunacak başka bir kullanıcı girdisi yoktur; kayıtlı isim/saat dilimi değişmez.

Manager **Workspace team → Add salesperson** ile geçici parola belirler ve güvenli kanaldan paylaşır. Yalnız bu yeni hesap `password_change_required=true` olur. İlk login `/settings/password` ekranına gider; CRM navigasyonu yerine parola formu/tema/logout görünür. Eski ve yeni parolayı girerek başarılı değişiklik yapmadan CRM GET/POST/PATCH istekleri sunucuda 303 ile bu ekrana döner. Settings, team veya signup isteğiyle atlanamaz. Parola ekranı ve logout serbest olduğundan redirect loop oluşmaz.

Mevcut manager ve salesperson hesapları için migration değeri **false**; signup ile açılan yeni workspace manager'ı da false'tur. Eski hesaplar beklenmedik parola değişikliğine zorlanmaz. Parolayı unutma/e-posta kurtarma, manager'ın başkasının parolasını sıfırlaması ve MFA bu değişikliğin kapsamı değildir.

## HTTP ve güvenlik sınırları

| Kontrol | Uygulama |
|---|---|
| Giriş zorunluluğu | ApplicationController; anonim kullanıcı login'e gider; her iki rol kendi parolasını değiştirebilir |
| Hedef kullanıcı | `GET/PATCH /settings/password`; route'ta kullanıcı ID'si yok, actor daima `current_user`; nested bilinmeyen alanlar/top-level user/user_id/id reddedilir. Manager için ayrı hedef yetkisi yok |
| Geçerli mevcut parola | ChangePassword, user row lock aldıktan sonra DB'deki güncel digest ile `authenticate` kullanır; doğrulanmadan hiçbir parola/session/audit değişmez |
| Yeni parola | Mevcut `User.has_secure_password`, min 12 ve Rails bcrypt max 72 byte; confirmation zorunlu/eşleşmeli; aynı parola reddedilir |
| CSRF | Mevcut Rails `protect_from_forgery with: :exception`; token olmayan direct HTTP isteği reddedilir, geçerli token'lı istek testlidir |
| Rate limit | Hesap başına 10 dakikada 5 PATCH denemesi; sonra 429 ve açık mesaj. Hatalı denemeler dahil, hesaplar birbirinin kotasını tüketmez |
| Gizli veri | Mevcut `:passw` filtresi current/new/confirmation ve `password_change` kökünü maskeler; plaintext DB/audit/flash'a yazılmaz; HTML value attribute'larında parola yok |
| Tarayıcı | Parola/Settings yanıtı no-store, Turbo snapshot kapalı; parola formu native POST/PATCH redirect kullanır. Stimulus snapshot öncesi alanı boşaltıp maskeler. Yeni parola autocomplete=new-password; mevcut parola current-password |
| Denetim | `password_changed` AuditEvent yalnız diğer iptal edilen oturum sayısını tutar; parola/digest/cookie/token içermez |

Rate limit deposu bilinçli olarak süreç içi `ActiveSupport::Cache::MemoryStore`'dur: test ortamının NullStore'undan etkilenmez, yeniden başlatmada sıfırlanır. Birden fazla instance/worker için paylaşılan cache gerekir; bu teslim yeni Redis/hizmet veya Railway ayarı eklemez. Geçici parola güvenli kanalda paylaşılmalıdır; sistem e-posta göndermez.

## Atomik parola ve oturum değişimi

1. User row lock alınır; mevcut DB session hâlâ geçerli ve bu kullanıcıya ait olmalıdır. Süresi dolmuş/iptal edilmiş oturum yeni session yaratamaz.
2. Mevcut parola doğrulanır. Yeni parola/tekrar validasyonu geçerse digest güncellenir ve geçici flag false yapılır.
3. Yalnız bu kullanıcıya ait tüm DB Session'lar iptal edilir; geçerli tarayıcı için yeni kimlikli bir Session oluşturulur. Eski session'ın expiry değeri korunur; 12 saatlik süre uzatılmaz.
4. Aynı transaction içinde secret-free AuditEvent yazılır. Controller `reset_session` ile Rails cookie/CSRF session'ını döndürür, yeni DB kimliğini bağlar. Kullanıcı aynı tarayıcıda giriş yapmış kalır; diğer tarayıcılar ve eski cookie replay'i sonraki istekte login'e gider.

Login de parola doğrulaması + session yaratmayı aynı user lock altında yapar. Böylece değişimden önce doğrulanan eski parola, değişimden sonra yeni session oluşturamaz. Önceden başlamış bir HTTP isteğinin çalışması durdurulmaz; iptal edilmiş oturum yeni isteklerde kullanılamaz. Yeni parola geçerli olur olmaz eski parola login'de reddedilir.

## Migration ve dosyalar

Yeni [20261017000100 migration](../db/migrate/20261017000100_add_password_change_required_to_users.rb) yalnız `users.password_change_required` boolean/default false/not null ekler. Önceki migration'lar değiştirilmedi; [schema.rb](../db/schema.rb) Rails tarafından üretildi. Yerel development ve test DB'lerine yalnız migration uygulandı; reset, kullanıcı silme veya production SQL bağlantısı yapılmadı. Docker'ın mevcut `db:prepare` entrypoint'i normal otomatik deployment'ta additive migration'ı uygular; manuel redeploy/env/credential değişikliği gerekmez.

| Dosyalar | Amaç |
|---|---|
| [PasswordsController](../app/controllers/passwords_controller.rb), [ChangePassword](../app/services/change_password.rb) | Self-only endpoint, clear errors, rate limit, atomik parola/session/audit |
| [ApplicationController](../app/controllers/application_controller.rb), [SessionsController](../app/controllers/sessions_controller.rb), [SettingsController](../app/controllers/settings_controller.rb) | Sunucu guard'ı, kilitli login, yalnız yeni team member için geçici flag |
| [routes.rb](../config/routes.rb) | İki self-password route'u |
| [settings/show](../app/views/settings/show.html.erb), [passwords/form](../app/views/passwords/_form.html.erb), [passwords/edit](../app/views/passwords/edit.html.erb) | Profile security bölümü ve restricted ilk giriş ekranı |
| [Layout](../app/views/layouts/application.html.erb), [visibility controller](../app/javascript/controllers/password_visibility_controller.js), [pro.css](../app/assets/stylesheets/pro.css) | Snapshot koruması, kısıtlı frame, Show/Hide, responsive light/dark |
| [Migration](../db/migrate/20261017000100_add_password_change_required_to_users.rb), [schema](../db/schema.rb) | Mevcut hesaplarla uyumlu yeni flag |
| [HTTP testleri](../test/integration/password_management_test.rb), [service testleri](../test/models/change_password_test.rb), [browser testleri](../test/system/password_management_test.rb) | Rol, validation, auth, cookie/session, CSRF, rate limit, ilk login, görünüm ve tam gerçek-browser akışı |
| [README](../README.md), [AGENT](../AGENT.md), bu rapor | Kullanım, güvenlik sınırları ve doğrulama |

`app/models/user.rb` ve `filter_parameter_logging.rb` değiştirilmedi: mevcut bcrypt doğrulaması ve secret filtreleri yeniden kullanıldı. Dependency veya DB connection ayarı değişmedi.

## Gerçek doğrulama ve teslim

17 Ekim 2026, Windows/Ruby 3.4.7/Rails 8.1.4/PostgreSQL 17:

| Kontrol | Gerçek sonuç |
|---|---|
| `bundle exec rails test` | seed 38455: **67 runs, 924 assertions, 0 failures, 0 errors, 0 skips** |
| `bundle exec rails test:system` | seed 32970, gerçek headless Edge: **9 runs, 104 assertions, 0 failures, 0 errors, 0 skips** |
| Toplam | **76 test, 1.028 assertion**, sıfır failure/error/skip; 13 yeni parola testi |
| `bundle exec rails zeitwerk:check` | All is good |
| `bundle exec brakeman --no-pager --quiet` | Brakeman 8.1.0, Errors 0 / Security Warnings 0 / exit 0. Windows fork/Ractor/Forwardable stderr fallback mesajları önceki taramalardaki gibi görülür; final rapor sıfırdır |
| Production assets | `RAILS_ENV=production SECRET_KEY_BASE_DUMMY=1 bundle exec rails assets:precompile`, child process ortamıyla exit 0; yeni visibility JS ve CSS derlendi |
| Kaynak/secret kontrolü | Gitleaks staged scan: 0 leak; yeni scanner istisnası yok. Testlerde replacement/temporary parolalar bellekte rastgele üretilir. 20 eski korunan kaynak/test dosyasının hash'i ve yerel master key değişmedi; yetkili schema değişikliği ayrıca incelendi. Markdown link/anchor ve whitespace kontrolleri geçti |

Yeni testler iki rolün kendi parolası; yanlış current/min/max/confirmation/aynı parola; role/tenant hedefleme; eski ve yeni login; cookie/DB session rotation ve diğer oturum iptali; eski cookie replay; anonim/expired/revoked session; geçici onboarding GET/POST/PATCH/signup bypass ve logout; eski hesap/default uyumu; CSRF token'sız ve geçerli token'lı HTTP; secret filtering; hesap başına rate-limit ve 10 dakika sonrası açılmayı kapsar. Başarısız validasyonda memory'deki assigned flag DB'den yeniden yüklenir; zorunlu parola ekranı/CRM kısıtı hata sayfasında da korunur.

İki yeni gerçek browser testi manager login → Settings → parola değişimi → logout → eski parola red/yeni parola kabul → salesperson oluşturma → geçici login → CRM engeli → zorunlu değişim → CRM erişimi akışını ve validation sonrası boş alanları, Show/Hide, 390px, light/dark görünümü çalıştırır. Mevcut workspace signup, lead/contact/conversion, opportunity stage/terminal, NBA, Customer 360, analytics, tenant/owner ve üç zaman kuralı testleri tam suite içinde geçti. Önceki migration'lar ve mevcut test dosyaları değiştirilmedi; schema'da yalnız yeni boolean ve Rails'in ürettiği sürüm başlığı değişti.

## GitHub CI ve Railway: gerçekten doğrulanan sonuç

Uygulama commit'i: [0feb82ddd8d1d66ec2db10e3b3cc287c64305671](https://github.com/Montaserissa20/leadcurrent/commit/0feb82ddd8d1d66ec2db10e3b3cc287c64305671). [LeadCurrent CI run 39045799534](https://github.com/Montaserissa20/leadcurrent/actions/runs/39045799534): **success**, exact SHA eşleşti. Job `117434148349` gerçek log'unda 17 Ekim 15:37:13 UTC: **67/924**; 15:37:37 UTC gerçek Chrome: **9/104**, sıfır failure/error/skip. PostgreSQL hazırlığı, Zeitwerk, Brakeman ve production assets adımları da success.

**Railway deployment: PASS.** Aynı SHA için Railway entegrasyonunun GitHub commit-status context'i `resourceful-nature - leadcurrent` success; [deployment 7141826282 status kaydı](https://api.github.com/repos/Montaserissa20/leadcurrent/deployments/7141826282/statuses) 17 Ekim **18:37:46 Europe/Istanbul** anında success. Bu, doğrudan Railway panel okuması değil, Railway'in GitHub'a gönderdiği aynı commit'e bağlı deployment sonucudur. Ardından gerçek public uygulamada yeni davranış test edildi. `/up` 200 / database connected ve `/login` 200 ayrıca gözlendi. Manuel redeploy, production SQL/reset, kullanıcı silme veya Railway credential/env değişikliği yapılmadı.

## Gerçek production browser testi

**PASS: 9/9 vaka**, 17 Ekim **18:39:13–18:39:48 Europe/Istanbul**; gerçek headless Edge, localhost yerine Railway URL'si. [Redakte edilmiş zaman/sonuç metadatası](evidence/password-production-2026-10-17.json) source commit'i içerir; parola, e-posta, cookie/token, HTML veya screenshot içermez.

| Vaka | Gözlenen sonuç |
|---|---|
| P01 | Tek yeni kurgusal workspace/manager oluşturuldu; manager iki ayrı browser session'ında giriş yaptı |
| P02 | Manager Security & Password formu görüldü; yanlış current parola reddedildi, bütün parola alanları boş döndü |
| P03 | Manager parolası değişti; aynı browser Settings'te giriş yapmış kaldı, ikinci browser yeni root isteğinde login'e gitti |
| P04 | Manager logout → eski parola reddi → yeni parola kabulü gerçekleşti |
| P05 | Manager yalnız QA workspace'ine bir yeni salesperson/geçici parola ekledi |
| P06 | Salesperson geçici login sonrası zorunlu parola ekranına gitti; `/leads` engellendi, CRM navigasyonu yoktu; logout çalıştı ve tekrar geçici login aynı ekrana döndü |
| P07 | Salesperson geçici parolayı değiştirdi; Settings, Overview ve Analytics'e erişti |
| P08 | Salesperson logout → geçici parola reddi → yeni parola kabulü; Settings'te kendi güvenlik formu var, team-create formu yok |
| P09 | 390px light/dark formu taşma olmadan açıldı; Show/Hide gerçek input tipini değiştirdi |

Kasıtlı hatalı-parola vakalarının HTTP 422 console resource kayıtları beklenir; beklenmeyen SEVERE JavaScript/CSP hatası gözlenmedi. Bu canlı test rate-limit saldırısı veya başka müşterinin kullanıcı/oturum/parola değişimi yapmadı; CSRF, yetki hedefleme, cookie replay, rate-limit ve tam CRM regresyonları yerel/CI suite'inde ayrıca kanıtlıdır. İki QA hesabının rastgele parolaları yalnız süreç belleğinde tutuldu; hiçbir mevcut production kullanıcısı değiştirilmedi. Yeni QA workspace/hesapları silinmedi.

Bu üretim/CI kaydını ekleyen son belge commit'i yalnız README, bu rapor ve redakte kanıtı değiştirir. Son HEAD'in **LeadCurrent CI** sonucu ve Railway deployment durumu push sonrası ayrıca exact-commit sorgulanıp teslim mesajında bildirilir. Yukarıdaki production browser çalışması source `0feb82d` üzerinde yapıldı; son belge commit'inde yeniden tam browser turu yapılmış gibi sunulmaz.
