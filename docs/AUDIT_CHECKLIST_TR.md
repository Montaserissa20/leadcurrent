# README, maliyet ve güvenlik düzeltme listesi

15 Ekim 2026. Kapsam: belge, güvenlik dosyaları ve kaynak paketleme; mevcut uygulama, iş kuralları, UI ve test mantığı korunur. Render dağıtımı yapılmaz. Başlangıç commit'i: `9949b3d8bb65e1ff1703b63f0cd6f032511faedf`.

- [x] README, AGENT/AGENTS, Gemfile/lock, CI, DB, credentials yaklaşımı ve Render yapılandırmasını incele.
- [x] Önce salt okunur Git/ignored/history/archive/env envanteri çıkar; gerçek değerleri yazdırma.
- [x] Erişilebilir bütün uzak branch geçmişini ve public GitHub master.key yokluğunu yeniden kontrol et.
- [x] Fortune tablosunu Minimum / Maksimum-Ortalama / Kaynak / Açıklama biçimine getir; örneklem ve nüfus sınırlarını koru.
- [x] Fortune müşteri kanıtlarını, Open Hub sayımını ve Capterra yorumunu yeniden doğrula (doğrudan erişim sınırı raporlandı).
- [x] Resmî fiyatlarla sayısal USD tahmini, token matematiği ve abonelik alternatifini yaz.
- [x] Gerçek tarihler ile bilinmeyen saat/fatura/model kullanımını ayrı tabloda göster; bilinmeyeni sıfır sayma.
- [x] Ignore ve Docker paylaşım kurallarını hassas dosya/dump/arşiv/cache kapsamıyla tamamla.
- [x] Yalnızca Git kaynaklarından üretip dosya adları ve içerik kontrolünden geçiren güvenli ZIP script'i ekle; normal ve reddetme yollarını doğrula.
- [x] docs/SECURITY_AUDIT.md yaz; eski güvensiz ZIP varsa koşullu müdahale/rotasyon adımlarını belirt.
- [x] Mevcut domain/HTTP/browser testlerini, Brakeman ve Zeitwerk kontrolünü çalıştır; gerçek çıktıyı kaydet.
- [x] Markdown, yerel link, dış kaynak, badge, diff ve tekrar secret taramasını doğrula.
- [x] Başlangıçtaki uygulama/test/DB/iş kuralı dosyalarının değişmediğini hash ile doğrula.
- [ ] Doğrulanmış değişiklikleri commit/push et; ilgili uygulama CI run'ını kontrol et.
- [x] Belge / güvenlik durumunu tamamla; CI teslim adımı aşağıdaki raporda izlenir; genel deployment eksikliğini açık bırak.

Yerel master key veya DB silinmez. Credential rotasyonu ve Git geçmişi yeniden yazımı yapılmaz. Eski Fixture projesinde işlem yapılmaz. Envanter ayrıntıları özel `.local/` dizininde kalır; paylaşılan rapor yalnızca redakte bulgular içerir.
