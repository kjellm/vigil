class Vigil
  class RevisionRepository
    
    def initialize(os, project)
      @os = os
      @project = project
    end

    def new
      Revision.new(most_recent_revision.id+1, @project)
    end

    def most_recent_revision
      id = @os.entries(@project.working_dir).select { |f| f =~ /^\d+$/ }.map {|f| f.to_i}.sort.last
      id ||= 0
      Revision.new(id, @project)
    end
  end
end
