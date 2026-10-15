# Geliştirme maliyeti ve kanıt sınırları

Fiyat kontrolü: 15 Ekim 2026. Önceki rapordaki “yeni satın alma yok” gözlemi toplam gideri kanıtlamaz; bilinmeyen giderler sıfır olarak gösterilmez. Uygulamada AI API entegrasyonu olmaması, geliştirme agent'ının ücretsiz olduğu anlamına gelmez.

## A — Tahmin

| Kalem | Varsayım ve USD hesabı | Kanıt / sınır |
|---|---|---|
| Odaklı geliştirme | 30 saat; 5 iş günü × 6 saat, yaklaşık bir hafta | Planlama tahmini; insan/agent çalışma kaydı değildir |
| Token bütçesi | 2 milyon önbelleksiz input + 0,5 milyon faturalanan output | Output bütçesine reasoning token'ları dahildir; gerçekleşen tüketim değildir |
| GPT-5.4 Standard API | `2 × $2.50 + 0.5 × $15 = $12.50` | [Resmî model fiyatı](https://developers.openai.com/api/docs/models/gpt-5.4); her istek ≤272K input varsayımı |
| GPT-6.1 Sol Standard, kısa bağlam API | `2 × $2 + 0.5 × $10 = $9` | [Model](https://developers.openai.com/api/docs/models/gpt-6.1-sol), [fiyat tablosu](https://developers.openai.com/api/docs/pricing); cache hit/write yok |
| Duyarlılık, GPT-5.4 | 1M input + 0,25M output: $6.25; 4M + 1M: $25 | Aynı birim fiyat ve bağlam varsayımları; garanti bütçe tavanı değildir |
| Abonelik alternatifi | Plus $20/ay; Pro $100, $200 veya $500/ay | [Resmî Codex fiyatları](https://learn.chatgpt.com/docs/pricing); model erişimi ve kullanım sınırları plana bağlı |
| Ek araç satın alma | Senaryoda $0 ek satın alma ayrıldı | Fatura veya gerçekleşen harcama iddiası değildir; vergi, ek kredi ve isteğe bağlı araçlar hariç |
| Demo hosting | Render Free compute $0/ay; ücretli başlangıç web $7 + PostgreSQL $6 = $13/ay compute | [Free sınırları](https://render.com/docs/free), [resmî Rails fiyat rehberi](https://render.com/articles/production-rails-hosting-guide), [fiyatlar](https://render.com/pricing); depolama, trafik ve vergi eklenebilir |

API senaryosu ve aylık abonelik alternatif bütçelerdir; birbirine eklenmez. Abonelik bedeli ölçülmüş token harcaması değildir ve aylık bedel beş güne bölünerek gerçek maliyet üretilmez. Cache, bölgesel işlem, araç çağrıları, uzun bağlam ve vergiler hesabı değiştirebilir. Free PostgreSQL 30 günde sona erer; Free web 15 dakika boşta kalınca uyur. Ücretsiz demo üretim dayanıklılığı sağlamaz.

## B — Gerçekleşen ve bilinmeyen

| Kalem | Elde bulunan kanıt | Sonuç |
|---|---|---|
| Takvim | [İlk commit](https://github.com/Montaserissa20/leadcurrent/commit/96bd09f63c339b669188d29d2bce1491829f5b0e) ve [ilk teslim son commit'i](https://github.com/Montaserissa20/leadcurrent/commit/9949b3d8bb65e1ff1703b63f0cd6f032511faedf): 14 Ekim 2026; bu denetim: 15 Ekim 2026 | Git'te doğrulanabilen tarihler; commit öncesi çalışmayı kapsamaz |
| Çalışma saati | İlk teslim commit aralığı 16:57:57–17:17:48, UTC+03 | Toplam emek süresi değildir. Kesin kullanım veya ödeme verisi mevcut değil. |
| Agent/model | Çalışma ortamı Codex; hesapta faturalandırılan kesin model/çağrı raporu yok | Kesin kullanım veya ödeme verisi mevcut değil. |
| Ödenmiş abonelik | Fatura veya makbuz verilmedi | Kesin kullanım veya ödeme verisi mevcut değil. |
| API token ve ücret | Token dökümü/fatura yok | Kesin kullanım veya ödeme verisi mevcut değil. |
| Hosting ve GitHub gideri | Bu görevde Render deployment yapılmadı; hesapların ödeme raporlarına erişilmedi | Kesin kullanım veya ödeme verisi mevcut değil. |
| Gerçek toplam gider | Fatura kalemleri eksik | Kesin kullanım veya ödeme verisi mevcut değil. |

$9–$12.50 API bütçesi bir modelleme sonucudur. Gerçek fatura ve timesheet olmadan tasarruf yüzdesi, gerçekleşen toplam USD veya tahmine göre süre kazancı hesaplanamaz. README'deki tablolar bu ayrımı korur.
