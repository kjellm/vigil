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
        FileUtils.mkdir_p args
      end

      def chdir *args
        Dir.chdir args
      end

      def exists? *args
        File.exists? args
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
      _git_clone
      _set_up_iso_cache
      unless @x.exists?(File.join(@run_dir_boxes, "#@project-#{@revision_id}_complete.pkg"))
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
      @x.chdir @run_dir_revision
      
      #TODO use grit for git stuff
      
      @x._system "git clone #@project_dir ."
      @x._system "git checkout vigil"  #FIXME
    end

    def _set_up_iso_cache
      @x._system "ln -s #{File.expand_path(File.join(@run_dir, 'iso'))}"
    end  

    def _build_vm
      _build_basebox
      _build_no_gems_box
      _build_complete_box
    end

    def _build_basebox
      previous_revision_box_name = File.join @run_dir_boxes, "#@project-#{@revision_id.to_i - 1}.box"
      current_revision_box_name = File.join @run_dir_boxes, "#@project-#@revision_id.box"
      if @x.exists?(current_revision_box_name)
        # noop
      elsif @x.exists?(previous_revision_box_name) and _no_changes_relative_to_previous_revision_in?('definitions')
        @x.ln previous_revision_box_name, current_revision_box_name
      else
        _vagrant "basebox build --force --nogui '#{@project}'"
        _vagrant "basebox validate '#{@project}'"
        _vagrant "basebox export '#{@project}'"
        @x._system "mv #{@project}.box #{@run_dir_boxes}/#{@project}-#{@revision_id}.box"
        _vagrant "basebox destroy #{@project}"
        @rebuild = true
      end
    end

    def _build_no_gems_box
      previous_revision_box_name = File.join @run_dir_boxes, "#{@project}-#{@revision_id.to_i - 1}_no_gems.pkg"
      current_revision_box_name = File.join @run_dir_boxes, "#{@project}-#{@revision_id}_no_gems.pkg"
      boxname = "#{@project}-#{@revision_id}"
      if @x.exists?(current_revision_box_name)
        # noop
      elsif @rebuild or !@x.exists?(previous_revision_box_name) or
          !_no_changes_relative_to_previous_revision_in?('manifests')
        _vagrant "box add --force '#{boxname}' '#{@run_dir_boxes}/#{boxname}.box'"
        _vagrant_use "#{@project}-#{@revision_id}"
        _vagrant "up"
        _vagrant "package --output #{@run_dir_boxes}/#{boxname}_no_gems.pkg"
        _vagrant "box remove #{boxname}"
        @rebuild = true
      else
        @x.ln previous_revision_box_name, "#{@run_dir_boxes}/#{boxname}_no_gems.pkg"
      end
    end

    def _build_complete_box
      previous_revision_box_name = File.join @run_dir_boxes, "#{@project}-#{@revision_id.to_i - 1}_complete.pkg"
      if @rebuild or !@x.exists?(previous_revision_box_name) or
          !_no_changes_relative_to_previous_revision_in?('Gemfile*')
        _vagrant "box add --force '#{@project}-#{@revision_id}_no_gems' '#{@run_dir_boxes}/#{@project}-#{@revision_id}_no_gems.pkg'"
        _vagrant_use "#{@project}-#{@revision_id}_no_gems"
        _vagrant "up"
        _vagrant "ssh -c 'sudo gem install bundler'"
        _vagrant "ssh -c 'cd /vagrant/; bundle install'"
        _vagrant "package --output #{@run_dir_boxes}/#{@project}-#{@revision_id}_complete.pkg"
        _vagrant "box remove '#{@project}-#{@revision_id}_no_gems'"
      else
        @x.ln previous_revision_box_name, "#{@run_dir_boxes}/#{@project}-#{@revision_id}_complete.pkg"
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
