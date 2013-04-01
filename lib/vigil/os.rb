require 'fileutils'
class Vigil
  class OS
  
    def system(cmd)
      Vigil.logger.info "$ #{cmd}"
      stat = super cmd
      unless stat
        block_given? ? yield($?) : raise("Failed")
      end
      stat
    end
    
    def backticks(cmd)
      Vigil.logger.info "$ #{cmd}"
      output = `#{cmd}`
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
    
    def ln *args
      FileUtils.ln *args
    end

    def entries *args
      Dir.entries *args
    end

    def rename *args
      File.rename *args
    end
    
  end
end
