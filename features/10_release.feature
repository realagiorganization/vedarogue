Feature: 10.x Release tagging and artifacts
  As a maintainer, I can tag a release to trigger crates.io publish, GHCR pushes, and a GitHub Release with artifacts.

  Scenario: 10.1 bump version and tag
    Given environment variable "VERSION" is set to "0.1.1"
    When I run "git tag -a v0.1.1 -m 'release: v0.1.1' && git push origin v0.1.1"
    Then CI publishes the crate and pushes images to GHCR
    And CI creates a GitHub Release with docker test logs and deployments readme attached

