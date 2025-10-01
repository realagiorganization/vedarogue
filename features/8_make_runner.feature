Feature: 8.x make-runner CLI with full stdio passthrough
  As a user, I can use the cargo binary or its Docker image to run Make targets with interactive stdio.

  Scenario: 8.1 run list via cargo
    When I run "cargo run -- list"
    Then the command succeeds

  Scenario: 8.2 run Make target via cargo
    When I run "cargo run -- run env-sync"
    Then the command succeeds

  Scenario: 8.3 run list via Docker image
    When I run "make docker-make-runner-run ARGS='list'"
    Then the command succeeds

