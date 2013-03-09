class Vigil
  module Vagrant

    def self.run(cmd)
      Vigil.os._system "vagrant #{cmd}"
    end

    def self.use(box)
      Vigil.os._system %Q{ruby -pi -e 'sub(/(config.vm.box = )"[^"]+"/, "\\\\1\\"#{box}\\"")' Vagrantfile}
    end

  end
end
