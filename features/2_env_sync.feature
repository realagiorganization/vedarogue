Feature: 2.x Env sync for Kitty and iTerm2
  As a user, I can generate terminal env configs from a curated list of variables.

  Background:
    Given environment variable "PROJECT" is set to "demo-project"
    And environment variable "ENV" is set to "dev"

  Scenario: 2.1 generate kitty env snippet
    When I run "make env-sync"
    Then file "install_tui/generated/kitty_env.conf" exists

  Scenario: 2.2 generate iTerm2 launcher
    When I run "make env-sync"
    Then file "install_tui/generated/iterm2_env_launcher.sh" exists

  Scenario: 2.3 install iTerm2 dynamic profile
    Given environment variable "HOME" is set to "/Users/me"
    When I run "make install-iterm2-dynamic-profile"
    Then file "/Users/me/Library/Application Support/iTerm2/DynamicProfiles/tui-env-profile.json" exists

