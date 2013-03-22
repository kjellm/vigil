class Vigil
  class Project
    attr_reader :name
    attr_reader :working_dir
    attr_reader :git_url
    attr_reader :branch

    def initialize(args)
      @name = args.fetch(:name)
      @working_dir = File.join(Vigil.run_dir, @name)
      @os = Vigil.os
      @git_url = args.fetch(:git_url)
      @branch = args[:branch] || 'master'
      @revision_repository = (args[:revision_repo_factory] || RevisionRepository).new(self)
      @repo = repo = File.join(@working_dir, 'repo.git')
      @git = args[:git] || Git.new(bare: true, git_dir: @repo)
    end

    def run_pipeline
      _prepare
      return unless _has_changes?
      revision = @revision_repository.new
      revision.run_pipeline
    end

    def _prepare
      if _repo_exists?
        _update_repo
      else
        _import_repo
      end
    end

    def _has_changes?
      @git.sha != @revision_repository.most_recent_revision.sha
    end

    def _repo_exists?
      @os.exist? @repo
    end

    def _update_repo
      @git.fetch
    end

    def _import_repo
      @os.mkdir_p @working_dir
      @git.clone @git_url, 'repo.git', '--bare'
    end

    def differs?(rev1, rev2, files)
      @git.differs?('HEAD^', files) #FIXME
    end
  end
end
