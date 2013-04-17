class Vigil
  class Log

    def initialize
      @log = []
    end

    def <<(item)
      @log << item
    end

    def serialize
      @log.map {|i| i.serialize}
    end

  end
end
