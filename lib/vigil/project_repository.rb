class Vigil
  class ProjectRepository

    def initialize(env)
      @projects = {}
      env.config.opts['projects'].each do |k, v|
        @projects[k] = Project.new(
          name: k,
          git_url: v['url'],
          branch: v['branch'],
          type: v['type'],
          env: env
        )
      end
    end

    def find(name)
      @projects.fetch(name)
    end

    def each(&block)
      @projects.values.each(&block)
    end
    
  end
end
