class Vigil
  class VMBuilder

    def initialize(vagrant, revision)
      @x = Vigil.os
      @vagrant = vagrant
      @revision = revision
      @previous_revision = @revision.previous
      @rebuild = false
    end

    def run
      return if @x.exists?(@revision.complete_box_path)
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
      else
        _build_basebox
        @rebuild = true
      end
    end

    def _build_basebox
      _setup_iso_cache
      @vagrant.run "basebox build --force --nogui '#{@revision.project_name}'"
      @vagrant.run "basebox validate '#{@revision.project_name}'"
      @vagrant.run "basebox export '#{@revision.project_name}'"
      @x._system "mv #{@revision.project_name}.box #{@revision.base_box_path}"
      @vagrant.run "basebox destroy #{@revision.project_name}"
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
      @vagrant.run "box add --force '#{@revision.base_box_name}' '#{@revision.base_box_path}'"
      @vagrant.use @revision.base_box_name
      @vagrant.run "up"
      @vagrant.run "package --output #{@revision.no_gems_box_path}"
      @vagrant.run "box remove #{@revision.base_box_name}"
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
      @vagrant.run "box add --force '#{@revision.no_gems_box_name}' '#{@revision.no_gems_box_path}'"
      @vagrant.use @revision.no_gems_box_name
      @vagrant.run "up"
      @vagrant.run "ssh -c 'sudo gem install bundler'"
      @vagrant.run "ssh -c 'cd /vagrant/; bundle install'"
      @vagrant.run "package --output #{@revision.complete_box_path}"
      @vagrant.run "box remove '#{@revision.no_gems_box_name}'"
    end

    def _use_old_box(box)
      @x.ln @previous_revision.send(box), @revision.send(box)
    end

    def _changes_relative_to_previous_revision_in?(files)
      !@x.__system "git diff --quiet HEAD^ -- #{files}" #FIXME
    end

  end
end
