require 'yaml'

class Vigil
  class Revision

    attr_reader :id
    
    def initialize(env, id, project)
      @env = env
      @id = id
      @project = project

      @boxes_dir = File.join(@project.working_dir, 'boxes')
      @git_origin = File.join(@project.working_dir, 'repo.git')
      @git = Git.new(git_dir: File.join(working_dir, '.git'), work_tree: working_dir)
      @sys = @env.system
    end
  
    def run_pipeline
      _git_clone
      @sys.mkdir_p @boxes_dir
      pipeline = @project.type == 'gem' ? GemPipeline : VMPipeline
      @sys.chdir working_dir
      session = Session.new(env: @env, revision: self)
      report = pipeline.new(session).run
      File.open( '.vigil.yml', 'w' ) do |out|
        YAML.dump(report.serialize, out)
      end
      report
    end

    def _git_clone
      Git.new.clone @git_origin, working_dir, '--shared'
      @git.checkout branch
    end
  
    def previous
      Revision.new(@env, @id-1, @project)
    end

    def working_dir
      File.join(@project.working_dir, @id.to_s)
    end
    
    def git_url
      @project.git_url
    end

    def sha
      @sys.backticks("bash -c 'GIT_DIR=#{File.join(working_dir, '.git')} git rev-parse HEAD'").chop #FIXME
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
      File.join(@boxes_dir, box)
    end
  
    def differs?(git)
      git.differs2? branch, sha
    end
  
    def report
      YAML.load_file(File.join(working_dir, '.vigil.yml'))
    end

  end
end

