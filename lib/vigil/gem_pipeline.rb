class Vigil
  class GemPipeline

    def initialize(revision, args={})
      @os = Vigil.os
      @revision = revision
      @plugman = Vigil.plugman
    end
    
    def run
      @os.chdir @revision.working_dir
      _git_clone
      _bundle_install
      _run_tests
      @plugman.notify(:task_done, 'tests')
    end
  
    def _git_clone
      return if @os.exists? File.join(@revision.working_dir, '.git')
      Git.clone @revision.git_url, '.'
      Git.checkout @revision.branch
    end
  
    def _bundle_install
      @os._system "bundle install"
    end
    
    def _run_tests
      @os._system "bundle exec rake"
    end
  end
end
