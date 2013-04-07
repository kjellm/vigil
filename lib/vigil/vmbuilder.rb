class Vigil
  class VMBuilder
    include Task

    def initialize(revision)
      @x = Vigil.os
      @plugman = Vigil.plugman
      @revision = revision
      @previous_revision = @revision.previous
      @rebuild = false
      @git = Git.new
      @vagrant = Vagrant.new
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
      task('VM1') { _setup_basebox }
      task('VM2') { _setup_no_gems_box }
      task('VM3') { _setup_complete_box }
      @rebuild = false
    end
    
    def _setup_basebox
      return if @x.exists? @revision.base_box_path
      if @x.exists?(@previous_revision.base_box_path) and !_changes_relative_to_previous_revision_in?('definitions')
        _use_old_box(:base_box_path)
      else
        _build_basebox
        @rebuild = true
      end
    end

    def _build_basebox
      _setup_iso_cache
      @vagrant.build_basebox(@revision.project_name)
      @vagrant.validate_basebox(@revision.project_name)
      @vagrant.export_basebox(@revision.project_name)
      @x.rename "#{@revision.project_name}.box",  @revision.base_box_path
      @vagrant.destroy_basebox(@revision.project_name)
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
      @vagrant.add_box(@revision.base_box_name, @revision.base_box_path)
      @vagrant.use @revision.base_box_name
      @vagrant.up
      @vagrant.package(@revision.no_gems_box_path)
      @vagrant.remove_box(@revision.base_box_name)
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
      @vagrant.add_box(@revision.no_gems_box_name, @revision.no_gems_box_path)
      @vagrant.use(@revision.no_gems_box_name)
      @vagrant.up
      @vagrant.ssh('sudo gem install bundler')
      @vagrant.ssh('cd /vagrant/; bundle install')
      @vagrant.package(@revision.complete_box_path)
      @vagrant.remove_box(@revision.no_gems_box_name)
    end

    def _use_old_box(box)
      @x.ln @previous_revision.send(box), @revision.send(box)
    end

    def _changes_relative_to_previous_revision_in?(files)
      @git.differs?(@previous_revision.sha, files)
    end

  end
end
