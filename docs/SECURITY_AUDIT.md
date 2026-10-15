# Güvenlik denetimi

Tarih: 15 Ekim 2026. Başlangıç: `9949b3d8bb65e1ff1703b63f0cd6f032511faedf`. Kapsam mevcut LeadCurrent deposu, erişilebilir Git geçmişi, yerel kaynak arşivi ve yapılandırmadır. Uygulama yeniden kurulmadı; eski Fixture projesi, geliştirme verileri ve yerel master key korunur. Bu çalışma bir penetrasyon testi değildir.

## İncelenenler ve bulgular

| Alan | Yapılan kontrol | Sonuç / sınır |
|---|---|---|
| Git ve yerel envanter | Başlangıçta 157 tracked dosya, ignored/untracked yollar; config, CI, render.yaml, log/cache/DB/arşiv yolları | Gerçek `config/master.key` yerelde mevcut, ignored ve untracked. Yerel PostgreSQL ve runtime dosyaları `.local/` altında; bunlar dağıtılmamalı |
| Görünür geçmiş | Tüm erişilebilir uzak branch'ler fetch edilerek 11 commit; 171 blob üzerinde dosya adı, credential regex ve yerel secret ile tam eşleşme kontrolü | İncelenen kaynaklarda gerçek credential eşleşmesi bulunmadı. Silinmiş ref, fork veya erişilemeyen eski arşivler için yokluk kanıtı değildir |
| Public GitHub | API üzerinden mevcut varsayılan branch ağacı ve dosya-path commit sorguları | `config/master.key`, `config/credentials/production.key`, `.env`: mevcut içerik 404; görünür varsayılan branch path geçmişi 0 commit. `.gitignore` eski geçmişi silmez |
| Gitleaks | [v8.30.1 resmî release](https://github.com/gitleaks/gitleaks/releases/tag/v8.30.1), release SHA256 checksum doğrulaması; redakte edilmiş tüm-ref taraması | İlk taramada iki false positive: rapordaki public commit SHA ve auth testindeki sentetik parola. `.gitleaksignore` yalnız bu iki kesin fingerprint'i gerekçesiyle hariç tutar; gözden geçirilmiş tarama temiz |
| Ortam ve sırlar | Ortamda secret benzeri değişken varlığı ve yerel key değerleri yalnız bellekte, rapora yazılmadan tarandı | Değerler çıktıya, belgeye veya arşive eklenmedi. Encrypted `credentials.yml.enc` sır içeriği çözülmedi; key'den ayrı tutulur |
| Var olan kaynak ZIP | Yerelde bulunabilen 211 entry'li kaynak arşivinin yolları | Key, `.env`, PG verisi ve `.git` görülmedi; harmless runtime `.keep` entry'leri var. Önceki denetimde sözü edilen hassas tam-klasör ZIP'i burada bulunamadı; geçmişte dağıtılan kopyaların güvenli olduğu iddia edilmez |
| Rails güvenlik kontrolleri | Auth, yetki/scope, session, CSRF, password, üretim config ve debug davranışı | bcrypt, minimum 12 karakter parola; DB session 12 saat; production secure/HttpOnly/SameSite=Lax cookie ve SSL; CSRF exception; organizasyon scope ve owner/manager yetkisi; production debug kapalı. Production auth bypass veya global admin route bulunmadı |
| DB ve deploy sırları | database.yml, render.yaml, build script ve seed koşulları | Production `DATABASE_URL` ortamdan; Render ayrı DB binding ve üretilen `SECRET_KEY_BASE`; production demo seed için açıkça `DEMO_PASSWORD` gerekir. Geliştirme fixture parolaları gerçek hesap sırrı değildir; production'da tekrar kullanılmamalı |
| CI | PostgreSQL test fixture, workflow izinleri ve log yaklaşımı | `contents: read`; workflow'daki local test DB parolası disposable CI fixture'dır. Gerçek hesap token'ı veya production secret commit edilmemiştir |

Tarama raporları yalnız ignored `.local/` içinde redakte edilmiş metadata olarak saklanır. Tarayıcılar yalnız bildikleri biçimleri ve erişilebilen kaynakları kontrol eder; “hiç sır yoktur” garantisi verilmez.

## Düzeltilenler

Önceki ignore kuralları temel Rails sırlarını koruyordu; elle oluşturulan ZIP, dump, alternatif credential dosyası ve cache yollarını yeterince açık kapsamıyordu. `.gitignore` ve `.dockerignore` nested `.env`, key/PEM, yerel credential dosyaları, DB/dump, PostgreSQL dizinleri, arşiv ve cache türleriyle tamamlandı. Güvenli `.env.example` korunur. `.gitattributes` Git archive export'undan runtime ve hassas yolları çıkarır.

`script/package_source.rb` temiz ve commit edilmiş Git snapshot'ından ZIP üretir. Yerel klasörü kopyalamaz. Tracked hassas yol varsa export-ignore ile gizlemek yerine işlemi reddeder; symlink/submodule, geçersiz yol, duplicate entry, kaynak dışı dosya, boyut/encoding sınırı, credential imzası ve bilinen yerel secret eşleşmelerini kontrol eder. CI'nin tam olarak tanımlanmış disposable test DB URL'si dışında gömülü DB credential kabul edilmez. Kontrol bitmeden son ZIP yayımlanmaz; mevcut paket üzerine yazılmaz. Yeni uygulama bağımlılığı eklenmedi; mevcut rubyzip kullanılır.

## Güvenli paylaşım

Tercih edilen kaynak paylaşımı public Git deposunun bağlantısıdır. ZIP gerekiyorsa değişiklikleri incele, taramadan geçir ve commit et; working tree temiz olmalıdır:

```powershell
bundle exec ruby script/check_source_package.rb
bundle exec ruby script/package_source.rb
bundle exec ruby script/package_source.rb --verify .local/packages/LeadCurrent-<commit-ilk-12>.zip
```

Script dosya sayısını, commit'i, SHA256 ve kontrol sonucunu verir. Yalnız doğrulanan `.local/packages/LeadCurrent-<commit-ilk-12>.zip` paylaşılır. Klasörü Explorer ile topluca ZIP'lemek, `.local/`, `.git`, master key veya yerel PG dizinini paylaşmak güvenli prosedür değildir. Build sonrasında kaynak değişirse yeni commit için yeni paket oluşturulur. `--verify` mevcut ZIP'i değiştirmez. Sentetik kontrol script'i gerçek key'i fixture içine yazmaz; tehlikeli yollar ve sahte credential içerikleriyle reddetme davranışını sınar.

## Yetki gerektiren müdahaleler

Erişilebilen kaynaklarda gerçek secret ifşası doğrulanmadığından otomatik rotasyon veya Git geçmişi yeniden yazımı yapılmadı. Daha önce paylaşılan tam-klasör ZIP'inde `config/master.key`, gerçek token, DB credential veya PG verisi bulunduğu doğrulanırsa:

1. Hangi kopyaların kimlerle paylaşıldığını ve hangi sır/verinin etkilendiğini belirle; mümkünse dağıtımı durdur ve kopyaları geri çektir. Dosya adı raporlanır, içerik raporlanmaz.
2. Master key ile birlikte encrypted credentials erişimini değerlendir; encrypted dosyadaki ilgili servis sırlarını belirle. Sadece yeni key üretmek daha önce ifşa olmuş servis sırlarını geçersiz kılmaz.
3. Açık kullanıcı yetkisiyle etkilenen provider token/DB password gibi sırları döndür; DB dump/PG dosyasındaki kişisel veriler için ayrıca etki değerlendirmesi yap. Rails `SECRET_KEY_BASE` rotasyonu mevcut cookie/session'ları geçersiz kılabilir; credential encryption key değişimi ayrı bir işlemdir.
4. Gerekirse onaylı geçmiş temizliği ve alıcıların yeniden clone etmesi planlanır; Git history temizliği ifşa olmuş credential'ı iptal etmez. Sonra yeniden tarama ve yeni doğrulanmış ZIP yapılır.

Yerel master key silinmedi veya yenilenmedi; geliştirme DB'si silinmedi; production veri değişikliği ve history rewrite yapılmadı.

## Üretim için kalan konular

Yerel PG trust yalnız loopback geliştirme ortamına yöneliktir; production'a taşınmamalı. Production DB kullanıcı/şifre/TLS, backup/restore, secret erişimi ve retention operasyonel olarak doğrulanmalıdır. Oturum/tenant kontrolleri uygulama katmanında; DB RLS yoktur. Rate limiting process-local'dır; birden çok instance için ortak store gerekir. MFA, e-posta doğrulama ve parola kurtarma bulunmuyor. Gerçek domain belli olduğunda host allowlist, HTTPS/proxy ve cookie davranışı o ortamda kontrol edilmelidir.

Render dağıtımı yapılmadı; Free DB süresi ve uyuyan web servisi production sürekliliği sağlamaz. Public URL üzerinde health, yetki, kalıcılık ve iş akışı testi hâlâ gereklidir. Bu rapor güvenlik denetiminin tamamlandığını belirtir; production onayı veya ödevin bütün teslim şartlarının tamamlandığı iddiası değildir.

## Doğrulama kaydı

Mevcut Rails suite: 37 run / 401 assertion; headless Edge system suite: 2 run / 24 assertion; failure/error/skip yok. Zeitwerk geçti; Brakeman 8.1.0 sıfır warning/error verdi. Paket script'inin sentetik kontrolleri, gerçek Git archive üretimi ve son commit'in CI sonucu [doğrulama raporunda](AUDIT_VERIFICATION_TR.md) kaydedilir. Uygulama, test, schema/seed, Gemfile/lock ve route içerikleri başlangıç hash'leriyle karşılaştırılır.
