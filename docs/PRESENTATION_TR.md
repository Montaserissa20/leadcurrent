# Beş dakikalık sunum

**Ön koşul:** Render yayınını bitirip doğrulanmış genel URL'yi README'ye ekleyin. Şu anda yalnızca yerel uygulama doğrulandı. Yerel gösterimi canlı genel yayınmış gibi anlatmayın. Geliştirme hesabı: demo@leadcurrent.test / LeadCurrentDemo!2026; production için ayrı parola kullanın.

## 0:00–0:30 — İş değeri

“Salesforce Sales Cloud'dan ilham aldım. Ford'un resmî müşteri hikâyesi Sales Cloud kullanımını gösteriyor; Fortune 2026 profili şirketin üyeliğini doğruluyor. Fatura tutarı açık değil. CRM'nin müşteriye değer katan merkezi akışı, yeni adayı tamamlanmış temastan satış fırsatına ve gelire taşımak. LeadCurrent'ta bu aort dilimini bağımsız gerçekleştirdim.” README'deki iki kaynak bağlantısını açın.

## 0:30–2:30 — Gerçek uygulama

1. Doğrulanmış yayın URL'sinde giriş yapın. Overview sayılarını gösterin.
2. + New lead → kurgusal “Sunum platformu”, “Ada Teknoloji”, “Deniz Kaya”, deniz@example.test. Save; 24 saat deadline'ı gösterin.
3. Tamamlanmış görüşmeyi açıklamaya yazın. Save action; varsayılan yarın takip tarihini koruyun. Contacted ve görev kaydı oluşsun.
4. Mark qualified; fırsat başlığı, 15000 USD, kapanış tarihi. Convert lead.
5. Move: Proposal, Negotiation, Won. Terminal durumu ve audit history'yi gösterin.
6. Overview'a dönüp won sayısı/geliri gösterin; yenileyin. Gerçek veritabanı kalıcılığını vurgulayın.

Pro kısa gösterimi: müşteri profilinde Customer 360, eski lead görüşmesi ve bağlı fırsatı birlikte açın; Create a task → Edit → Complete akışını gösterin. Task completion'ın ilk temas olmadığını vurgulayın. Analytics'te stage dağılımı, ayrı para birimleri ve converted / tüm lead oranını gösterin. Dashboard kartları eşleşen filtreli listeleri açar. Bugün/gecikmiş takip önerisini doğrudan tamamlayınca dashboard yeniden hesaplanır; satış aşaması yalnız açık kullanıcı işlemiyle değişir.

## 2:30–3:30 — Kural ve test

- Süre: `app/services/follow_up_deadline.rb`, **satır 2**. FIRST_CONTACT_WINDOW, deadline, overdue?. Tam deadline anı zamanında; bir saniye sonrası gecikmiş.
- Lead geçişi: `app/services/lead_transition.rb`, **satır 2** TRANSITIONS ve call. Opportunity: `app/services/opportunity_transition.rb`, **satır 2**.
- `test/models/deadline_test.rb`, **satır 12**, gerçek travel_to ile önce/tam/sonra boundary testini açın. Model sonuçları mock değil.
- `bundle exec rails test` çalıştırın; eşzamanlı dönüşüm ve yetki testlerine değinin. Gerçek CI workflow ekranını açın; kontrol edilen commit'i gösterin.

## 3:30–4:30 — Gerçek problem / Next Best Action

README'de khyan A.'nın 15 Mart 2026 Capterra yorumunu açın: karmaşıklık ve kalabalık alan/iş akışları eleştirisi. Ardından dashboard'daki deadline yaklaşan/overdue önerisini gösterin. Açıklama nedeniyle sıralamayı izleyin.

“What happened?” alanına gerçek tamamlanmış demo görüşmesi açıklaması yazın; varsayılan takip tarihini koruyup Save action'a basın. İki fare tıklaması (alana odak + submit), tek POST, başka sayfa açmadan temas ve takip. Yeni data oluştuğunu Tasks ve Activity'de doğrulayın. Salesforce tıklama sayısı ölçülmediğini açıkça söyleyin.

## 4:30–5:00 — Kural değiştirme sorusu

- “48 saat olsun”: follow_up_deadline.rb:2 FIRST_CONTACT_WINDOW = 48.hours; zaman testlerini yeni beklentiyle güncelleyin. Mevcut deadline'lar persisted olduğu için yalnızca kod değişikliği eski kayıtları geriye dönük değiştirmez; ayrı, açık onaylı veri migration gerekir.
- “Hafta sonunu sayma”: aynı serviste yeni çalışma takvimi politikası gerekir; mevcut elapsed-hour kuralında bu özellik yok. İstanbul ve DST/timezone sınırları için travel_to testleri eklenir. Hazırmış gibi göstermeyin.
- “Proposal → Lost yasak olsun”: opportunity_transition.rb:2 grafiğinden ilgili kenarı kaldırın; tüm geçiş çiftleri testini ve bu politika için açık beklentiyi güncelleyin. Model ve controller'a dağınık if eklemeyin.

Fixture hiç değiştirilmedi; yeni DB ve repo ayrı. Eksikleri README / Yapamadıklarım'dan dürüstçe belirtin.
