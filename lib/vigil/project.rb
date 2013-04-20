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
      @branch = args[:branch] || _default_branch
      @type = args[:type] || 'default'
      @env = args.fetch(:env)

      @working_dir = File.join(@env.run_dir, @name)
      @revision_repository = args[:revision_repository] || RevisionRepository.new(@env, self)
      @git_repo = File.join(@working_dir, 'repo.git')
      @git = args[:git] || Git.new(bare: true, git_dir: @git_repo)
      @sys = @env.system
    end

    def _default_branch; 'master'; end

    def synchronize
      @sys.mkdir_p @working_dir
      if @sys.exists?(@git_repo)
        @git.fetch
      else
        @git.clone(@git_url, @git_repo, '--mirror')
      end
    end

    def new_revision?
      return true if @revision_repository.empty?
      most_recent_revision.differs? @git
    end

    def most_recent_revision
      @revision_repository.most_recent_revision
    end
    
    def revisions
      @revision_repository.all
    end
    
    def run_pipeline
      @sys.mkdir_p @working_dir
      revision = @revision_repository.new
      revision.run_pipeline
    end

    def readme
      md = Redcarpet::Markdown.new(Redcarpet::Render::HTML, fenced_code_blocks: true)
      md.render(File.read(File.join(most_recent_revision.working_dir, 'README.md')))
    end
  end
end
