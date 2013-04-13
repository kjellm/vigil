require 'vigil/task'

class Vigil
  class VMBuilder

    def initialize(revision)
      @x = Vigil.os
      @plugman = Vigil.plugman
      @revision = revision
      @previous_revision = @revision.previous
      @rebuild = false
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

    def _build_vm
      _setup_basebox
      _setup_no_gems_box
      _setup_complete_box
      @rebuild = false
    end
    
    def _setup_basebox
      return if @x.exists? @revision.base_box_path
      if @x.exists?(@previous_revision.base_box_path) and !_changes_relative_to_previous_revision_in?('definitions')
        _use_old_box(:base_box_path)
        task_done('VM1')
      else
        @basebox_task.call
        @rebuild = true
      end
    end

    def _setup_iso_cache
      @x.system "ln -sf #{File.join(Vigil.run_dir, 'iso')}"
    end  

    def _setup_no_gems_box
      return if @x.exists?(@revision.no_gems_box_path)
      if @rebuild or !@x.exists?(@previous_revision.no_gems_box_path) or
          _changes_relative_to_previous_revision_in?('manifests')
        @no_gems_box_task.call
        @rebuild = true
      else
        _use_old_box :no_gems_box_path
        task_done('VM2')
      end
    end

    def _setup_complete_box
      if @rebuild or !@x.exists?(@previous_revision.complete_box_path) or
          _changes_relative_to_previous_revision_in?('Gemfile*')
        @complete_box_task.call
      else
        _use_old_box :complete_box_path
        task_done('VM3')
      end
    end

    def _use_old_box(box)
      @x.ln @previous_revision.send(box), @revision.send(box)
    end

    def _changes_relative_to_previous_revision_in?(files)
      @git.differs?(@previous_revision.sha, files)
    end

    def task_done(task)
      @plugman.notify(:task_done, @revision.project_name, task)
    end

  end
end
