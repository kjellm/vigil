source 'https://rubygems.org'

gem "plugman", "~> 1.0.2"
gem "toml"
gem "trollop"
gem "vagrant"
gem "veewee"
gem "redcarpet"
gem "logging"

group :test do
  gem 'coveralls'
  gem "rake"
  gem "rspec"
  gem "cucumber"
end

group :development do
  gem "simplecov"
  gem "guard-rspec"
  gem "guard-cucumber"
  gem "pry"
  gem "awesome_print"
  gem "pry-exception_explorer"
  if RUBY_PLATFORM.downcase.include?("darwin")
    gem 'rb-fsevent'
    gem 'terminal-notifier-guard'
  end
end
