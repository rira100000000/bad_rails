source "https://rubygems.org"

ruby "3.4.8"

gem "rails", "~> 7.1.3"
gem "sprockets-rails"
gem "sqlite3", "~> 1.4"
gem "puma", ">= 5.0"
gem "bcrypt", "~> 3.1.7"
gem "tzinfo-data", platforms: %i[ windows jruby ]
gem "bootsnap", require: false

# Rails 7 default form helpers / flashes
gem "turbo-rails"

group :development, :test do
  gem "debug", platforms: %i[ mri windows ]
  gem "rspec-rails", "~> 6.1"
  gem "factory_bot_rails"
end

group :development do
  gem "web-console"
end

group :test do
  gem "capybara"
  gem "rack-test"
end
