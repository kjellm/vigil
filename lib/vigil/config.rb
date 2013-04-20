require 'toml'

class Vigil
  class Config

    def initialize(opts={})
      root = File.join(File.dirname(__FILE__), '..', '..')
      p root
      if !opts[:rcfile] and File.exists?(File.join(root, '.git'))
        opts[:rcfile] = File.join root, 'vigil.toml'
      end

      @opts = TOML.load_file(opts[:rcfile]).merge(opts)
      @opts['run_dir'] ||= File.expand_path('run') # FIXME make absolute
      @opts
    end

    def [](key)
      @opts[key]
    end

    def fetch(key)
      @opts.fetch(key)
    end

  end
end
