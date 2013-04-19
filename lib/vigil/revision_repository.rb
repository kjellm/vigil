class Vigil
  class RevisionRepository
    
    def initialize(env, project)
      @os = Vigil.os
      @project = project
      @env = env
    end

    def new
      Revision.new(@env, most_recent_revision.id+1, @project)
    end

    def all
      _entries.map {|id| Revision.new(@env, id, @project)}
    end
    
    def empty?
      _entries.empty?
    end

    def most_recent_revision
      id = _entries.sort.last
      id ||= 0
      Revision.new(@env, id, @project)
    end

    def _entries
      @os.entries(@project.working_dir).select { |f| f =~ /^\d+$/ }.map {|f| f.to_i}
    end
  end
end
