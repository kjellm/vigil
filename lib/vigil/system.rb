class Vigil
  class System
    
    def run_command(command)
      output = ''
      IO.popen([*command, :err=>[:child, :out]]) do |io|
        output = io.read
      end
      return CommandResult.new($?.exitstatus == 0, output, $?.clone)
    end
    
  end
end
