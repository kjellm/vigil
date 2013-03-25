class Vigil
  class GemPipeline

    def initialize(revision, args={})
      @os = Vigil.os
      @revision = revision
      @plugman = Vigil.plugman
    end
    
    def run
      @os.chdir @revision.working_dir
      _notify(:build_started)
      _task_started 'bundle'
      _bundle_install
      _task_done 'bundle'
      _task_started 'tests'
      _run_tests
      _task_done 'tests'
    end
  
    def _bundle_install
      @os.system "bundle install"
    end
    
    def _run_tests
      @os.system "bundle exec rake"
    end

    def _task_started(task)
      _notify(:task_started, task)
    end

    def _task_done(task)
      _notify(:task_done, task)
    end

    def _notify(msg, *args)
      @plugman.notify(msg, @revision.project_name, *args)
    end

  end
end
