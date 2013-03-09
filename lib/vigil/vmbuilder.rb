class Vigil
  class VMBuilder

    def initialize(revision)
      @x = Vigil.os
      @plugman = Vigil.plugman
      @revision = revision
      @previous_revision = @revision.previous
      @rebuild = false
    end

    def run
      if @x.exists?(@revision.complete_box_path)
        @plugman.notify(:task_done, 'VM1')
        @plugman.notify(:task_done, 'VM2')
        @plugman.notify(:task_done, 'VM3')
        return
      end
      _build_vm
    end

    def _build_vm
      _setup_basebox
      @plugman.notify(:task_done, 'VM1')
      _setup_no_gems_box
      @plugman.notify(:task_done, 'VM2')
      _setup_complete_box
      @plugman.notify(:task_done, 'VM3')
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
      Vagrant.run "basebox build --force --nogui '#{@revision.project_name}'"
      Vagrant.run "basebox validate '#{@revision.project_name}'"
      Vagrant.run "basebox export '#{@revision.project_name}'"
      @x._system "mv #{@revision.project_name}.box #{@revision.base_box_path}"
      Vagrant.run "basebox destroy #{@revision.project_name}"
    end

    def _setup_iso_cache
      @x._system "ln -sf #{File.join(Vigil.run_dir, 'iso')}"
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
      Vagrant.run "box add --force '#{@revision.base_box_name}' '#{@revision.base_box_path}'"
      Vagrant.use @revision.base_box_name
      Vagrant.run "up"
      Vagrant.run "package --output #{@revision.no_gems_box_path}"
      Vagrant.run "box remove #{@revision.base_box_name}"
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
      Vagrant.run "box add --force '#{@revision.no_gems_box_name}' '#{@revision.no_gems_box_path}'"
      Vagrant.use @revision.no_gems_box_name
      Vagrant.run "up"
      Vagrant.run "ssh -c 'sudo gem install bundler'"
      Vagrant.run "ssh -c 'cd /vagrant/; bundle install'"
      Vagrant.run "package --output #{@revision.complete_box_path}"
      Vagrant.run "box remove '#{@revision.no_gems_box_name}'"
    end

    def _use_old_box(box)
      @x.ln @previous_revision.send(box), @revision.send(box)
    end

    def _changes_relative_to_previous_revision_in?(files)
      Git.differs?('HEAD^', files) #FIXME
    end

  end
end
