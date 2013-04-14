class Vigil
  class Vagrant

    def up
      run "up"
    end

    def build_basebox(name)
      basebox('build', '--force', '--nogui', name)
    end

    def validate_basebox(name)
      basebox('validate', name)
    end

    def export_basebox(name)
      basebox('export', name)
    end

    def destroy_basebox(name)
      basebox('destroy', name)
    end

    def basebox(*cmd)
      run('basebox', *cmd)
    end 

    def add_box(name, path)
      run('box', 'add', '--force', name, path)
    end

    def remove_box(name)
      run('box', 'remove', name)
    end

    def package(path)
      run('package', '--output', path)
    end

    def ssh(cmd)
      run('ssh', '-c', cmd)
    end

    def run(*cmd)
      ['vagrant', *cmd]
    end

    def use(box)
      ['ruby', '-pi', '-e', %Q{sub(/(config.vm.box = )"[^"]+"/, "\\\\1\\"#{box}\\"")}, 'Vagrantfile']
    end

  end
end
