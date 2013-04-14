require 'vigil/task'

class Vigil
  class ReuseBoxTask < Task

    private

    def post_initialize(args)
      @name = args.fetch(:name)
      @box  = args.fetch(:box)
    end
     
    def name; @name; end
   
    def commands
      [ ['ln', @session.revision.previous.send(@box), @session.revision.send(@box) ] ]
    end
    
  end
end
