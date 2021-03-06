class Vigil
  class Git

    def initialize(args={})
      @git_cmd = "git"
      @git_cmd << " --bare" if args[:bare]
      @git_cmd << " --work-tree=" << args[:work_tree] if args[:work_tree]
      @git_cmd << " --git-dir=" << args[:git_dir] if args[:git_dir]

      @os = Vigil.os
    end

    def init
      cmd "init"
    end

    def clone(url, target, *args)
      cmd "clone #{args.join(' ')} #{url} #{target}"
    end

    def checkout(branch)
      cmd "checkout #{branch}"
    end

    def differs?(rev_spec, files)
      _differs?("#{rev_spec} -- #{files}")
    end

    def differs2?(rev_spec1, rev_spec2)
      _differs?("#{rev_spec1} #{rev_spec2}")
    end

    def _differs?(str)
      !@os.system("#@git_cmd diff --quiet #{str}") {|stat| raise "Failed: #{stat}" if stat.exitstatus > 1}
    end

    def fetch
      cmd "fetch --all"
    end

    def cmd(str)
      @os.system @git_cmd + " " + str
    end

  end
end
