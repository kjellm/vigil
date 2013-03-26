class Vigil
  class GemPipeline
    include Task

    def initialize(revision, args={})
      @os = Vigil.os
      @revision = revision
      @plugman = Vigil.plugman
    end
    
    def run
      @os.chdir @revision.working_dir
      notify(:build_started)
      task('bundle') { _bundle_install }
      task('tests') { _run_tests }
    end
  
    def _bundle_install
      task_started 'bundle'
      @os.system "bundle install"
      task_done 'bundle'
    end
    
    def _run_tests
      @os.system "bundle exec rake"
    end

  end
end
