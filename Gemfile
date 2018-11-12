source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "2.5.3"

gem "activeadmin"
gem "addressable"
gem "bootsnap", ">= 1.1.0", require: false
gem "devise"
gem "faraday"
gem "pg"
gem "puma", "~> 3.11"
gem "rack-cors", :require => "rack/cors"
gem "rails", "~> 5.2.1"
gem "rufus-scheduler"
gem "timber", "~> 2.3"

group :development, :test do
  gem "byebug", platforms: [:mri, :mingw, :x64_mingw]
  gem "dotenv-rails"
  gem "factory_bot_rails", "~> 4.0"
  gem "rspec-rails", "~> 3.7"
  gem "webmock"
end

group :test do
  gem "simplecov", require: false
end

group :development do
  gem "listen", ">= 3.0.5", "< 3.2"
  gem "spring"
  gem "spring-commands-rspec"
  gem "spring-watcher-listen", "~> 2.0.0"
end
