class Vigil

  
  def initialize(shell=nil)
    @x = shell || Class.new do
      require 'fileutils'

      def _system cmd
        puts "# #{cmd}"
        system cmd or raise "Failed"
      end
      
      def __system cmd
        puts "# #{cmd}"
        system cmd
        return $? == 0
      end

      def mkdir_p *args
        FileUtils.mkdir_p *args
      end

      def chdir *args
        Dir.chdir *args
      end

      def exists? *args
        File.exists? *args
      end
        
      def ln *args
        FileUtils.ln *args
      end

    end.new
  end


  def run(project_dir, revision_id)
    VMBuilder.new(@x, project_dir, revision_id).run
  end

  class VMBuilder

    def initialize(shell, project_dir, revision_id)
      @x = shell
      @project_dir = project_dir
      @revision_id = revision_id

      @project = File.basename(@project_dir)
    
      @run_dir = File.expand_path 'run'
      @run_dir_project = File.join(@run_dir, @project)
      @run_dir_revision = File.join(@run_dir_project, @revision_id)
      @run_dir_boxes = File.join(@run_dir_project, 'boxes')

      @rebuild = false
    end

    def run
      _create_required_directories
      @x.chdir @run_dir_revision
      _git_clone
      _set_up_iso_cache
      unless @x.exists?(_current_revision_box_base_name + "_complete.pkg")
        _build_vm
      end
      _start_vm
      _run_tests
    end

    def _create_required_directories
      @x.mkdir_p @run_dir_revision
      @x.mkdir_p @run_dir_boxes
    end
    
    def _git_clone
      return if @x.exists? File.join(@run_dir_revision, '.git')
      @x._system "git clone #@project_dir ."
      @x._system "git checkout vigil"  #FIXME
    end

    def _set_up_iso_cache
      @x._system "ln -sf #{File.join(@run_dir, 'iso')}"
    end  

    def _build_vm
      _setup_basebox
      _setup_no_gems_box
      _build_complete_box
      @rebuild = false
    end

    def _previous_revision_box_base_name
      _box_base_name_for(@revision_id.to_i - 1)
    end

    def _current_revision_box_base_name
      _box_base_name_for @revision_id
    end

    def _box_base_name_for(revision)
      File.join @run_dir_boxes, "#@project-#{revision}"
    end


    def _setup_basebox
      current_box = _current_revision_box_base_name + ".box"
      previous_box = _previous_revision_box_base_name + ".box"
      return if @x.exists? current_box
      if @x.exists?(previous_box) and _no_changes_relative_to_previous_revision_in?('definitions')
        @x.ln previous_box, current_box
      else
        _build_basebox(current_box)
        @rebuild = true
      end
    end

    def _build_basebox(current_box)
      _vagrant "basebox build --force --nogui '#{@project}'"
      _vagrant "basebox validate '#{@project}'"
      _vagrant "basebox export '#{@project}'"
      @x._system "mv #{@project}.box #{current_box}"
      _vagrant "basebox destroy #{@project}"
    end

    def _setup_no_gems_box
      current_box = _current_revision_box_base_name + "_no_gems.pkg"
      previous_box = _previous_revision_box_base_name + "_no_gems.pkg"
      return if @x.exists?(current_box)
      if @rebuild or !@x.exists?(previous_box) or
          !_no_changes_relative_to_previous_revision_in?('manifests')
        _build_no_gems_box(current_box)
        @rebuild = true
      else
        @x.ln previous_box, current_box
      end
    end

    def _build_no_gems_box(current_box)
      boxname = "#{@project}-#{@revision_id}"
      _vagrant "box add --force '#{boxname}' '#{@run_dir_boxes}/#{boxname}.box'"
      _vagrant_use "#{@project}-#{@revision_id}"
      _vagrant "up"
      _vagrant "package --output #{current_box}"
      _vagrant "box remove #{boxname}"
    end

    def _build_complete_box
      previous_box = _previous_revision_box_base_name + "_complete.pkg"
      if @rebuild or !@x.exists?(previous_box) or
          !_no_changes_relative_to_previous_revision_in?('Gemfile*')
        _vagrant "box add --force '#{@project}-#{@revision_id}_no_gems' '#{@run_dir_boxes}/#{@project}-#{@revision_id}_no_gems.pkg'"
        _vagrant_use "#{@project}-#{@revision_id}_no_gems"
        _vagrant "up"
        _vagrant "ssh -c 'sudo gem install bundler'"
        _vagrant "ssh -c 'cd /vagrant/; bundle install'"
        _vagrant "package --output #{@run_dir_boxes}/#{@project}-#{@revision_id}_complete.pkg"
        _vagrant "box remove '#{@project}-#{@revision_id}_no_gems'"
      else
        @x.ln previous_box, "#{@run_dir_boxes}/#{@project}-#{@revision_id}_complete.pkg"
      end
    end

    def _start_vm
      _vagrant "box add --force '#{@project}-#{@revision_id}_complete' '#{@run_dir_boxes}/#{@project}-#{@revision_id}_complete.pkg'"
      _vagrant_use "#{@project}-#{@revision_id}_complete"
      _vagrant "up"
    end

    def _run_tests
      _vagrant "ssh -c 'cd /vagrant; rake test'"
    end

    def _no_changes_relative_to_previous_revision_in?(files)
      @x.__system "git diff --quiet HEAD^ -- #{files}" #FIXME
    end

    def _vagrant(cmd)
      @x._system "vagrant #{cmd}"
    end

    def _vagrant_use(box)
      @x._system %Q{ruby -pi -e 'sub(/(config.vm.box = )"[^"]+"/, "\\\\1\\"#{box}\\"")' Vagrantfile}
    end

  end
end
