module Vigil

  class Project
  end


end

Given /^A project$/ do
    @project = Vigil::Project.new
end

When /^the pipeline is executed$/ do
  pending # express the regexp above with the code you wish you had
  @project.run_pipeline
end

Then /^it builds a new virtual machine$/ do
  pending # express the regexp above with the code you wish you had
end

Then /^runs the tests$/ do
  pending # express the regexp above with the code you wish you had
end
