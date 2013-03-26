class Vigil
  class Pipeline
    include Task

    def initialize(revision, args={})
      @os = Vigil.os
      @revision = revision
      @vmbuilder = args[:vmbuilder] || VMBuilder.new(@revision)
      @plugman = Vigil.plugman
      @git = Git.new
    end
    
    def run
      @os.chdir @revision.working_dir
      notify(:build_started)
      @vmbuilder.run
      task('boot_vm') { _start_vm }
      task('tests') { _run_tests }
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
