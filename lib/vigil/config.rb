require 'toml'

class Vigil
  class Config

    attr_reader :opts

    def initialize(opts={})
      root = File.join(File.dirname(__FILE__), '..', '..')
      p root
      if !opts[:rcfile] and File.exists?(File.join(root, '.git'))
        opts[:rcfile] = File.join root, 'vigil.toml'
      end

      @opts = TOML.load_file(opts[:rcfile]).merge(opts)
    end

    def [](key)
      @opts[key]
    end

    def fetch(key)
      @opts.fetch(key)
    end

  end
end
