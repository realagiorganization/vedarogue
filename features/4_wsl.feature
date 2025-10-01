Feature: 4.x WSL setup flows
  As a Windows user, I can install WSL and create a Linux dev container.

  Scenario: 4.1 ensure WSL installed
    When I run "make install-wsl"
    Then the command completes (may require admin / reboot)

  Scenario: 4.2 launch WSL-like container under Linux containers mode
    When I run "make install-wsl-in-docker"
    Then the command completes or prints guidance to switch to Linux containers

