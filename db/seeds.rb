require "securerandom"
if Rails.env.production? && ENV["DEMO_SEED_ENABLED"] != "true"
  puts "Production demo seeding is disabled."
else
  email = ENV.fetch("DEMO_EMAIL", "demo@leadcurrent.test")
  password = ENV["DEMO_PASSWORD"] || (Rails.env.production? ? raise("Set DEMO_PASSWORD before production seeding") : "LeadCurrentDemo!2026")
  unless User.exists?(email: email)
    Organization.transaction do
      org = Organization.create!(name: "Current Studio")
      manager = User.create!(organization: org, name: "Alex Morgan", email: email, password: password, role: "manager")
      salesperson = User.create!(organization: org, name: "Jamie Park", email: "jamie@leadcurrent.test", password: password, role: "salesperson")
      samples = [
        ["Atlas Industries", "Enterprise rollout", "Casey Reed", 29.hours.ago, "new", 0],
        ["Nova Systems", "Team workspace expansion", "Jordan Lee", 22.hours.ago, "new", 0],
        ["Cedar Labs", "Annual sales platform", "Riley Quinn", 4.hours.ago, "new", 0],
        ["Horizon Works", "Strategic partnership", "Taylor Brooks", 5.days.ago, "negotiation", 42000],
        ["Northstar Digital", "Customer success workspace", "Drew Ellis", 4.days.ago, "proposal", 18500],
        ["Meadow Collective", "Regional team rollout", "Robin Avery", 3.days.ago, "qualification", 27000],
        ["Stonebridge Studio", "Annual agreement", "Alex Rowan", 6.days.ago, "won", 32000]
      ]
      samples.each_with_index do |(name, title, person, created_at, stage, value), index|
        company = Company.create!(organization: org, name: name, industry: "Technology")
        contact = Contact.create!(organization: org, company: company, name: person, email: "contact#{index}@example.test")
        owner = index == 5 ? salesperson : manager
        lead = Lead.create!(organization: org, owner: owner, company: company, contact: contact, title: title, created_at: created_at)
        AuditEvent.record!(manager, lead, "created")
        next if stage == "new"
        RecordActivity.call(lead, actor: manager, kind: "contact", body: "Completed discovery call; confirmed team requirements.")
        LeadTransition.call(lead, actor: manager, to: "qualified")
        deal = LeadConversion.call(lead, actor: manager, attributes: { title: title, value: value, currency: "USD", expected_closing_date: (index == 4 ? 3.days : 20.days).from_now.to_date })
        %w[proposal negotiation won].each do |next_stage|
          break if deal.status == stage
          OpportunityTransition.call(deal, actor: manager, to: next_stage)
        end
        deal.update!(last_activity_at: 80.hours.ago) if index == 3
      end
      puts "Fictional LeadCurrent workspace created. Demo email: #{email}. Password comes from DEMO_PASSWORD or the documented development-only default."
    end
  else
    puts "Demo account already exists; no records were changed."
  end
end
