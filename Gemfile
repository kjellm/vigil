source 'https://rubygems.org'

gem "vagrant"
gem "veewee"
gem "trollop"
gem "plugman"
gem "dcell"

group :development do
  gem "rake"
  gem "rspec"
  gem "guard-rspec"

  if RUBY_PLATFORM.downcase.include?("darwin")
    gem 'rb-fsevent'
    gem 'terminal-notifier-guard'
  end
end
