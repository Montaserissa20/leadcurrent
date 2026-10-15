# frozen_string_literal: true

require_relative "package_source"
require "tmpdir"

checks = 0
FileUtils.mkdir_p(LeadCurrentSourcePackage::OUTPUT_DIR)
Dir.mktmpdir("package-check-", LeadCurrentSourcePackage::OUTPUT_DIR) do |directory|
  fixture = lambda do |name, content|
    path = File.join(directory, "fixture-#{checks}.zip")
    Zip::File.open(path, create: true) { |zip| zip.get_output_stream(name) { |stream| stream.write(content) } }
    path
  end
  reject = lambda do |path, message|
    begin
      LeadCurrentSourcePackage.verify_archive!(path)
    rescue RuntimeError => error
      raise unless error.message.include?(message)
      checks += 1
    else
      raise "Unsafe fixture accepted"
    end
  end

  %w[config/master.key config/credentials/production.key .env nested/.env.production .git/config .local/postgres/PG_VERSION pgdata/PG_VERSION log/development.log tmp/cache/file db/export.sql db/export.dump storage/local.sqlite3 private.pem credentials.json source.zip ../escape.txt].each do |name|
    reject.call(fixture.call(name, "synthetic fixture"), "Forbidden archive path")
  end
  # Rubyzip itself refuses to create absolute entry names; check our policy directly.
  raise "Absolute path accepted" unless LeadCurrentSourcePackage.forbidden_path?("/absolute.txt")
  checks += 1
  ["ghp_" + "A" * 36, "-----BEGIN " + "PRIVATE KEY-----"].each do |content|
    reject.call(fixture.call("README.md", content), "Credential signature")
  end
  database_canary = "postgresql://" + "user:synthetic-password" + "@db.example.test/app"
  reject.call(fixture.call("README.md", database_canary), "Embedded database credential")

  canary = "audit-only-" + "sensitive-canary"
  begin
    LeadCurrentSourcePackage.inspect_content!(canary, "README.md", [canary])
    raise "Exact-match fixture accepted"
  rescue RuntimeError => error
    raise unless error.message.include?("Local secret match")
    checks += 1
  end

  valid = fixture.call("README.md", "# Synthetic source\n")
  raise "Wrong file count" unless LeadCurrentSourcePackage.verify_archive!(valid, expected: ["README.md"])[:files] == 1
  checks += 1
  begin
    LeadCurrentSourcePackage.verify_archive!(valid, expected: ["Gemfile"])
    raise "Non-source fixture accepted"
  rescue RuntimeError => error
    raise unless error.message.include?("Non-source file")
    checks += 1
  end
  template = fixture.call(".env.example", "PGHOST=127.0.0.1\nSECRET_KEY_BASE=replace-with-your-own\n")
  LeadCurrentSourcePackage.verify_archive!(template)
  checks += 1
  empty_source = fixture.call("app/models/.keep", "")
  LeadCurrentSourcePackage.verify_archive!(empty_source)
  checks += 1
end
puts "Source package policy: #{checks} checks, 0 failures (synthetic fixtures only)"
