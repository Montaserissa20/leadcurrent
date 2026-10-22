# frozen_string_literal: true

# Run with: bundle exec ruby script/package_source.rb
# Uses existing rubyzip (Selenium dependency), Git and Ruby standard libraries.
require "zip"
require "open3"
require "pathname"
require "tempfile"
require "fileutils"
require "digest"
require "json"

module LeadCurrentSourcePackage
  ROOT = File.expand_path("..", __dir__)
  OUTPUT_DIR = File.join(ROOT, ".local", "packages")
  MAX_TEXT_BYTES = 2 * 1024 * 1024
  MAX_ARCHIVE_BYTES = 100 * 1024 * 1024
  module_function

  def git(*arguments)
    stdout, _stderr, status = Open3.capture3("git", "-C", ROOT, *arguments, binmode: true)
    raise "Git command failed; no archive was published" unless status.success?
    stdout
  end

  def forbidden_path?(name)
    normalized = name.tr("\\", "/").downcase
    parts = normalized.split("/")
    return true if normalized.start_with?("/") || normalized.match?(/\A[A-Za-z]:/) || parts.any? { |part| ["..", ".git", ".local", ".bundle", ".cache", "node_modules", "pgdata", "postgres", "backups", "exports"].include?(part) }
    return true if normalized.match?(/[\x00-\x1f]/)
    return true if normalized.match?(%r{\A(?:log|tmp|storage|coverage|public/assets)(?:/|\z)})
    base = parts.last.to_s
    return true if base.match?(/\A\.env(?:\..*)?\z/) && base != ".env.example"
    return true if base.match?(/\.(?:key|pem|p12|pfx|db|sqlite\d*(?:-\w+)?|sql|dump|backup|log|zip|7z|tar|gz|tgz)\z/i)
    return true if [".pgpass", "pgpass.conf", ".netrc", "credentials.json", "credentials.yml"].include?(base)
    base.match?(/service-account.*\.json\z/i)
  end

  def local_secrets
    key = File.join(ROOT, "config", "master.key")
    values = File.file?(key) ? [File.binread(key).strip] : []
    values.concat(Dir.glob(File.join(ROOT, "config", "credentials", "*.key")).map { |p| File.binread(p).strip })
    values.concat(ENV.filter_map { |name, value| value if name.match?(/KEY|TOKEN|SECRET|PASSWORD|DATABASE_URL/) && value.bytesize >= 12 })
    values.reject(&:empty?).uniq
  end

  def inspect_content!(bytes, name, secrets)
    raise "File exceeds content verification limit: #{name}" if bytes.bytesize > MAX_TEXT_BYTES
    raise "Local secret match in #{name}; value redacted" if secrets.any? { |secret| bytes.include?(secret.b) }
    return if bytes.include?("\0") # Binary images: exact secret matching above still applies.
    text = bytes.dup.force_encoding(Encoding::UTF_8)
    raise "Unverifiable text encoding: #{name}" unless text.valid_encoding?
    signatures = [
      /\blc_agent_[a-f0-9]{24}\.[A-Za-z0-9_-]{43}\b/,
      /\bgsk_[A-Za-z0-9_-]{20,}\b/,
      /-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----/,
      /\b(?:gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{35,})\b/,
      /\b(?:sk-(?:proj-)?[A-Za-z0-9_-]{24,}|nvapi-[A-Za-z0-9_-]{24,})\b/,
      /\b(?:AKIA|ASIA)[A-Z0-9]{16}\b/,
      /(?:secret_key_base|api_key|access_token)\s*[:=]\s*["'][A-Za-z0-9_\-+\/=]{20,}["']/i
    ]
    raise "Credential signature in #{name}; value redacted" if signatures.any? { |pattern| text.match?(pattern) }
    text.scan(%r{postgres(?:ql)?://[^\s"'<>]+:[^\s"'<>]+@[^\s"'<>]+}).each do |url|
      fixture_url = "postgresql://" + "postgres:postgres" + "@127.0.0.1:5432/leadcurrent_test"
      test_only = name == ".github/workflows/ci.yml" && url == fixture_url
      raise "Embedded database credential in #{name}; value redacted" unless test_only
    end
  end

  def verify_archive!(archive_path, expected: nil)
    secrets = local_secrets
    seen, file_count, total = {}, 0, 0
    Zip::File.open(archive_path) do |zip|
      zip.each do |entry|
        raise "Forbidden archive path: #{entry.name}" if forbidden_path?(entry.name)
        raise "Duplicate archive entry: #{entry.name}" if seen[entry.name]
        seen[entry.name] = true
        raise "Symlink in archive: #{entry.name}" if entry.ftype == :symlink
        next if entry.directory?
        total += entry.size
        raise "Archive exceeds verification limit" if total > MAX_ARCHIVE_BYTES
        raise "File exceeds verification limit: #{entry.name}" if entry.size > MAX_TEXT_BYTES
        raise "Non-source file in archive: #{entry.name}" if expected && !expected.include?(entry.name)
        entry.get_input_stream { |stream| inspect_content!(stream.read(MAX_TEXT_BYTES + 1) || "".b, entry.name, secrets) }
        file_count += 1
      end
    end
    raise "Empty source archive" if file_count.zero?
    { files: file_count, uncompressed_bytes: total, sha256: Digest::SHA256.file(archive_path).hexdigest }
  end

  def build!
    # Require a reviewable committed snapshot; ignored local state is never read as source.
    raise "Commit reviewed source changes before packaging" unless git("status", "--porcelain", "--untracked-files=normal").strip.empty?
    commit = git("rev-parse", "--verify", "HEAD^{commit}").strip
    records = git("ls-tree", "-rz", "--full-tree", commit).split("\0")
    expected = []
    secrets = local_secrets
    records.each do |record|
      metadata, name = record.split("\t", 2)
      mode, type, blob = metadata.split(" ")
      raise "Unsupported Git entry: #{name}" unless type == "blob" && %w[100644 100755].include?(mode)
      # A sensitive tracked path is an error even if export-ignore would hide it.
      next if name.end_with?("/.keep") && name.match?(%r{\A(?:log|tmp|storage)/})
      raise "Forbidden tracked source path: #{name}" if forbidden_path?(name)
      inspect_content!(git("cat-file", "blob", blob), name, secrets)
      expected << name
    end
    FileUtils.mkdir_p(OUTPUT_DIR)
    raise "Package directory cannot be a symlink" if File.symlink?(OUTPUT_DIR) || File.realpath(OUTPUT_DIR) != File.expand_path(OUTPUT_DIR)
    target = File.join(OUTPUT_DIR, "LeadCurrent-#{commit[0, 12]}.zip")
    raise "Archive already exists; refusing to overwrite it" if File.exist?(target)
    result = nil
    Tempfile.create(["leadcurrent-", ".zip"], OUTPUT_DIR) do |temporary|
      temporary.close
      git("archive", "--format=zip", "--output=#{temporary.path}", commit)
      result = verify_archive!(temporary.path, expected: expected)
      File.open(target, File::WRONLY | File::CREAT | File::EXCL, 0o600) do |output|
        File.open(temporary.path, "rb") { |input| IO.copy_stream(input, output) }
      end
    end
    puts JSON.pretty_generate(result.merge(commit: commit, archive: target, status: "verified"))
    target
  end
end

if $PROGRAM_NAME == __FILE__
  begin
    if ARGV.length == 2 && ARGV.first == "--verify"
      puts JSON.pretty_generate(LeadCurrentSourcePackage.verify_archive!(File.expand_path(ARGV.last)).merge(status: "verified"))
    elsif ARGV.empty?
      LeadCurrentSourcePackage.build!
    else
      raise "Usage: bundle exec ruby script/package_source.rb [--verify ARCHIVE.zip]"
    end
  rescue StandardError => error
    warn "Packaging rejected: #{error.message}"
    exit 1
  end
end
