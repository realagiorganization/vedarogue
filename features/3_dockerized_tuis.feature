Feature: 3.x Dockerized TUIs launcher
  As a user, I can run TUIs inside a Docker image with profiles and per-item subdirs.

  Scenario: 3.1 run a single TUI with explicit image
    Given environment variable "DOCKER_IMAGE_TUI" is set to "busybox:latest"
    When I run "make docker-tuis TUIS='sh -lc "echo HI"'"
    Then the command succeeds

  Scenario: 3.2 run multiple TUIs with a default profile
    Given environment variable "PROFILE" is set to "busybox"
    When I run "make docker-tuis TUIS='busybox@sh -lc "echo A" alpine@sh -lc "echo B"'"
    Then the command succeeds

  Scenario: 3.3 run TUIs from a list file
    Given file "docs/session_tui_list.txt" exists
    And environment variable "PROFILE" is set to "tui"
    When I run "make docker-tuis-file TUIS_FILE='docs/session_tui_list.txt'"
    Then the command succeeds

