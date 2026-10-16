# Adaptasyonun kanıtı ve özgünlük sınırı

16 Ekim 2026. Çalışan kullanım kolaylığı: **PASS**. PDF s.35'in “orijinalde olmayan adaptasyon” şartı: **PARTIAL; kanıtlanmadı**. Bu rapor 100+ not veya Salesforce'ta bulunmayan özellik iddiası değildir.

## Gerçek şikâyet ve etkilenen kişi

[Capterra Salesforce Sales Cloud yorumları](https://www.capterra.com/p/61368/Salesforce/reviews/): **khyan A.**, Senior Business Development Representative, Computer Software, 15 Mart 2026. Yorum başlığı “Powerful but heavy - great once it’s set up properly”. Karmaşıklık/maliyet, başlangıçta öğrenme ve kurulum yükü, fazla alan ve iş akışının arayüzü kalabalıklaştırması eleştiriliyor. Aynı kişi özelleştirme ve pipeline görünürlüğünü de olumlu buluyor. Kaynak 16 Ekim'de aynı URL'nin arama indeksindeki yazar/rol/tarih ve yorum metniyle yeniden eşleştirildi. Önceki doğrudan sayfa okumasındaki erişim hatası [araştırma kaydında](RESEARCH_AUDIT_TR.md); indeks kanıtı canlı Salesforce kullanıcı testi değildir. Başka yorumcunun “fazla tıklama” sözü bu kişiye atfedilmedi.

Tasarım çıkarımımız: günlük müşteri temasını kaydeden satışçı, açıklanmış öneriden ayrılmadan temas sonucunu ve sonraki takibini kaydedebilirse daha az ekran bağlamı yönetir. Bu yorumcunun LeadCurrent'ı kullandığı veya bizim çözümümüzü onayladığı anlamına gelmez.

## Rakipte zaten ne var?

Salesforce'un [resmî Einstein Next Best Action belgesi](https://help.salesforce.com/s/articleView?id=platform.einstein_next_best_action.htm&language=en_US&type=5) önerileri iş kurallarına göre sunmayı açıklar. [Başlangıç kılavuzu](https://help.salesforce.com/s/articleView?id=sf.nba_implementation_checklist.htm&language=en_US&type=5) öneri, strateji ve kabul/red sonrası flow çalıştırma yeteneklerini listeler. Dolayısıyla öneri, açıklama veya eylem otomasyonu kategorilerinin Salesforce'ta bulunmadığı söylenemez. 16 Ekim kontrolü resmî dokümanlara dayanır; belirli bir müşteri hesabının yapılandırması test edilmedi.

LeadCurrent'ın somut tercihi: ilk temas ve takip görevini tek dashboard formu/transaction içinde birleştiren, nedeni ve sabit önceliği görünür olan hazır akış. Kullanıcı strateji veya flow kurmaz; dış AI sağlayıcısı yoktur. Bu, bizim uygulamamızın kapsamıdır; Salesforce'un eşdeğer biçimde yapılandırılamayacağı sonucu çıkarılamaz. Kaynak: [öneri servisi](../app/services/next_best_action.rb), [inline form](../app/views/shared/_action_form.html.erb), [endpoint](../app/controllers/actions_controller.rb), [atomik servis](../app/services/record_activity.rb). Görev bitirme ve stage ilerletme de dashboard'dadır; görev bitirmek tamamlanmış görüşme kaydetmez.

## Gerçek tarayıcı ölçümü ve demo

[adaptation_interaction_test.rb:4](../test/system/adaptation_interaction_test.rb#L4), gerçek headless Edge + PostgreSQL ile çalıştırıldı. Girişten sonra dashboard açık; tek gecikmiş lead var; varsayılan completed-contact/phone-call ve yarın takip tarihi korunur.

1. “What happened?” alanına fareyle tıklayın ve gerçek demo görüşmesinin sonucunu yazın.
2. “Save action” düğmesine tıklayın.
3. Contacted ve ilk-temas zamanını, tek contact Activity ve tek pending Task'ı DB'den; başarı bildirimi ve önerinin kalkmasını tarayıcıdan doğrulayın.

Sonuç: **2 fare tıklaması, 1 form submit olayı, 1 POST ActionsController#create, 0 lead-profil ziyareti**. Form üzerindeki browser olayları `sessionStorage` ile sayılır; gerçek istek sayısı Rails `process_action.action_controller` bildirimiyle ölçülür. Redirect/dashboard yenilemesi gerçekleşir: “0 navigasyon” tüm ağ isteklerinin sıfır olduğu anlamına gelmez. Login ve başlangıç ekranını açmak ölçüm dışında; yazılan metin, klavye hareketleri, başka yöntem veya tarih seçimi ayrıca etkileşimdir. Ölçüm süre/üretkenlik karşılaştırması değildir.

```text
bundle exec rails test test/system/adaptation_interaction_test.rb
seed 29816
1 runs, 12 assertions, 0 failures, 0 errors, 0 skips
```

Aynı test tam `test:system` suite'ine ve CI'a dahildir. 16 Ekim önceki [gerçek Railway testi](PRODUCTION_TEST_REPORT.md) çalışan contact/followup/task/stage akışını da doğrular; bu yeni sayaç ölçümü yerel test ortamındadır. Salesforce için tıklama, süre, kurulum emeği veya kullanıcı başarı oranı ölçülmedi; sayısal üstünlük iddiası yoktur.

## 100+ için dar aday ve açık kalan kanıt

Mevcut NBA tek başına özgünlük şartını ispatlamaz. Şikâyete bağlı dar aday: **bekleyen takip kartında, gerçek görüşme yapıldıysa, “görevi bitir + görüşmeyi kaydet + sonraki takibi planla” işlemlerini tek formda birleştirmek**. Mevcut [recommendation:6](../app/views/shared/_recommendation.html.erb#L6) görev tamamlama sonrası contact için profile gitmeyi açıkça ister; aday bu somut bağlam değişimini azaltır. Kullanım kolaylığı gerekçesi kaynaklıdır, Salesforce'ta yokluğu kanıtlanmış değildir.

Bu aday bu teslimde uygulanmadı. Önce belirli bir Salesforce kurulumu/ürün kapsamı için eşdeğer akış araştırması ve öğretim görevlisinin adaptasyon yorumunun netleşmesi gerekir. Güvenli uygulama kabul ölçütleri: opsiyonel gerçek-contact beyanı; task completion tek başına ilk teması kapatmaz; tek kilitli transaction ve audit; başarısız takip tarihinde tüm yazmalar rollback; tenant/owner/terminal kontrolleri; tekrar submit ve gerçek browser testleri. Belgesiz yeni iş kuralı eklemek özgünlük eksikliğini kanıtlamaz. İlgili kapanmamış madde [kontrol listesinde](ASSIGNMENT_CHECKLIST.md) korunur.

## Tek cümlelik sunum açıklaması

“Günlük müşteri temasını kaydeden satışçı, karmaşık ekranlar arasında dolaşma yükünü azaltmak için LeadCurrent dashboard'undaki gerekçeli karttan görüşme sonucunu ve sonraki takibini tek gönderimde kaydeder; Salesforce'ta bulunmadığını kanıtlamış değilim.”
