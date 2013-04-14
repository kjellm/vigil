require 'vigil/task'

class Vigil
  class NoGemsBoxTask < Task

    private

    def name; 'VM2'; end

    def commands
      vagrant = Vagrant.new
      revision = @session.revision
      [
       vagrant.add_box(revision.base_box_name, revision.base_box_path),
       vagrant.use(revision.base_box_name),
       vagrant.up,
       vagrant.package(revision.no_gems_box_path),
       vagrant.remove_box(revision.base_box_name),
      ]
    end
      
  end
end
