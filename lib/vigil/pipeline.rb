class Vigil
  class Pipeline

    def initialize(revision, args={})
      @os = Vigil.os
      @revision = revision
      @vagrant = Vagrant.new(@os)
      @vmbuilder = args[:vmbuilder] || VMBuilder.new(@vagrant, @revision)
      @plugman = Vigil.plugman
    end
    
    def run
      @os.chdir @revision.working_dir
      _git_clone
      @vmbuilder.run
      _start_vm
      _run_tests
      @plugman.notify(:task_done, 'tests')
    end
  
    def _git_clone
      return if @os.exists? File.join(@revision.working_dir, '.git')
      @os._system "git clone #{@revision.git_url} ."
      @os._system "git checkout #{@revision.branch}"
    end
  
    def _start_vm
      @vagrant.run "box add --force '#{@revision.complete_box_name}' '#{@revision.complete_box_path}'"
      @vagrant.use @revision.complete_box_name
      @vagrant.run "up"
    end
  
    def _run_tests
      @vagrant.run "ssh -c 'cd /vagrant; rake test'"
    end
  end

end
