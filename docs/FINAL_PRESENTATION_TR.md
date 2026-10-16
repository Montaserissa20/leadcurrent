# Beş dakikalık canlı sunum

Canlı uygulama: https://leadcurrent-production.up.railway.app — 16 Ekim 2026 üretim kontrolü ve kapsamı [test raporunda](PRODUCTION_TEST_REPORT.md). Parola göstermeyin; kendi özel sunum hesabınızı kullanın. Önce `/up` ve son ilgili [LeadCurrent CI](https://github.com/Montaserissa20/leadcurrent/actions/workflows/ci.yml) run'ını kontrol edin. Ekranda eski QA kayıtlarını değiştirmek yerine yeni, kurgusal bir sunum kaydı oluşturun.

## 0:00–0:30 — SaaS, müşteri ve aort dilimi

“İlham ürünüm Salesforce Sales Cloud. Ford'un Fortune üyeliği resmî profille; ürün kullanımı müşteri hikâyesiyle kaynaklıdır. Ücretli sözleşme tutarı kamuya açık değil. LeadCurrent bağımsız marka ve uygulamadır. Aort dilimim yeni lead → tamamlanmış temas → qualification → opportunity → Won/Lost.” [Ford ürün kanıtı](https://www.salesforce.com/ca/customer-stories/ford-reinventing-customer-experience/), [Fortune profili](https://fortune.com/company/ford-motor/). Tam nüfus min/max ile örneklem/benchmark ayrımını README'de gösterin.

## 0:30–2:30 — Gerçek canlı satış akışı

1. Railway URL'sinde giriş yapın. Overview'daki mevcut değerleri başlangıç olarak gösterin; kendi workspace'inizin toplamları rapordaki QA tutarlarıyla aynı olmak zorunda değildir.
2. **+ New lead**: “Sunum Lisansı”, kurgusal şirket/kişi ve `example.test` adresi. **Create lead**; listeden yeniden açıp 24 saat deadline'ını ve Customer 360 bölümünü gösterin.
3. Gerçekte yapılmış demo görüşmesini **What happened?** alanına yazın; **Activity = Completed customer contact**, **Save action**. Planlanan takip tek başına ilk temas değildir. Contacted durumunu gösterin.
4. **Mark qualified** → **Convert to opportunity**. Değer `15000`, para birimi USD ve gelecekte bir kapanış tarihi seçin. **Convert lead**.
5. **Next stage** alanında sırayla Proposal, Negotiation, Won ve **Move**. Her aşamadaki notice/status'u ve kapanış geçmişini gösterin.
6. Overview ve Analytics'i açın; yeni Won değerini, conversion oranını ve ayrı para birimlerini gösterin. Refresh; mümkünse logout/login sonrası aynı kaydı tekrar açın. Bunlar gerçek üretim yazmalarıdır; silme/reset yapmayın.

## 2:30–3:30 — Zaman kuralı ve geçiş testleri

| Gösterilecek yer | Gerçek dosya ve satır | Açıklama |
|---|---|---|
| 24 saat ve uyarı | [follow_up_deadline.rb:2](../app/services/follow_up_deadline.rb#L2), [satır 3](../app/services/follow_up_deadline.rb#L3) | `FIRST_CONTACT_WINDOW = 24.hours`, `WARNING_WINDOW = 4.hours` |
| Deadline sınırı | [deadline_test.rb:12](../test/models/deadline_test.rb#L12) | Gerçek `travel_to`: bir saniye önce, tam anda, bir saniye sonra; tam deadline zamanındadır |
| Lead grafiği | [lead_transition.rb:2](../app/services/lead_transition.rb#L2) | İzinli geçiş listesi; qualification için tamamlanmış contact gerekir |
| Fırsat grafiği | [opportunity_transition.rb:2](../app/services/opportunity_transition.rb#L2) | Won/Lost terminal; rastgele stage update reddedilir |
| Conversion güvenliği | [lead_conversion.rb:4](../app/services/lead_conversion.rb#L4), [workflow_test.rb:39](../test/models/workflow_test.rb#L39), [concurrent_conversion_test.rb:20](../test/models/concurrent_conversion_test.rb#L20) | Kilit/transaction, tek bağlı fırsat, eşzamanlı iki istekte tek dönüşüm |

`bundle exec rails test` ve `bundle exec rails test:system` sonuçlarını veya ilgili başarılı CI run'ını açın. Yerel/CI zaman testini canlıda zaman değiştirmiş gibi sunmayın. Üretimde 24/72 saat beklenmedi; kısa vadeli follow-up doğal zamanla ayrıca test edilir. Güncel sayılar test raporundadır.

## 3:30–4:30 — Doğrulanmış şikâyet ve Next Best Action

[Capterra yorumu](https://www.capterra.com/p/61368/Salesforce/reviews/): khyan A., 15 Mart 2026; kurulum/günlük kullanım karmaşıklığı ve maliyet eleştirisi. Tam bağlam ve erişim yöntemi README/araştırma raporunda. Başka yorumcunun “fazla tıklama” ifadesini bu kişiye atfetmeyin; rakipte NBA olmadığını iddia etmeyin.

Dashboard'da yeni lead önerisinin nedenini ve doğrudan contact formunu gösterin. Görüşme sonucunu yazıp **Save action** ile kaydedin: profil sayfasına gitmeden işlem yapılır, dashboard yeniden hesaplanır. Bugünkü takip varsa **Complete follow-up** ile bitirin; tamamlanmış görev gerçek contact yerine geçmez. Yakın kapanış önerisinde **Next stage → Move** çalışır. Her özelliğin üretim kanıtı test raporunda; Salesforce'a karşı ölçülmüş tıklama/süre üstünlüğü iddiası yoktur.

## 4:30–5:00 — İş kuralı nereden değişir?

- “48 saat olsun”: [follow_up_deadline.rb:2](../app/services/follow_up_deadline.rb#L2). Yeni lead deadline hesabı değişir; saklanmış eski deadline'lar kendiliğinden güncellenmez. Eski veriyi değiştirmek ayrı onaylı veri migration'ı gerektirir.
- “Proposal → Lost yasak”: [opportunity_transition.rb:3](../app/services/opportunity_transition.rb#L3); grafikte ilgili kenarı değiştirin, [bütün geçiş çiftleri testini](../test/models/workflow_test.rb#L60) güncelleyin.
- “NBA eşikleri/puanları”: [next_best_action.rb:2](../app/services/next_best_action.rb#L2), [satır 4](../app/services/next_best_action.rb#L4). Sıralama deterministiktir; dış AI servisine bağlı değildir.

Kapanışta [ödev kontrol listesindeki](ASSIGNMENT_CHECKLIST.md) PARTIAL/BLOCKED kalemleri dürüstçe belirtin. Gerçek billing/timesheet ve kapalı kaynak LOC belgesi yoktur; not garantisi verilmez.
