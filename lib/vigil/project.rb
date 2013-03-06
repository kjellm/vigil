class Vigil
  class Project
    attr_reader :name
    attr_reader :working_dir
    attr_reader :git_url
    attr_reader :branch

    def initialize(args)
      @name = args.fetch(:name)
      @working_dir = File.join(args.fetch(:run_dir), @name)
      @os = args.fetch(:os)
      @git_url = args.fetch(:git_url)
      @branch = args.fetch(:branch)
      @revision_repository = RevisionRepository.new(@os, self)
      @os.mkdir_p @working_dir
    end

    def run_pipeline
      revision = @revision_repository.new
      revision.run_pipeline
    end
  end
end
