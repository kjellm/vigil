require 'vigil/task'

class Vigil
  class BaseboxTask < Task
      
    private

    def name; 'VM1'; end

    def commands
      vagrant = Vagrant.new
      revision = @session.revision
      [
       vagrant.build_basebox(revision.project_name),
       vagrant.validate_basebox(revision.project_name),
       vagrant.export_basebox(revision.project_name),
       ['mv', "#{revision.project_name}.box", revision.base_box_path],
       vagrant.destroy_basebox(revision.project_name),
      ]
    end
    
  end
end
