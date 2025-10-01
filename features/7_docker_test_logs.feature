Feature: 7.x Docker test logs and CSV→YAML
  As a maintainer, I can run containerized tests, write CSV logs, and convert them to YAML.

  Scenario: 7.1 run docker tests script
    When I run "bash scripts/run_docker_tests.sh"
    Then file "build/test_logs/tests.csv" exists

  Scenario: 7.2 convert CSV to YAML
    When I run "python3 scripts/csv_to_yaml.py build/test_logs/tests.csv build/test_logs/tests.yaml"
    Then file "build/test_logs/tests.yaml" exists

