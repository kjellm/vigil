class Vigil
  class Vagrant

    def initialize(os)
      @os = os
    end

    def run(cmd)
      @os._system "vagrant #{cmd}"
    end

    def use(box)
      @os._system %Q{ruby -pi -e 'sub(/(config.vm.box = )"[^"]+"/, "\\\\1\\"#{box}\\"")' Vagrantfile}
    end

  end
end
