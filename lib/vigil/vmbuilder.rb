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
          ['mv', "#{@revision.project_name}.box", @revision.base_box_path],
          vagrant.destroy_basebox(@revision.project_name),
        ]
      end

    end

    class NoGemsBoxTask < Task

      private

      def post_initialize(args)
        @revision = args.fetch(:revision)
      end

      def name; 'VM2'; end

      def commands
        vagrant = Vagrant.new
        [
         vagrant.add_box(@revision.base_box_name, @revision.base_box_path),
         vagrant.use(@revision.base_box_name),
         vagrant.up,
         vagrant.package(@revision.no_gems_box_path),
         vagrant.remove_box(@revision.base_box_name),
        ]
      end
      
    end

    class CompleteBoxTask < Task

      private

      def post_initialize(args)
        @revision = args.fetch(:revision)
      end

      def name; 'VM3'; end

      def commands
        vagrant = Vagrant.new
        [
         vagrant.add_box(@revision.no_gems_box_name, @revision.no_gems_box_path),
         vagrant.use(@revision.no_gems_box_name),
         vagrant.up,
         vagrant.ssh('sudo gem install bundler'),
         vagrant.ssh('cd /vagrant/; bundle install'),
         vagrant.package(@revision.complete_box_path),
         vagrant.remove_box(@revision.no_gems_box_name),
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
        NoGemsBoxTask.new(revision: @revision).call
        @rebuild = true
      else
        _use_old_box :no_gems_box_path
        task_done('VM2')
      end
    end

    def _setup_complete_box
      if @rebuild or !@x.exists?(@previous_revision.complete_box_path) or
          _changes_relative_to_previous_revision_in?('Gemfile*')
        CompleteBoxTask.new(revision: @revision).call
      else
        _use_old_box :complete_box_path
        task_done('VM3')
      end
    end

    def _build_complete_box
    end

    def _use_old_box(box)
      @x.ln @previous_revision.send(box), @revision.send(box)
    end

    def _changes_relative_to_previous_revision_in?(files)
      @git.differs?(@previous_revision.sha, files)
    end

    def task_done(task)
      notify(:task_done, task)
    end

    def notify(msg, *args)
      @plugman.notify(msg, @revision.project_name, *args)
    end

  end
end
