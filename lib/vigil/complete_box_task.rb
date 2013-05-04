require 'vigil/task'

class Vigil
  class CompleteBoxTask < Task

    private

    def name; 'VM3'; end

    def commands
      vagrant = Vagrant.new
      revision = @session.revision
      [
       vagrant.add_box(revision.no_gems_box_name, revision.no_gems_box_path),
       vagrant.use(revision.no_gems_box_name),
       vagrant.up,
       vagrant.ssh('sudo gem install bundler'),
       vagrant.ssh('cd /vagrant/; bundle install --without development'),
       vagrant.package(revision.complete_box_path),
       vagrant.remove_box(revision.no_gems_box_name),
      ]
    end
    
  end
end
