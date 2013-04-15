class Vigil
  class Report

    attr_reader :status
    attr_reader :log
    
    def initialize(status, log)
      @status = status
      @log = log
    end
    
  end
end
