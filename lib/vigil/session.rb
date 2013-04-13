require 'singleton'

class Vigil
  class Session
    include Singleton
    
    attr_accessor :revision
  end
end
