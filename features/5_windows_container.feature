Feature: 5.x Windows persistent container
  As a Windows user, I can build and run a persistent Windows container mounting the repo and passing env vars.

  Scenario: 5.1 build and launch tui-win
    Given environment variable "OS" is set to "Windows_NT"
    When I run "make install-win-docker"
    Then the command succeeds or prints a clear message about Windows containers mode

