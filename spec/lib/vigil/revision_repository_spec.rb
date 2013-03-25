require 'spec_helper'

class Vigil
  
  describe RevisionRepository do

    before :each do
      @os = double('os').as_null_object
      Vigil.os = @os
    end

    describe "#empty?" do
      it "returns true when no revisions are found" do
        project = double('project', working_dir: '/run_dir')
        @os.should_receive('entries').with('/run_dir').and_return(%w(boxes))
        r = RevisionRepository.new(project)
        r.empty?.should == true
      end

      it "finds the revision with the highest ID" do
        @os.should_receive('entries').with('/run_dir').and_return(%w(boxes 2 1 10 3 6 5 4 7 8 9))
        project = double('project', working_dir: '/run_dir')
        r = RevisionRepository.new(project)
        r.empty? == false
      end      
    end

    describe "#most_recent_revision" do

      it "returns a Revision with id set to 0 when no revisions are found" do
        project = double('project', working_dir: '/run_dir')
        @os.should_receive('entries').with('/run_dir').and_return(%w(boxes))
        r = RevisionRepository.new(project)
        r.most_recent_revision.id.should == 0
      end

      it "finds the revision with the highest ID" do
        @os.should_receive('entries').with('/run_dir').and_return(%w(boxes 2 1 10 3 6 5 4 7 8 9))
        project = double('project', working_dir: '/run_dir')
        r = RevisionRepository.new(project)
        r.most_recent_revision.id.should == 10
      end
    end
  end
end
