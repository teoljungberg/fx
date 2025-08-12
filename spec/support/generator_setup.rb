module GeneratorSetup
  RAILS_ROOT = Pathname.new(File.expand_path("../../../tmp/dummy", __dir__)).freeze
  MIGRATION_TIMESTAMP_PATTERN = /\d+_/

  def run_generator(generator_class, args = [], options = {})
    allow(Rails).to receive(:root).and_return(RAILS_ROOT)
    generator = generator_class.new(args, options, destination_root: RAILS_ROOT)

    silence_stream($stdout) do
      generator.invoke_all
    end
  end

  def file(relative_path)
    RAILS_ROOT.join(relative_path)
  end

  def migration_content(file_path)
    migration_path = find_migration_files(file_path).first
    return if migration_path.nil?

    Pathname.new(migration_path).read
  end

  def find_migration_files(file_path)
    directory = File.dirname(file_path)
    basename = File.basename(file_path, ".rb")
    Dir.glob(File.join(directory, "*#{basename}.rb"))
  end

  def expect_to_be_a_migration(pathname)
    migration_files = find_migration_files(pathname)

    expect(migration_files).to be_present,
      "expected #{pathname} to be a migration file"
    first_migration = migration_files.first
    expect(first_migration).to match(MIGRATION_TIMESTAMP_PATTERN),
      "expected #{first_migration} to have timestamp prefix (format: YYYYMMDDHHMMSS_)"
  end
end

RSpec.configure do |config|
  config.include GeneratorSetup, :generator

  config.before(:each, :generator) do
    FileUtils.rm_rf(GeneratorSetup::RAILS_ROOT) if File.exist?(GeneratorSetup::RAILS_ROOT)
    FileUtils.mkdir_p(GeneratorSetup::RAILS_ROOT)

    allow(Rails).to receive(:root).and_return(Pathname.new(GeneratorSetup::RAILS_ROOT))
  end
end
