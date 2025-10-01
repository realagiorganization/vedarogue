Feature: 1.x TUI installers
  As a user, I can install and verify TUIs via Makefile targets.

  Background:
    Given environment variable "PATH" contains "/opt/homebrew/bin"

  Scenario Outline: 1.<n> install <tool>
    When I run "make install-<tool>"
    Then the command succeeds
    And I can run "make verify-<tool>" and it succeeds

    Examples:
      | n  | tool            |
      | 1  | diskonaut       |
      | 2  | gdu             |
      | 3  | ncdu            |
      | 4  | xplr            |
      | 5  | wego            |
      | 6  | nemu            |
      | 7  | kitty           |
      | 8  | iterm2          |
      | 9  | distrobox-tui   |
      | 10 | gif-for-cli     |
      | 11 | ttyper          |
      | 12 | tray-tui        |
      | 13 | tlock           |

  Scenario: 1.install-all and 1.verify-all
    When I run "make install-all"
    Then the command succeeds
    When I run "make verify-all"
    Then the command succeeds

