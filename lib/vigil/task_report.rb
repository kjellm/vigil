class Vigil
  class TaskReport

    attr_reader :name
    attr_reader :status
    attr_reader :log
    
    def initialize(name, status, log)
      @name = name
      @status = status
      @log = log
    end
    
    def serialize
      {
        name: @name,
        status: @status,
        log: @log.serialize
      }
    end

  end
end
