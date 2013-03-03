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


  class Revision

    def initialize(id, project, run_dir_boxes)
      @id = id
      @project = project
      @run_dir_boxes = run_dir_boxes
    end

    def base_box_name
      "#@project-#@id"
    end

    def base_box_path
      _box_path(base_box_name + '.box')
    end

    def no_gems_box_name
      base_box_name + '_no_gems'
    end

    def no_gems_box_path
      _box_path(no_gems_box_name + '.pkg')
    end

    def complete_box_name
      base_box_name + '_complete'
    end

    def complete_box_path
      _box_path(complete_box_name + '.pkg')
    end

    def _box_path(box)
      File.join(@run_dir_boxes, box)
    end
    
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

      @previous_revision = Revision.new(@revision_id.to_i-1, @project, @run_dir_boxes)
      @revision = Revision.new(@revision_id, @project, @run_dir_boxes)

      @rebuild = false
    end

    def run
      _create_required_directories
      @x.chdir @run_dir_revision
      _git_clone
      _set_up_iso_cache
      unless @x.exists?(@revision.complete_box_path)
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
      _setup_complete_box
      @rebuild = false
    end

    def _setup_basebox
      return if @x.exists? @revision.base_box_path
      if @x.exists?(@previous_revision.base_box_path) and _no_changes_relative_to_previous_revision_in?('definitions')
        _use_old_box(:base_box_path)
      else
        _build_basebox
        @rebuild = true
      end
    end

    def _build_basebox
      _vagrant "basebox build --force --nogui '#{@project}'"
      _vagrant "basebox validate '#{@project}'"
      _vagrant "basebox export '#{@project}'"
      @x._system "mv #{@project}.box #{@revision.base_box_path}"
      _vagrant "basebox destroy #{@project}"
    end

    def _setup_no_gems_box
      return if @x.exists?(@revision.no_gems_box_path)
      if @rebuild or !@x.exists?(@previous_revision.no_gems_box_path) or
          !_no_changes_relative_to_previous_revision_in?('manifests')
        _build_no_gems_box
        @rebuild = true
      else
        _use_old_box :no_gems_box_path
      end
    end

    def _build_no_gems_box
      _vagrant "box add --force '#{@revision.base_box_name}' '#{@revision.base_box_path}'"
      _vagrant_use @revision.base_box_name
      _vagrant "up"
      _vagrant "package --output #{@revision.no_gems_box_path}"
      _vagrant "box remove #{@revision.base_box_name}"
    end

    def _setup_complete_box
      if @rebuild or !@x.exists?(@previous_revision.complete_box_path) or
          !_no_changes_relative_to_previous_revision_in?('Gemfile*')
        _build_complete_box
      else
        _use_old_box :complete_box_path
      end
    end

    def _build_complete_box
      _vagrant "box add --force '#{@revision.no_gems_box_name}' '#{@revision.no_gems_box_path}'"
      _vagrant_use @revision.no_gems_box_name
      _vagrant "up"
      _vagrant "ssh -c 'sudo gem install bundler'"
      _vagrant "ssh -c 'cd /vagrant/; bundle install'"
      _vagrant "package --output #{@revision.complete_box_path}"
      _vagrant "box remove '#{@revision.no_gems_box_name}'"
    end

    def _use_old_box(box)
      @x.ln @previous_revision.send(box), @revision.send(box)
    end

    def _start_vm
      _vagrant "box add --force '#{@revision.complete_box_name}' '#{@revision.complete_box_path}'"
      _vagrant_use @revision.complete_box_name
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
