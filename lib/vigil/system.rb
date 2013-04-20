require 'pty'
require 'fileutils'

class Vigil
  class System
    
    def run_command(command)
      output = []
      child = nil
      p command
      ENV['COLUMNS'] = '80' # FIXME workaround bug in progressbar gem used by veewee
      Bundler.with_clean_env do
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
      end
      puts "#{child} #$?"
      return CommandResult.new(command, $?.exitstatus == 0, output.join(""), $?.clone)
    end

    def system(*cmd)
      Vigil.logger.info "$ #{cmd}"
      stat = super *cmd
      Vigil.logger.info "Exitstatus: #{stat} #{$?.inspect}"
      unless stat
        block_given? ? yield($?) : raise("Failed")
      end
      stat
    end
    
    def backticks(cmd)
      Vigil.logger.info "$ #{cmd}"
      output = `#{cmd}`
      Vigil.logger.info "Exitstatus: #{$?.inspect}"
      raise "Failed: #{$?.exitstatus}" if $?.exitstatus != 0
      output
    end

    def mkdir_p *args
      FileUtils.mkdir_p *args
    end
    
    def chdir *args
      Dir.chdir *args
    end
    
    def exists? *args
      File.exists? *args
    end
    
    def entries *args
      Dir.entries *args
    end

  end
end
