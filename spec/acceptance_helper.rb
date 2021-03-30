require "bundler"

ENV["RAILS_ENV"] = "test"

RSpec.configure do |config|
  config.around(:each) do |example|
    Dir.chdir("spec/dummy") do
      example.run
    end
  end

  config.before(:suite) do
    Dir.chdir("spec/dummy") do
      system <<-CMD
        git init 1>/dev/null &&
        git add -A &&
        git commit --no-gpg-sign --message 'initial' 1>/dev/null
      CMD
    end
  end

  config.after(:suite) do
    Dir.chdir("spec/dummy") do
      ActiveRecord::Base.connection.disconnect!
      system <<-CMD
        echo &&
        rake db:environment:set db:drop db:create &&
        git add -A &&
        git reset --hard HEAD 1>/dev/null &&
        rm -rf .git/ 1>/dev/null
      CMD
    end
  end

  def successfully(command)
    `RAILS_ENV=test #{command}`
    expect($?.exitstatus).to eq(0), "'#{command}' was unsuccessful"
  end

  def write_aggregate_definition(file, contents)
    write_definition(file, contents, "aggregates")
  end

  def write_function_definition(file, contents)
    write_definition(file, contents, "functions")
  end

  def write_trigger_definition(file, contents)
    write_definition(file, contents, "triggers")
  end

  def write_definition(file, contents, directory)
    File.open("db/#{directory}/#{file}.sql", File::WRONLY) do |definition|
      definition.truncate(0)
      definition.write(contents)
    end
  end

  def verify_identical_definitions(def_a, def_b)
    successfully "cmp #{def_a} #{def_b}"
  end

  def execute(command)
    execute_raw(command).first
  end

  def execute_raw(command)
    ActiveRecord::Base.connection.execute(command)
  end
end
