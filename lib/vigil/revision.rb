class Vigil
  class Revision

    def initialize(id, project, run_dir_boxes)
      @id = id
      @project = project
      @run_dir_boxes = run_dir_boxes
    end
  
    def base_box_name
      "#@project-#@id"
    end
  
    def base_box_path
      _box_path(base_box_name + '.box')
    end
  
    def no_gems_box_name
      base_box_name + '_no_gems'
    end
  
    def no_gems_box_path
      _box_path(no_gems_box_name + '.pkg')
    end
  
    def complete_box_name
      base_box_name + '_complete'
    end
  
    def complete_box_path
      _box_path(complete_box_name + '.pkg')
    end
  
    def _box_path(box)
      File.join(@run_dir_boxes, box)
    end
    
  end
end

