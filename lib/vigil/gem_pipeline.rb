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
      task('bundle') { @os.system "bundle install" }
      task('tests') { @os.system "bundle exec rake" }
    end
  
  end
end
