class Vigil
  module Vagrant

    def self.run(cmd)
      Vigil.os.system "vagrant #{cmd}"
    end

    def self.use(box)
      Vigil.os.system %Q{ruby -pi -e 'sub(/(config.vm.box = )"[^"]+"/, "\\\\1\\"#{box}\\"")' Vagrantfile}
    end

  end
end
