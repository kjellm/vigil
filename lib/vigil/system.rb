require 'pty'

class Vigil
  class System
    
    def run_command(command)
      output = []
      child = nil
      p command
      ENV['COLUMNS'] = '80' # FIXME workaround bug in progressbar gem used by veewee
      PTY.spawn(*command) do |r, w, pid|
        child = pid
        begin
          # Do stuff with the output here. Just printing to show it works
          r.each do |line|
            break if line.nil? # Happens on BSD
            print line
            output << line
          end
        rescue Errno::EIO
          # Happens on Linux
        ensure
          Process::wait(pid)
        end
      end
      puts "#{child} #$?"
      return CommandResult.new($?.exitstatus == 0, output.join(""), $?.clone)
    end

    def run_command2(command)
      output = ''
      IO.popen([*command, :err=>[:child, :out]]) do |io|
        output = io.read
      end
      return CommandResult.new($?.exitstatus == 0, output, $?.clone)
    end
    
  end
end
