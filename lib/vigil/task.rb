class Vigil
  module Task

    def task(desc, &block)
      task_started desc
      _redirected(&block)
      task_done desc
    end

    
    def _redirected
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
