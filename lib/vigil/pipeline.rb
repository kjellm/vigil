class Vigil
  class Pipeline
    
    def initialize(revision, args={})
      @os = Vigil.os
      @revision = revision
      @vmbuilder = args[:vmbuilder] || VMBuilder.new(@revision)
      @plugman = Vigil.plugman
      @git = Git.new
      @vagrant = args[:vagrant] || Vagrant.new
    end
    
    def run
      notify(:build_started)
      @vmbuilder.run
      task('boot_vm') { _start_vm }
      task('tests') { _run_tests }
    end
  
    def _start_vm
      @os.system(@vagrant.add_box(@revision.complete_box_name, @revision.complete_box_path))
      @os.system(@vagrant.use(@revision.complete_box_name))
      @os.system(@vagrant.up)
    end
  
    def _run_tests
      @os.system(@vagrant.ssh('cd /vagrant; rake test'))
    end

    def task(desc, &block)
      task_started desc
      _redirected(desc, &block)
      task_done desc
    end

    
    def _redirected(desc)
      out = File.open(File.join(@revision.working_dir, ".vigil_task_#{desc}.log"), 'w')
      orig_stderr = $stderr.clone
      orig_stdout = $stdout.clone
      $stderr.reopen(out)
      $stdout.reopen(out)
      begin
        yield
      ensure
        $stderr.reopen(orig_stderr)
        $stdout.reopen(orig_stdout)
        out.close
      end
    end

    def task_started(task)
      notify(:task_started, task)
    end

    def task_done(task)
      notify(:task_done, task)
    end

    def notify(msg, *args)
      @plugman.notify(msg, @revision.project_name, *args)
    end

  end
end
