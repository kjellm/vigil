require 'vigil/task'

class Vigil
  class StartVMTask < Task

    private

    def post_initialize(args)
      @vagrant = args.fetch(:vagrant)
    end

    def name; 'start_VM'; end

    def commands
      r = @session.revision
      [
        @vagrant.add_box(r.complete_box_name, r.complete_box_path),
        @vagrant.use(r.complete_box_name),
        @vagrant.up,
      ]
    end

  end
end
