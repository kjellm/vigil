class Vigil
  class ProjectRepository

    def initialize(config)
      @projects = {}
      
      config.opts['projects'].each do |k, v|
        @projects[k] = Project.new(
          name: k,
          git_url: v['url'],
          branch: v['branch'],
          type: v['type'],
        )
      end
    end

    def find(name); @projects[name]; end

    def to_a; @projects.values; end
    
  end
end
