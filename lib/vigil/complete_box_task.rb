require 'vigil/task'

class Vigil
  class CompleteBoxTask < Task

    private

    def post_initialize(args)
      @revision = args.fetch(:revision)
    end

    def name; 'VM3'; end

    def commands
      vagrant = Vagrant.new
      [
       vagrant.add_box(@revision.no_gems_box_name, @revision.no_gems_box_path),
       vagrant.use(@revision.no_gems_box_name),
       vagrant.up,
       vagrant.ssh('sudo gem install bundler'),
       vagrant.ssh('cd /vagrant/; bundle install'),
       vagrant.package(@revision.complete_box_path),
       vagrant.remove_box(@revision.no_gems_box_name),
      ]
    end
    
  end
end
