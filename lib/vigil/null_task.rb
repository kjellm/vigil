require 'vigil/task'

class Vigil
  class NullTask < Task

    private

    def post_initialize(args)
      @name = args.fetch(:name)
    end
     
    def name; @name; end
   
    def commands
      [ ]
    end
    
  end
end
