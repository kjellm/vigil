source 'https://rubygems.org'

gem "dcell", "> 0.13.0.pre"
gem "plugman", "~> 1.0.2"
gem "toml"
gem "trollop"
gem "vagrant"
gem "veewee"
gem "redcarpet"

group :test do
  gem 'coveralls'
  gem "rake"
  gem "rspec"
end

group :development do
  gem "simplecov"
  gem "guard-rspec"
  gem "pry"
  gem "awesome_print"
  gem "pry-exception_explorer"
  if RUBY_PLATFORM.downcase.include?("darwin")
    gem 'rb-fsevent'
    gem 'terminal-notifier-guard'
  end
end
