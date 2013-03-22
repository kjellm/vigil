require 'spec_helper'

class Vigil
  describe Project do

    describe "#syncronize" do
      it "updates the repository"
    end

    describe "#new_revision?" do

      it "returns true if no builds exists for this project" # do
        #build_repository.should_receive('empty?').and_return('true')
        #Project.new.new_revision?.should == 
      #end
      
      it "returns true if repository has stuff that are newer than the newest build"
      it "returns false if repository has not changed relative to the newest build"
    end

    describe "#build" do
      it "runs the pipeline on the newest revision"
    end
  end
end

