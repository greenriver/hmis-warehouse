#!/bin/bash

# Checkout, build, and run the HMIS frontend locally

# usage
# BRANCH_NAME=186406279-hmis-system-e2e-tests bin/run_hmis_system_tests.sh

if [[ "$1" = "--dev" ]]; then
  echo "Running in dev mode"
  dev_mode=true
else
  dev_mode=false
fi

if [ -z "$REPO_URL" ]; then
  # If not set, assign a default value
  REPO_URL="https://github.com/greenriver/hmis-frontend.git"
fi

echo "Branch list: $BRANCH_NAME"
if [ -z "$BRANCH_NAME" ]; then
  echo "Error: The BRANCH_NAME environment variable is not set."
  exit 1
fi

# Function to find the first branch that exists
find_existing_branch() {
  IFS=':' read -r -a branches <<< "$BRANCH_NAME"
  for branch in "${branches[@]}"; do
    if git ls-remote --exit-code --heads "$REPO_URL" "$branch" &> /dev/null; then
      echo "$branch"
      return
    fi
  done
  echo ""
}

branch_to_checkout=$(find_existing_branch)
if [ -z "$branch_to_checkout" ]; then
  echo "Error: None of the specified branches exist."
  exit 1
fi

echo "Branch to checkout: $branch_to_checkout"

# Create a temporary directory
TEMP_DIR=$(mktemp -d)

# Ensure temporary directory was created
if [[ ! "$TEMP_DIR" ]]; then
  echo "Failed to create a temporary directory."
  exit 1
fi

# Function to cleanup on exit
cleanup() {
  echo "Removing temporary directory ${TEMP_DIR}"
  # comment this out to preserve the directory on exit
  rm -rf "$TEMP_DIR"
}

# Register the cleanup function to be called on the EXIT signal
if [ "$dev_mode" = false ] ; then
  trap cleanup EXIT
fi

# Save the current working directory
ORIGINAL_CWD=$(pwd)

set -x
# Change to the temporary directory
cd "$TEMP_DIR"

# fails on exit
set -e

# Clone the specific branch from the repository
git clone --depth 1 --branch "$branch_to_checkout" "$REPO_URL" .

CWD=$(pwd)
yarn config set ignore-engines true
yarn --cwd $CWD install
yarn --cwd $CWD build

# unset fails on exit
set +e

# hostname for chrome container to connect to this container
HOSTNAME=`hostname`

# If dev mode, start in the foreground
if [ "$dev_mode" = true ] ; then
  SERVER_HTTPS=false HMIS_SERVER_URL="http://localhost:4444" HMIS_HOST=$HOSTNAME yarn --cwd $CWD preview -d
  SERVER_PID=$!
  exit 0
fi

# Start in the background
SERVER_HTTPS=false HMIS_SERVER_URL="http://localhost:4444" HMIS_HOST=$HOSTNAME yarn --cwd $CWD preview &
SERVER_PID=$!

sleep 5

# Change back to the original working directory
cd "$ORIGINAL_CWD"

# skip okta if it's set in our local env
unset HMIS_OKTA_CLIENT_ID
unset OKTA_DOMAIN
RUN_SYSTEM_TESTS=true RAILS_ENV=test CAPYBARA_APP_HOST="http://$HOSTNAME:5173" rspec drivers/hmis/spec/system/hmis/*

TEST_EXIT_CODE=$?

kill $SERVER_PID
wait $SERVER_PID

exit $TEST_EXIT_CODE
