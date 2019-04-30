appraise "rails40" do
  gem "activerecord", "~> 4.0.0"
  gem "railties", "~> 4.0.0"
  gem "pg", "~> 0.15"
end

appraise "rails41" do
  gem "activerecord", "~> 4.1.0"
  gem "railties", "~> 4.1.0"
  gem "pg", "~> 0.15"
end

appraise "rails42" do
  gem "activerecord", "~> 4.2.0"
  gem "railties", "~> 4.2.0"
  gem "pg", "~> 0.15"
end

if RUBY_VERSION > "2.2.0"
  appraise "rails50" do
    gem "activerecord", "~> 5.0"
    gem "railties", "~> 5.0"
  end

  appraise "rails51" do
    gem "activerecord", "~> 5.1"
    gem "railties", "~> 5.1"
  end

  appraise "rails52" do
    gem "activerecord", "~> 5.2"
    gem "railties", "~> 5.2"
  end

  appraise "rails-edge" do
    gem "rails", github: "rails/rails"
    gem "arel", :github => "rails/arel"
  end
end
