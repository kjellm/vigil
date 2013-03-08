class Vigil
  class TestPipeline

    def initialize(revision, args={})
      @revision = revision
      @plugman = Vigil.plugman
    end
    
    def run
      @plugman.notify(:build_started)
      @plugman.notify(:task_started, 'VM1')
      sleep 5
      @plugman.notify(:task_done, 'VM1')
      @plugman.notify(:task_started, 'VM2')
      sleep 5
      @plugman.notify(:task_done, 'VM2')
      @plugman.notify(:task_started, 'VM3')
      sleep 5
      @plugman.notify(:task_done, 'VM3')
      @plugman.notify(:task_started, 'UNIT')
      sleep 5
      @plugman.notify(:task_done, 'UNIT')
    end
  end

end
