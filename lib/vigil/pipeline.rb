class Vigil
  class Pipeline
    
    def initialize(session, args={})
      @os = Vigil.os
      @session = session
      @vmbuilder = args[:vmbuilder] || VMBuilder.new(@session)
      @git = Git.new
      @vagrant = args[:vagrant] || Vagrant.new
    end
    
    def run
      notify(:build_started)
      @vmbuilder.run
      StartVMTask.new(@session, vagrant: @vagrant).call
      task('tests') { _run_tests }
    end
  
    def _start_vm
      @os.system(*@vagrant.add_box(@session.revision.complete_box_name, @session.revision.complete_box_path))
      @os.system(*@vagrant.use(@session.revision.complete_box_name))
      @os.system(*@vagrant.up)
    end
  
    def _run_tests
      @os.system(*@vagrant.ssh('cd /vagrant; rake'))
    end

    def task(desc)
      task_started desc
      yield
      task_done desc
    end

    
    def task_started(task)
      notify(:task_started, task)
    end

    def task_done(task)
      notify(:task_done, task)
    end

    def notify(msg, *args)
      @session.plugman.notify(msg, @session.revision.project_name, *args)
    end

  end
end
