# Fixture incelemesi — 14 Ekim 2026

Eski proje: `D:\ruby_project`. Salt okunur inceleme; eski uygulama/test/migration çalıştırılmadı, veritabanına bağlanılmadı, veri/anahtar/kod kopyalanmadı. Yeni proje: `D:\LeadCurrent`.

Gerçek yığın: Rails 8.0.x, SQLite, Devise, Pundit, Hotwire, Propshaft, RSpec, Chartkick, Pagy. Kodda RailCRM adı da mevcut. `tmp/ai-first-baseline-*` kopyaları ana uygulama sayılmadı. Proje LICENSE dosyası bulunmadığından kaynak yeniden kullanımı izni varsayılmadı. Uygulama kodu bağımsız yazılır.

| Kaynak / bileşen | Gözlem | Karar |
|---|---|---|
| `app/controllers/application_controller.rb`, `app/policies/*` | Devise, Pundit kapsamı ve doğrulama | Kapsam fikri; yeni organizasyon sınırlarıyla yeniden yaz |
| `app/models/company.rb`, `contact.rb`, `concerns/owned_associations.rb` | Şirket/kişi sahipliği | Yeni tenant ve şirket eşleşmesi doğrulamaları |
| `app/models/deal.rb`, `app/controllers/pipeline_controller.rb` | Lead ve deal tek model; kilit var fakat her listelenen aşamaya geçilebilir, terminal yeniden açılabilir | Ayrı Lead/Opportunity ve açık geçiş grafiği |
| `app/models/task.rb`, `note.rb`, `activity.rb` | Görev gecikmesi ve polimorfik geçmiş | Yeniden yaz; planlanmış görevi tamamlanmış temas sayma |
| `app/controllers/dashboard_controller.rb` | DB toplamları, risk panelleri; para birimi ayrımı yok | DB hesaplamaları, para birimine göre toplam |
| `app/services/daily_plan_builder.rb`, `deal_risk_scorer.rb` | Deterministik öncelik, durgunluk/kapanış | Açıklanabilir Next Best Action, tek temas/takip formu |
| `app/services/suggestion_approval.rb`, `agent/plan_executor.rb` | Onay, kilit, yazma planı | Yetki ve işlem fikri; konuşma altyapısı kapsam dışı |
| `app/services/llm/provider.rb`, `llm/ollama_provider.rb` | Varsayılan yerel Ollama | Kullanma; temel akış AI bağımsız |
| `app/jobs/agent_execution_job.rb`, `intelligence_refresh_job.rb` | Async/inline işler | Senkron temel kurallar; process içi async kalıcı değildir |
| `db/schema.rb` | SQLite, FK, checks ve indeksler | Yeni PostgreSQL migration, ayrı DB, tekil lead dönüşümü |
| `spec/models`, `spec/requests`, `spec/services`, `spec/system/workflow_spec.rb` | Yetki/browser testleri; aşama atlama kabul ediliyor; 24 saat kuralı yok | Bağımsız Minitest, zaman ve geçiş testleri |
| CSS/view bileşenleri | Bootstrap ve çoklu CSS katmanları | Özgün LeadCurrent kimliği ve sade CSS |
| `.github/workflows/ci.yml` | SQLite; sistem testleri CI dışında | PostgreSQL ve yeni uçtan uca testler |

İşlevsellik değerlendirmesi kaynak incelemesidir; eski testler çalıştırılmadığından çalıştıkları iddia edilmez. Eski env, credential veya müşteri bilgisi okunmadı/kopyalanmadı.
