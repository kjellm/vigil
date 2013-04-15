require 'vigil/task'

class Vigil
  class VMBuilder

    def initialize(session)
      @x = Vigil.os
      @session = session
      @revision = @session.revision
      @previous_revision = @revision.previous
      @git = Git.new
      @vagrant = Vagrant.new

      @basebox_task = BaseboxTask.new(@session)
      @no_gems_box_task = NoGemsBoxTask.new(@session)
      @complete_box_task = CompleteBoxTask.new(@session)
    end

    def run
      _setup_iso_cache
      _build_vm
    end

    def _setup_iso_cache
      @x.mkdir_p File.join(Vigil.run_dir, 'iso')
      @x.system "ln -sf #{File.join(Vigil.run_dir, 'iso')}"
    end  

    def _build_vm
      tasks = _tasks
      log = []
      res = Class.new {def self.status; true; end}
      tasks.each {|t| log << res = t.call if res.status }
      log
    end

    def _tasks
      if @x.exists?(@revision.complete_box_path)
        [ _null_task('VM1'), _null_task('VM2'), _null_task('VM3') ]
      else
        _setup_basebox
      end
    end
    
    # Use NullTasks to notify plugins that a task is done without actually do anything.
    def _null_task(name)
      NullTask.new(@session, name: name)
    end

    def _setup_basebox
      name = 'VM1'
      if @x.exists? @revision.base_box_path
        [_null_task(name), *_setup_no_gems_box]
      elsif @x.exists?(@previous_revision.base_box_path) and !_changes_relative_to_previous_revision_in?('definitions')
        [ReuseBoxTask.new(@session, name: name, box: :base_box_path), *_setup_no_gems_box]
      else
        [@basebox_task, @no_gems_box_task, @complete_box_task]
      end
    end

    def _setup_no_gems_box
      name = 'VM2'
      if @x.exists?(@revision.no_gems_box_path)
        [_null_task(name), *_setup_complete_box]
      elsif !@x.exists?(@previous_revision.no_gems_box_path) or
          _changes_relative_to_previous_revision_in?('manifests')
        [@no_gems_box_task, @complete_box_task]
      else
        [ReuseBoxTask.new(@session, name: name, box: :no_gems_box_path), *_setup_complete_box]
      end
    end

    def _setup_complete_box
      name = 'VM3'
      if !@x.exists?(@previous_revision.complete_box_path) or
          _changes_relative_to_previous_revision_in?('Gemfile*')
        @complete_box_task
      else
        ReuseBoxTask.new(@session, name: name, box: :complete_box_path)
      end
    end

    def _changes_relative_to_previous_revision_in?(files)
      @git.differs?(@previous_revision.sha, files)
    end

    def task_done(task)
      @plugman.notify(:task_done, @revision.project_name, task)
    end

  end
end
