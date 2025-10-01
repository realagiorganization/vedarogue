Feature: 6.x CI build, test, publish, and release
  As a maintainer, I can rely on CI to build and test the crate, dockerize, publish to crates.io, push GHCR images, and create a Release.

  Scenario: 6.1 cargo fmt/clippy/build/test matrix
    When CI runs workflow "Cargo CI" on push
    Then steps format check, clippy, build, and tests succeed on ubuntu, macos, and windows

  Scenario: 6.2 docker build and smoke run
    When CI builds image from "docker/cargo/Dockerfile"
    Then it runs "make-runner list" inside the container successfully

  Scenario: 6.3 publish crate on tags
    Given environment variable "CRATES_IO_TOKEN" is set to "***"
    When CI sees a tag like "v0.1.1"
    Then it runs "cargo publish --no-verify" successfully

  Scenario: 6.4 push GHCR images on main/tags
    Given environment variable "GITHUB_TOKEN" is set to "***"
    When CI builds images
    Then it pushes ghcr.io/<owner>/<repo> images for make-runner, emacs, and tui-wsl

  Scenario: 6.5 create GitHub Release and attach artifacts
    When CI runs release job on tags
    Then it attaches docker-test-logs and README.deployments.md and includes release body text

