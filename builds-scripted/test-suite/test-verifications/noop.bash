#!/usr/bin/env bash

echo "Initializing up test results file"
TEST_FILE="/srv/test-results.txt"
tee -a "TEST CASE: noop" "${TEST_FILE}"
