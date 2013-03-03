require 'vigil/os'
require 'vigil/pipeline'
require 'vigil/revision'
require 'vigil/vagrant'
require 'vigil/vmbuilder'

class Vigil
  
  def initialize(args)
    @x = args[:os] || Vagrant::OS.new
  end
  
  def run(project_dir, revision_id)
    Pipeline.new(@x, project_dir, revision_id).run
  end

end
