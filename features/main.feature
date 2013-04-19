Feature:


Scenario: On first run
Given a minimal git repository
When Vigil runs
Then Vigil should do a first build

Scenario: No changes since last run
Given a minimal git repository
When Vigil runs and there are no changes since last run
Then Vigil should do nothing

Scenario: Changes since last run
Given a minimal git repository
When Vigil runs
 And a change is commited
 And Vigil runs again
Then Vigil should do a new build
