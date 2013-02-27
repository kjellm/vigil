require 'fileutils'

class Vigil

  
  def initialize(shell=nil)
    @x = shell || Class.new do
      def _system cmd
        puts "# #{cmd}"
        system cmd or raise "Failed"
      end
      
      def __system cmd
        puts "# #{cmd}"
        system cmd
        return $? == 0
      end
    end.new
  end


  def run revision_id

    project_dir = '/Users/kjellm/projects/amedia/znork/'
    project = File.basename(project_dir)
    
    run_dir = File.expand_path 'run'
    run_dir_project = File.join(run_dir, project)
    run_dir_revision = File.join(run_dir_project, revision_id)
    run_dir_boxes = File.join(run_dir_project, 'boxes')
    
    raise "Failed" unless File.directory?(project_dir)
    
    FileUtils.mkdir_p run_dir_revision
    FileUtils.mkdir_p run_dir_boxes
    Dir.chdir run_dir_revision
    
    #TODO use grit for git stuff
    
    @x._system "git clone #{project_dir} ."
    @x._system "git checkout vigil"  #FIXME
    
    @x._system "ln -s #{File.expand_path('../../iso')}"
    
    puts "### Step 1"
    previous_revision_box_name = File.join run_dir_boxes, "#{project}-#{revision_id.to_i - 1}.box"
    current_revision_box_name = File.join run_dir_boxes, "#{project}-#{revision_id}.box"
    if File.exists?(current_revision_box_name)
    elsif !File.exists?(previous_revision_box_name) or
        !@x.__system "git diff --quiet HEAD^ -- definitions" #FIXME
      @x._system "vagrant basebox build --force --nogui '#{project}'"
      @x._system "vagrant basebox validate '#{project}'"
      @x._system "vagrant basebox export '#{project}'"
      @x._system "mv #{project}.box #{run_dir_boxes}/#{project}-#{revision_id}.box"
      @x._system "vagrant basebox destroy #{project}" #FIXME put in ensure block
    else
      @x._system "ln #{previous_revision_box_name} #{run_dir_boxes}/#{project}-#{revision_id}.box"
    end
    
    puts "### Step 2"
    previous_revision_box_name = File.join run_dir_boxes, "#{project}-#{revision_id.to_i - 1}_no_gems.pkg"
    boxname = "#{project}-#{revision_id}"
    if !File.exists?(previous_revision_box_name) or
        !@x.__system "git diff --quiet HEAD^ -- manifests" #FIXME
      @x._system "vagrant box add --force '#{boxname}' '#{run_dir_boxes}/#{boxname}.box'"
      @x._system %Q{ruby -pi -e 'sub(/(config.vm.box = )"[^"]+"/, "\\\\1\\"#{project}-#{revision_id}\\"")' Vagrantfile}
      @x._system "vagrant up"
      @x._system "vagrant package --output #{run_dir_boxes}/#{boxname}_no_gems.pkg"
      @x._system "vagrant box remove #{boxname}"# remove #FIXME put in ensure block
    else
      @x._system "ln #{previous_revision_box_name} #{run_dir_boxes}/#{boxname}_no_gems.pkg"
    end
    
    puts "### Step 3"
    previous_revision_box_name = File.join run_dir_boxes, "#{project}-#{revision_id.to_i - 1}_complete.pkg"
    if !File.exists?(previous_revision_box_name) or
        !@x.__system "git diff --quiet HEAD^ -- Gemfile*" #FIXME
      @x._system "vagrant box add --force '#{project}-#{revision_id}_no_gems' '#{run_dir_boxes}/#{project}-#{revision_id}_no_gems.pkg'"
      @x._system %Q{ruby -pi -e 'sub(/(config.vm.box = )"[^"]+"/, "\\\\1\\"#{project}-#{revision_id}_no_gems\\"")' Vagrantfile}
      @x._system "vagrant up"
      @x._system "vagrant ssh -c 'sudo gem install bundler'"
      @x._system "vagrant ssh -c 'cd /vagrant/; bundle install'"
      @x._system "vagrant package --output #{run_dir_boxes}/#{project}-#{revision_id}_complete.pkg"
      @x._system "vagrant box remove '#{project}-#{revision_id}_no_gems'"# remove #FIXME put in ensure block
    else
      @x._system "ln #{previous_revision_box_name} #{run_dir_boxes}/#{project}-#{revision_id}_complete.pkg"
    end
    
    puts "### Step 4"
    @x._system "vagrant box add --force '#{project}-#{revision_id}_complete' '#{run_dir_boxes}/#{project}-#{revision_id}_complete.pkg'"
    @x._system %Q{ruby -pi -e 'sub(/(config.vm.box = )"[^"]+"/, "\\\\1\\"#{project}-#{revision_id}_complete\\"")' Vagrantfile}
    @x._system "vagrant up"
    
    puts "### Step 5"
    @x._system "vagrant ssh -c 'cd /vagrant; rake test'"
  end
end
