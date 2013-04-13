require 'vigil/task'

class Vigil
  class VMBuilder

    class BaseboxTask < Task
      
      private

      def post_initialize(args)
        @revision = args.fetch(:revision)
      end

      def name; 'VM1'; end

      def commands
        vagrant = Vagrant.new
        [
          vagrant.build_basebox(@revision.project_name),
          vagrant.validate_basebox(@revision.project_name),
          vagrant.export_basebox(@revision.project_name),
          "mv #{@revision.project_name}.box #{@revision.base_box_path}",
          vagrant.destroy_basebox(@revision.project_name),
        ]
      end

    end

    def initialize(revision)
      @x = Vigil.os
      @plugman = Vigil.plugman
      @revision = revision
      @previous_revision = @revision.previous
      @rebuild = false
      @git = Git.new
      @vagrant = Vagrant.new
      Session.instance.revision = @revision
    end

    def run
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
      task('VM2') { _setup_no_gems_box }
      task('VM3') { _setup_complete_box }
      @rebuild = false
    end
    
    def _setup_basebox
      return if @x.exists? @revision.base_box_path
      if @x.exists?(@previous_revision.base_box_path) and !_changes_relative_to_previous_revision_in?('definitions')
        _use_old_box(:base_box_path)
        task_done('VM1')
      else
        _setup_iso_cache
        BaseboxTask.new(revision: @revision).call
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
        _build_no_gems_box
        @rebuild = true
      else
        _use_old_box :no_gems_box_path
      end
    end

    def _build_no_gems_box
      @x.system @vagrant.add_box(@revision.base_box_name, @revision.base_box_path)
      @x.system @vagrant.use @revision.base_box_name
      @x.system @vagrant.up
      @x.system @vagrant.package(@revision.no_gems_box_path)
      @x.system @vagrant.remove_box(@revision.base_box_name)
    end

    def _setup_complete_box
      if @rebuild or !@x.exists?(@previous_revision.complete_box_path) or
          _changes_relative_to_previous_revision_in?('Gemfile*')
        _build_complete_box
      else
        _use_old_box :complete_box_path
      end
    end

    def _build_complete_box
      @x.system @vagrant.add_box(@revision.no_gems_box_name, @revision.no_gems_box_path)
      @x.system @vagrant.use(@revision.no_gems_box_name)
      @x.system @vagrant.up
      @x.system @vagrant.ssh('sudo gem install bundler')
      @x.system @vagrant.ssh('cd /vagrant/; bundle install')
      @x.system @vagrant.package(@revision.complete_box_path)
      @x.system @vagrant.remove_box(@revision.no_gems_box_name)
    end

    def _use_old_box(box)
      @x.ln @previous_revision.send(box), @revision.send(box)
    end

    def _changes_relative_to_previous_revision_in?(files)
      @git.differs?(@previous_revision.sha, files)
    end

    def task(desc, &block)
      task_started desc
      _redirected(desc, &block)
      task_done desc
    end

    
    def _redirected(desc)
      out = File.open(File.join(@revision.working_dir, ".vigil_task_#{desc}.log"), 'w')
      orig_stderr = $stderr.clone
      orig_stdout = $stdout.clone
      $stderr.reopen(out)
      $stdout.reopen(out)
      begin
        yield
      ensure
        $stderr.reopen(orig_stderr)
        $stdout.reopen(orig_stdout)
        out.close
      end
    end

    def task_started(task)
      notify(:task_started, task)
    end

    def task_done(task)
      notify(:task_done, task)
    end

    def notify(msg, *args)
      @plugman.notify(msg, @revision.project_name, *args)
    end

  end
end
