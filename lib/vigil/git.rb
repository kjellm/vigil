class Vigil
  class Git

    def initialize(args)
      @git_cmd = "git"
      @git_cmd << " --bare" if args[:bare]
      @git_cmd << " --work-tree=" << args[:work_tree] if args[:work_tree]
      @git_cmd << " --git-dir=" << args[:git_dir] if args[:git_dir]
    end

    def clone(url, target, *args)
      cmd "clone #{args.join(' ')} #{url} #{target}"
    end

    def checkout(branch)
      cmd "checkout #{branch}"
    end

    def differs?(rev_spec, files)
      !cmd("diff --quiet #{rev_spec} -- #{files}")
    end

    def fetch
      cmd "fetch"
    end

    def cmd(str)
      Vigil.os._system @git_cmd + " " + str
    end

  end
end
