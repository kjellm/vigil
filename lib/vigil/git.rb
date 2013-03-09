class Vigil
  module Git

    def self.clone(url, target)
      Vigil.os._system "git clone #{url} #{target}"
    end

    def self.checkout(branch)
      Vigil.os._system "git checkout #{branch}"
    end

    def self.differs?(rev_spec, files)
      !Vigil.os.__system "git diff --quiet #{rev_spec} -- #{files}"
    end

  end
end
