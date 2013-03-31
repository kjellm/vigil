require 'redcarpet'

class Vigil
  class Project
    attr_reader :branch
    attr_reader :git_url
    attr_reader :name
    attr_reader :type
    attr_reader :working_dir

    def initialize(args)
      @name = args.fetch(:name)
      @git_url = args.fetch(:git_url)
      @working_dir = File.join(Vigil.run_dir, @name)
      @os = args[:os] || Vigil.os
      @branch = args[:branch] || _default_branch
      @revision_repository = args[:revision_repository] || RevisionRepository.new(self)
      @type = args[:type] || 'default'
      @git_repo = File.join(@working_dir, 'repo.git')
      @git = args[:git] || Git.new(bare: true, git_dir: @git_repo)
    end

    def _default_branch; 'master'; end

    def synchronize
      @os.mkdir_p @working_dir
      if @os.exists?(@git_repo)
        @git.fetch
      else
        @git.clone(@git_url, @git_repo, '--mirror')
      end
    end

    def new_revision?
      return true if @revision_repository.empty?
      @revision_repository.most_recent_revision.differs? @git
    end

    def run_pipeline
      @os.mkdir_p @working_dir
      revision = @revision_repository.new
      revision.run_pipeline(@type)
    end

    def readme
      md = Redcarpet::Markdown.new(Redcarpet::Render::HTML, fenced_code_blocks: true)
      md.render(File.read(File.join(@revision_repository.most_recent_revision.working_dir, 'README.md')))
    end
  end
end
