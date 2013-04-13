require 'singleton'

class Vigil
  class Environment
    include Singleton
  
    attr_accessor :system
    attr_accessor :plugman

    def initialize
      @system = System.new
      @plugman = Vigil.plugman
    end
  
  end
end
