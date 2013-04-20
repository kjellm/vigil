class Vigil
  class Pipeline

    def initialize(session, args={})
      @session = session
      post_initialize(args)
    end

    def run
      notify(:build_started)
      log = Log.new
      res = Class.new {def self.status; true; end}
      tasks.each {|t| log << res = t.call if res.status }
      return Report.new(res.status, log)
    end
  
    private
    
    def post_initialize(args); end

    def tasks; raise "Abstract method called"; end

    def notify(msg, *args)
      @session.notify(msg, @session.revision.project_name, *args)
    end

  end
end
