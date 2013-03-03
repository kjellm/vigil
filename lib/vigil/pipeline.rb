class Vigil
  class Pipeline

    def initialize(os, project_dir, revision_id)
      @os = os
      @project_dir = project_dir
      @project = File.basename(project_dir)
      @run_dir = File.expand_path 'run'
      @run_dir_project = File.join(@run_dir, @project)
      @run_dir_boxes = File.join(@run_dir_project, 'boxes')
      @run_dir_revision = File.join(@run_dir_project, revision_id)
      @revision = Revision.new(revision_id, @project, @run_dir_boxes)
      @vagrant = Vagrant.new(@os)
    end
    
    def run
      _create_required_directories
      @os.chdir @run_dir_revision
      _git_clone
      VMBuilder.new(@os, @vagrant, @project_dir, @revision).run
      _start_vm
      _run_tests
    end
  
    def _create_required_directories
      @os.mkdir_p @run_dir_revision
      @os.mkdir_p @run_dir_boxes
    end
      
    def _git_clone
      return if @os.exists? File.join(@run_dir_revision, '.git')
      @os._system "git clone #@project_dir ."
      @os._system "git checkout vigil"  #FIXME
    end
  
    def _start_vm
      @vagrant.run "box add --force '#{@revision.complete_box_name}' '#{@revision.complete_box_path}'"
      @vagrant.use @revision.complete_box_name
      @vagrant.run "up"
    end
  
    def _run_tests
      @vagrant.run "ssh -c 'cd /vagrant; rake test'"
    end
  end

end
