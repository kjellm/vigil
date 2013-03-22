class Vigil
  class Project
    attr_reader :branch
    attr_reader :git_url
    attr_reader :name
    attr_reader :type
    attr_reader :working_dir

    def initialize(args)
      @name = args.fetch(:name)
      @working_dir = File.join(Vigil.run_dir, @name)
      @os = Vigil.os
      @git_url = args.fetch(:git_url)
      @branch = args.fetch(:branch)
      @revision_repository = RevisionRepository.new(self)
      @type = args[:type] || 'default'
    end

    def run_pipeline
      @os.mkdir_p @working_dir
      revision = @revision_repository.new
      revision.run_pipeline(@type)
    end
  end
end
