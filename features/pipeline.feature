Feature: Pipeline


  Scenario: Running the pipeline on a project for the first time
    Given A project with no previous builds
      And a pipeline with a VMBuildTask and a TestTask
     When its pipeline gets executed
     Then each task in the pipeline gets executed
      And a Report is returned

  Scenario: Running the pipeline when there is changes since last build
    Given A project with
      And a pipeline with a VMBuildTask and a TestRunTask
     When its pipeline gets executed
     Then each task in the pipeline gets executed
