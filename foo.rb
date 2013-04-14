require 'pty'

def run_command(command)
  PTY.spawn(*command) do |r, w, pid|
    child = pid
    begin
      r.each do |line|
        break if line.nil? # Happens on BSD
        print line
      end
    rescue Errno::EIO
      # Happens on Linux
    ensure
      Process::wait(pid)
    end
  end
end

run_command(%q{ruby -e 'require_relative "lib/progressbar"; ProgressBar.new("Foo", 100)'})
