require 'yaml'

class Vigil
  class Revision

    attr_reader :id
    
    def initialize(id, project)
      @id = id
      @project = project
      @run_dir_boxes = File.join(@project.working_dir, 'boxes')
      @os = Vigil.os
      @git_origin = File.join(@project.working_dir, 'repo.git')
      @git = Git.new(git_dir: File.join(working_dir, '.git'), work_tree: working_dir)
    end
  
    def run_pipeline(type='default')
      _git_clone
      @os.mkdir_p @run_dir_boxes
      pipeline = @project.type == 'gem' ? GemPipeline : Pipeline
      @os.chdir working_dir
      report = pipeline.new(self).run
      File.open( '.vigil.log', 'w' ) do |out|
        YAML.dump(report, out)
      end
    end

    def _git_clone
      Git.new.clone @git_origin, working_dir, '--shared'
      @git.checkout branch
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
      @os.backticks "bash -c 'GIT_DIR=#{File.join(working_dir, '.git')} git rev-parse HEAD'" #FIXME
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
  
    def differs?(git)
      git.differs2? branch, sha
    end
  
  end
end

