class Vigil
  class Pipeline

    def initialize(revision, args={})
      @os = Vigil.os
      @revision = revision
      @vmbuilder = args[:vmbuilder] || VMBuilder.new(@revision)
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
      Git.clone @revision.git_url, '.'
      Git.checkout @revision.branch
    end
  
    def _start_vm
      Vagrant.run "box add --force '#{@revision.complete_box_name}' '#{@revision.complete_box_path}'"
      Vagrant.use @revision.complete_box_name
      Vagrant.run "up"
    end
  
    def _run_tests
      Vagrant.run "ssh -c 'cd /vagrant; rake test'"
    end
  end

end
