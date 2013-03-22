class Vigil
  class Revision

    attr_reader :id

    def initialize(id, project)
      @id = id
      @project = project
      @run_dir_boxes = File.join(@project.working_dir, 'boxes')
      @os = Vigil.os
    end
  
    def run_pipeline
      @os.mkdir_p File.join(working_dir, '.vigil')
      @os.mkdir_p @run_dir_boxes
      Pipeline.new(self).run
    end
    
    def previous
      Revision.new(@id-1, @project)
    end

    def working_dir
      File.join(@project.working_dir, @id.to_s)
    end
    
    def git_url
      @project.git_url
    end

    def sha
      `bash -c 'GIT_DIR=#{File.join(working_dir, '.git')} git rev-parse HEAD'` #FIXME
    end

    def differs?(revision, files)
      @project.differs?(self, revision, files)
    end


    def branch
      @project.branch
    end

    def project_name
      @project.name
    end

    def base_box_name
      "#{@project.name}-#@id"
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

