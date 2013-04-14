class Vigil
  class Report
    
    def initialize(status, log)
      @status = status
      @log = log
    end
    
    def to_s
      "Status: #{@status ? 'success' : 'failed'}\n" << @log.map {|l| "$ #{l.command.join(' ')}\n\t" << l.result.output.split("\n").join("\n\t") }.join("\n")
    end
    
  end
end
