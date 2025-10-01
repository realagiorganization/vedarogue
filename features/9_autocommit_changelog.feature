Feature: 9.x Auto-commit with changelog and docker output examples
  As a maintainer, I can auto-commit with required README changelogs and docker output snippets.

  Scenario: 9.1 generate changelog
    When I run "bash scripts/generate_changelog.sh"
    Then file "CHANGELOG.md" exists

  Scenario: 9.2 auto-commit and push
    Given environment variable "GIT_AUTHOR_NAME" is set to "codex-bot"
    And environment variable "GIT_AUTHOR_EMAIL" is set to "codex-bot@example.com"
    When I run "bash scripts/auto_commit.sh 'docs: update'"
    Then the command succeeds

