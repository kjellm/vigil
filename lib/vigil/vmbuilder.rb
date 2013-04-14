require 'vigil/task'

class Vigil
  class VMBuilder

    def initialize(revision)
      @x = Vigil.os
      @plugman = Vigil.plugman
      @revision = revision
      @previous_revision = @revision.previous
      @git = Git.new
      @vagrant = Vagrant.new
      Session.instance.revision = @revision

      @basebox_task = BaseboxTask.new(revision: @revision)
      @no_gems_box_task = NoGemsBoxTask.new(revision: @revision)
      @complete_box_task = CompleteBoxTask.new(revision: @revision)
    end

    def run
      _setup_iso_cache
      if @x.exists?(@revision.complete_box_path)
        task_done 'VM1'
        task_done 'VM2'
        task_done 'VM3'
        return
      end
      _build_vm
    end

    def _setup_iso_cache
      @x.mkdir_p File.join(Vigil.run_dir, 'iso')
      @x.system "ln -sf #{File.join(Vigil.run_dir, 'iso')}"
    end  

    def _build_vm
      tasks = _setup_basebox
      log = []
      res = Class.new {def self.status; true; end}
      tasks.each {|t| log << res = t.call if res.status }
    end
    
    def _setup_basebox
      return [] if @x.exists? @revision.base_box_path
      if @x.exists?(@previous_revision.base_box_path) and !_changes_relative_to_previous_revision_in?('definitions')
        return [ReuseBoxTask.new(name: 'VM1', box: :base_box_path), *_setup_no_gems_box]
      else
        return [@basebox_task, @no_gems_box_task, @complete_box_task]
      end
    end

    def _setup_no_gems_box
      return [] if @x.exists?(@revision.no_gems_box_path)
      if !@x.exists?(@previous_revision.no_gems_box_path) or
          _changes_relative_to_previous_revision_in?('manifests')
        return [@no_gems_box_task, @complete_box_task]
      else
        return [ReuseBoxTask.new(name: 'VM2', box: :no_gems_box_path), *_setup_complete_box]
      end
    end

    def _setup_complete_box
      if !@x.exists?(@previous_revision.complete_box_path) or
          _changes_relative_to_previous_revision_in?('Gemfile*')
        return [@complete_box_task]
      else
        return [ReuseBoxTask.new(name: 'VM3', box: :complete_box_path)]
      end
    end

    def _use_old_box(box, name)
      @x.ln @previous_revision.send(box), @revision.send(box)
      task_done name
    end

    def _changes_relative_to_previous_revision_in?(files)
      @git.differs?(@previous_revision.sha, files)
    end

    def task_done(task)
      @plugman.notify(:task_done, @revision.project_name, task)
    end

  end
end
