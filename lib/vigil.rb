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
      
      #TODO use grit for git stuff
      
      @x._system "git clone #@project_dir ."
      @x._system "git checkout vigil"  #FIXME
      
      @x._system "ln -s #{File.expand_path(File.join(@run_dir, 'iso'))}"
  
      unless @x.exists?(File.join @run_dir_boxes, "#@project-#{@revision_id}_complete.pkg")
        previous_revision_box_name = File.join @run_dir_boxes, "#@project-#{@revision_id.to_i - 1}.box"
        current_revision_box_name = File.join @run_dir_boxes, "#@project-#@revision_id.box"
        if @x.exists?(current_revision_box_name)
          # noop
        elsif @x.exists?(previous_revision_box_name) and
            @x.__system "git diff --quiet HEAD^ -- definitions" #FIXME
          @x._system "ln #{previous_revision_box_name} #{current_revision_box_name}"
        else
          _build_basebox
          @rebuild = true
        end
        
        previous_revision_box_name = File.join @run_dir_boxes, "#{@project}-#{@revision_id.to_i - 1}_no_gems.pkg"
        current_revision_box_name = File.join @run_dir_boxes, "#{@project}-#{@revision_id}_no_gems.pkg"
        boxname = "#{@project}-#{@revision_id}"
        if @x.exists?(current_revision_box_name)
        elsif @rebuild or !@x.exists?(previous_revision_box_name) or
            !@x.__system "git diff --quiet HEAD^ -- manifests" #FIXME
          @x._system "vagrant box add --force '#{boxname}' '#{@run_dir_boxes}/#{boxname}.box'"
          @x._system %Q{ruby -pi -e 'sub(/(config.vm.box = )"[^"]+"/, "\\\\1\\"#{@project}-#{@revision_id}\\"")' Vagrantfile}
          @x._system "vagrant up"
          @x._system "vagrant package --output #{@run_dir_boxes}/#{boxname}_no_gems.pkg"
          @x._system "vagrant box remove #{boxname}"# remove #FIXME put in ensure block
          @rebuild = true
        else
          @x._system "ln #{previous_revision_box_name} #{@run_dir_boxes}/#{boxname}_no_gems.pkg"
        end
        
        previous_revision_box_name = File.join @run_dir_boxes, "#{@project}-#{@revision_id.to_i - 1}_complete.pkg"
        if @rebuild or !@x.exists?(previous_revision_box_name) or
            !@x.__system "git diff --quiet HEAD^ -- Gemfile*" #FIXME
          @x._system "vagrant box add --force '#{@project}-#{@revision_id}_no_gems' '#{@run_dir_boxes}/#{@project}-#{@revision_id}_no_gems.pkg'"
          @x._system %Q{ruby -pi -e 'sub(/(config.vm.box = )"[^"]+"/, "\\\\1\\"#{@project}-#{@revision_id}_no_gems\\"")' Vagrantfile}
          @x._system "vagrant up"
          @x._system "vagrant ssh -c 'sudo gem install bundler'"
          @x._system "vagrant ssh -c 'cd /vagrant/; bundle install'"
          @x._system "vagrant package --output #{@run_dir_boxes}/#{@project}-#{@revision_id}_complete.pkg"
          @x._system "vagrant box remove '#{@project}-#{@revision_id}_no_gems'"# remove #FIXME put in ensure block
        else
          @x._system "ln #{previous_revision_box_name} #{@run_dir_boxes}/#{@project}-#{@revision_id}_complete.pkg"
        end
      end
    
      @x._system "vagrant box add --force '#{@project}-#{@revision_id}_complete' '#{@run_dir_boxes}/#{@project}-#{@revision_id}_complete.pkg'"
      @x._system %Q{ruby -pi -e 'sub(/(config.vm.box = )"[^"]+"/, "\\\\1\\"#{@project}-#{@revision_id}_complete\\"")' Vagrantfile}
      @x._system "vagrant up"
      
      @x._system "vagrant ssh -c 'cd /vagrant; rake test'"
    end

    def _create_required_directories
      @x.mkdir_p @run_dir_revision
      @x.mkdir_p @run_dir_boxes
    end

    def _build_basebox
      @x._system "vagrant basebox build --force --nogui '#{@project}'"
      @x._system "vagrant basebox validate '#{@project}'"
      @x._system "vagrant basebox export '#{@project}'"
      @x._system "mv #{@project}.box #{@run_dir_boxes}/#{@project}-#{@revision_id}.box"
      @x._system "vagrant basebox destroy #{@project}" #FIXME put in ensure block
    end
  end
end
