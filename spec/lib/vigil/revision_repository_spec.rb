require 'spec_helper'

class Vigil
  
  describe RevisionRepository do

    describe "#most_recent_revision" do

      it "return FIXME when no revisions are found"

      it "finds the revision with the highest ID" do
        os = double('os').as_null_object
        Vigil.os = os
        os.should_receive('entries').with('/run_dir').and_return(%w(boxes 2 1 10 3 6 5 4 7 8 9))
        project = double('project', working_dir: '/run_dir')
        r = RevisionRepository.new(os, project)
        r.most_recent_revision.id.should == 10
      end
    end
  end
end
