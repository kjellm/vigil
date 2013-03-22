source 'https://rubygems.org'

gem "dcell", "> 0.13.0.pre"
gem "plugman"
gem "toml"
gem "trollop"
gem "vagrant"
gem "veewee"
gem 'coveralls', require: false

group :test do
  gem "rake"
  gem "rspec"
end

group :development do
  gem "guard-rspec"
  if RUBY_PLATFORM.downcase.include?("darwin")
    gem 'rb-fsevent'
    gem 'terminal-notifier-guard'
  end
end
