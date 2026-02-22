source "https://rubygems.org"

rails_version = ENV.fetch("RAILS_VERSION", "8.1")

gemspec

if rails_version == "main"
  gem "activerecord", github: "rails/rails", branch: "main"
  gem "railties", github: "rails/rails", branch: "main"
else
  gem "activerecord", "~> #{rails_version}.0"
  gem "railties", "~> #{rails_version}.0"
end

gem "bundler", ">= 1.5"
gem "pg"
gem "pry"
gem "rake"
gem "redcarpet"
gem "rspec", ">= 3.3"
gem "standardrb"
gem "yard"
gem "warning"
