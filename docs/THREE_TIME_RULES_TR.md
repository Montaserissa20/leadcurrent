# Üç bağımsız zaman kuralı

16 Ekim 2026. Durum: **PASS**. `2026-10-12.pdf`, s.35 üç ayrı zaman kuralının `travel_to` ile testini ister. PDF'nin kimliği ve okunan sayfalar [PDF/G1–G5 denetiminde](G1_G5_AUDIT_TR.md) kayıtlıdır. İş kuralları değiştirilmedi; eksik sınır testleri eklendi.

| Kural ve iş amacı | Kaynak ve kesin satır | Gerçek sınır testi |
|---|---|---|
| İlk temas: lead oluşumundan 24 gerçek saat içinde tamamlanmış müşteri görüşmesi; adayın unutulmasını önler | [follow_up_deadline.rb:2](../app/services/follow_up_deadline.rb#L2), [hesap:4](../app/services/follow_up_deadline.rb#L4), [karşılaştırma:7](../app/services/follow_up_deadline.rb#L7); [Lead SQL scope:17](../app/models/lead.rb#L17) | [deadline_test.rb:12](../test/models/deadline_test.rb#L12): 24 saat − 1 saniye, tam 24 saat, 24 saat + 1 saniye. Hem model hem SQL scope doğrulanır |
| Acil uyarı: ilk temasa kalan süre ≤4 saat; ihlal oluşmadan satışçıyı uyarır | [WARNING_WINDOW:3](../app/services/follow_up_deadline.rb#L3), [next_best_action.rb:21](../app/services/next_best_action.rb#L21) | [time_rule_boundaries_test.rb:6](../test/models/time_rule_boundaries_test.rb#L6): lead yaşı 20 saat − 1 saniye / tam 20 saat / +1 saniye; kalan süre 4 saat +1 / tam 4 saat / −1 saniye; öncelik 50 / 90 / 90 |
| Fırsat hareketsizliği: son aktiviteden ≥72 gerçek saat sonra takip önerisi; duran satışın yeniden ele alınmasını sağlar | [INACTIVITY_WINDOW:2](../app/services/next_best_action.rb#L2), [SQL aday filtresi:30](../app/services/next_best_action.rb#L30), [karşılaştırma:33](../app/services/next_best_action.rb#L33) | [time_rule_boundaries_test.rb:20](../test/models/time_rule_boundaries_test.rb#L20): 72 saat −1 saniyede öneri yok, tam 72 saatte ve +1 saniyede öncelik 80 / `follow_up` |

24 saatin tam sınırı zamanındadır; ilk gecikme +1 saniyede başlar. Acil uyarı tam 4 saati kapsar; deadline geçince öncelik 100 olur. Üçüncü kuralda tam 72 saat kapsanır. Hareketsizlik testi, kapanışı 20 gün sonraya ayarlanmış ve bekleyen görevi olmayan aktif fırsatı kullanır; yakın kapanış veya görev önceliği sonucu gölgelemez. Gerçek uygulamada bekleyen takip bulunan fırsat için ikinci planlama önerisi bastırılır, Won/Lost dışlanır.

Not yazmak, geleceğe görev planlamak veya görevi tamamlamak ilk temas değildir ([deadline_test.rb:32](../test/models/deadline_test.rb#L32)). Tamamlanmış contact ilk zamanı kaydeder ve ilk-temas gecikmesini kaldırır; fırsat aktivitesi `last_activity_at` değerini yeniler ([RecordActivity:8](../app/services/record_activity.rb#L8)). Zaman DB'de UTC, gösterim kullanıcının saat dilimindedir. DST/gece yarısı ayrıca [deadline_test.rb:42](../test/models/deadline_test.rb#L42) içinde testlidir. 7 günlük kapanış ve günlük görev kuralları bu üçlüden ayrıdır.

## Gerçek çalıştırma

```text
bundle exec rails test test/models/deadline_test.rb test/models/time_rule_boundaries_test.rb
seed 62660
8 runs, 41 assertions, 0 failures, 0 errors, 0 skips
```

Bu komut altı mevcut deadline testi ile iki yeni bağımsız eşik testini çalıştırır. Yeni testlerde toplam 19 assertion vardır. Tam suite ve GitHub CI kanıtı [son doğrulama kaydındadır](G1_G5_AUDIT_TR.md#son-doğrulama).

## Sunumda 20 saniyelik açıklama

“İlk teması 24 gerçek saatte bekliyorum; tam deadline zamanında, bir saniye sonrası gecikmiş. Son dört saatte uyarıyorum. Fırsat 72 saat hareketsiz kalırsa takip öneriyorum. Her eşik için bir saniye önce, tam an ve bir saniye sonra gerçek `travel_to` testi var.” Kaynak sabitlerini ve testteki üç zaman noktasını gösterin; canlı üretim saatini değiştirmeyin. [Beş dakikalık sunum](FINAL_PRESENTATION_TR.md) bu açıklamaya mevcut bir dakikalık kod bölümünde yer verir.
