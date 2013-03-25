require 'fileutils'
class Vigil
  class OS
  
    def system(cmd)
      puts "# #{cmd}"
      stat = super cmd
      yield($?) if !stat and block_given?
      stat
    end
    
    def backticks(str)
      puts "# #{str}"
      output = `#{str}`
      raise "Failed: $?" if $?.exitstatus != 0
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
