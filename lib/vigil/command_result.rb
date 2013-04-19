class Vigil
  class CommandResult
    
    attr_reader :status
    attr_reader :output
    attr_reader :process_status
    
    def initialize(command, status, output, process_status)
      @command = command
      @status = status
      @output = output
      @process_status = process_status
    end
    
    def serialize
      {
        command: @command,
        status: @status,
        output: @output,
      }
    end

  end
end  
