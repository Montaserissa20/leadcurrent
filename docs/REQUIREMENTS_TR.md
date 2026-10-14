# Gereksinim → uygulama → test haritası

| Gereksinim | Uygulama | Kanıt / test |
|---|---|---|
| Bağımsız Rails / PostgreSQL | Gemfile, config/database.yml, db/migrate | Yeni repo ve iki izole DB; zeitwerk |
| Authentication / tenant separation | sessions, registrations, WorkspaceAccess, TenantRecord | authentication_test, sales_flow_test yetki/tamper/CSRF |
| Lead create/edit/assign | CreateLead, LeadsController | sales_flow_test, workflow_test |
| Şirket ve kişi | Company, Contact; CreateLead transaction | Validasyon ve orphan rollback testi |
| Contact / notes / tasks / history | RecordActivity, ScheduleFollowUp, AuditEvent | deadline_test, sales_flow_test |
| Qualification / conversion | LeadTransition, LeadConversion | workflow_test; concurrent_conversion_test |
| Opportunity stages / terminal | OpportunityTransition | Tüm durum çiftleri, HTTP ve gerçek browser akışı |
| 24 saat zaman kuralı | FollowUpDeadline, Lead | deadline_test: gerçek travel_to, boundary, timezone, DST |
| Next Best Action | NextBestAction, ActionsController, dashboard | ranking/reasons/action/tenant/no-AI + browser tek submit |
| DB dashboard / currency totals | DashboardController | sales_flow_test, browser refresh |
| Kanban / filters | opportunities/pipeline, filter_records | stage form persistence ve filtre testleri |
| Responsive / theme | appearance_controller.js, application.css | mobile, theme persistence browser testi |
| CI | .github/workflows/ci.yml | GitHub named workflow + exact commit; VERIFICATION_TR |
| Render | render.yaml, render-build.sh, HealthController | Yapılandırma hazır; hesap bağlantısı ve public smoke bekliyor |
| Araştırma / gerçek yorum / maliyet | README.md | Sourced tables, sınırlar, COSTS_TR |
| Agent / sunum | AGENT.md, PRESENTATION_TR.md | Kaynak dosyalarından hesaplanmış satır konumları |

**Henüz tamamlanmayan zorunlu koşul:** doğrulanmış genel Render URL'si ve üretimde uçtan uca kontrol. Puan garantisi yoktur.
