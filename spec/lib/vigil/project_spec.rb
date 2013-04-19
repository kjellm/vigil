require 'spec_helper'

class Vigil
  describe Project do

    before(:each) do
      Vigil.run_dir = '/run'
    end

    describe "#syncronize" do
      it "clones the repository on first run" do
        git = double('git')
        os = double('os', mkdir_p: true)
        os.should_receive('exists?').with('/run/foo/repo.git').and_return(false)
        git.should_receive('clone').with('/foo.git', '/run/foo/repo.git', '--mirror')
        Project.new(name: 'foo', git_url: '/foo.git', git: git, os: os, env: double('env')).synchronize
      end
      
      it "updates the repository if a repository already exists" do
        git = double('git')
        os = double('os', mkdir_p: true)
        os.should_receive('exists?').with('/run/foo/repo.git').and_return(true)
        git.should_receive('fetch')
        Project.new(name: 'foo', git_url: '/foo.git', git: git, os: os, env: double('env')).synchronize
      end
    end

    describe "#new_revision?" do
      it "returns true if no builds exists for this project" do
        rev_repo = double('rev_repo', empty?: true)
        project = Project.new(name: 'foo', git_url: '/foo.git', revision_repository: rev_repo, env: double('env'))
        project.new_revision?.should == true
      end

      it "returns true if repository has stuff that are newer than the newest build" do
        rev_repo = double('rev_repo', empty?: false)
        rev = double('rev')
        rev_repo.should_receive('most_recent_revision').and_return(rev)
        rev.should_receive('differs?').and_return(true)
        project = Project.new(name: 'foo', git_url: '/foo.git', revision_repository: rev_repo, env: double('env'))
        project.new_revision?.should == true
      end

      it "returns false if repository has not changed relative to the newest build" do
        rev_repo = double('rev_repo', empty?: false)
        rev = double('rev')
        rev_repo.should_receive('most_recent_revision').and_return(rev)
        rev.should_receive('differs?').and_return(false)
        project = Project.new(name: 'foo', git_url: '/foo.git', revision_repository: rev_repo, env: double('env'))
        project.new_revision?.should == false
      end
    end
  end
end
