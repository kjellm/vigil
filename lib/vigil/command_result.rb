class Vigil
  class CommandResult
    
    attr_reader :status
    attr_reader :output
    attr_reader :process_status
    
    def initialize(status, output, process_status)
      @status = status
      @output = output
      @process_status = process_status
    end
    
  end
end  
