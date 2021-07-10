if RUBY_VERSION < "2.6.0"
  appraise "rails42" do
    gem "activerecord", "~> 4.2.0"
    gem "railties", "~> 4.2.0"
    gem "pg", "~> 0.15.0"
  end
end

if RUBY_VERSION >= "2.2.0"
  appraise "rails50" do
    gem "activerecord", "~> 5.0.0"
    gem "railties", "~> 5.0.0"
  end

  appraise "rails51" do
    gem "activerecord", "~> 5.1.0"
    gem "railties", "~> 5.1.0"
  end

  appraise "rails52" do
    gem "activerecord", "~> 5.2.0"
    gem "railties", "~> 5.2.0"
  end

end

if RUBY_VERSION >= "2.5.0"
  appraise "rails60" do
    gem "activerecord", "~> 6.0.0"
    gem "railties", "~> 6.0.0"
  end

  appraise "rails61" do
    gem "activerecord", "~> 6.1.0"
    gem "railties", "~> 6.1.0"
  end
end

if RUBY_VERSION >= "2.7.0"
  appraise "rails-edge" do
    gem "rails", github: "rails/rails", branch: "main"
    gem "arel", :github => "rails/arel"
  end
end
