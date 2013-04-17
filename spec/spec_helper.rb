require 'simplecov'
require 'coveralls'


SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]
SimpleCov.start

require 'vigil'

FileUtils.mkdir_p File.join(File.dirname(__FILE__), '../tmp/')
Vigil.logger = Logger.new(File.join(File.dirname(__FILE__), '../tmp/specs.log'))

