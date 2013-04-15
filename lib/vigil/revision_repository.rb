class Vigil
  class RevisionRepository
    
    def initialize(project)
      @os = Vigil.os
      @project = project
    end

    def new
      Revision.new(most_recent_revision.id+1, @project)
    end

    def all
      _entries.map {|id| Revision.new(id, @project)}
    end
    
    def empty?
      _entries.empty?
    end

    def most_recent_revision
      id = _entries.sort.last
      id ||= 0
      Revision.new(id, @project)
    end

    def _entries
      @os.entries(@project.working_dir).select { |f| f =~ /^\d+$/ }.map {|f| f.to_i}
    end
  end
end
