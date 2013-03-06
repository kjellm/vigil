require 'fileutils'
class Vigil
  class OS
  
    def _system cmd
      puts "# #{cmd}"
      system cmd or raise "Failed"
    end
    
    def __system cmd
      puts "# #{cmd}"
      system cmd
      return $? == 0
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
    
  end
end
