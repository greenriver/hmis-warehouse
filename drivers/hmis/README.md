## HMIS Driver

This driver contains all the backend logic for supporting the [HMIS Frontend](https://github.com/greenriver/hmis-frontend).

To enable locally:
```
ENABLE_HMIS_API=true
HMIS_HOSTNAME=hmis.dev.test
```

### New Deployment Checklist

Some things need to be done manually for a new deployment:

* Create the HMIS Data Source
* Create an HMIS Administrator role
* Configure permissions in the warehouse
* Set up File Tags in the warehouse
* Create any UnitTypes
* Create any CustomServiceTypes and categories
* Create any CustomDataElementDefinitions
* Set up any RemoteCredentials
* Enable any InboundApiConfigurations
* Create a GrdaWarehouse::Theme

# E2E Testing

We have a few end-to-end tests located in [drivers/hmis/spec/system/hmis](drivers/hmis/spec/system/hmis).
Below are instructions for getting set up to run and write E2E tests locally.

## Background and Testing Philosophy

The goal of these tests is to catch regressions, especially in the UI. The tests use [Capybara](https://github.com/teamcapybara/capybara), which allows us to test our [frontend](https://github.com/greenriver/hmis-frontend/) using our existing factories to mock the backend models. This means these tests are testing both UI and API behavior.

Since E2E tests are expensive -- slow to run and fiddly to write/update -- we should avoid testing parts of the interface where we anticipate major redesign or other churn, and we should avoid using E2E tests to test logic that could be tested more efficiently in another way. For example, we would use an E2E test to verify that form validation messages are displayed appropriately to the user, but we would not write E2E tests exercising all the different validations on every field; this kind of logic should be tested using an API or model test.

## Develop E2E Tests Locally

1. Open a Docker shell.
    ```bash
    docker compose run --rm \
      --env CHROME_DEBUGGING_PORT=${CHROME_DEBUGGING_PORT:-9222} \
      --env CHROME_DEBUGGING_PROXY_PORT=${CHROME_DEBUGGING_PROXY_PORT:-9223} \
      --publish ${CHROME_DEBUGGING_PROXY_PORT:-9223}:${CHROME_DEBUGGING_PROXY_PORT:-9223} \
      shell  # `dcr shell --publish ...` if you have that alias
    ```

2. In the Docker shell, run the `run_hmis_system_tests` script, indicating the branch of the `hmis-frontend` repo you want to test. The `--dev` flag keeps the frontend server running in the foreground for development.

    ```bash
    BRANCH_NAME=release-X ./bin/run_hmis_system_tests.sh --dev
    ```

    You can specify multiple fallback branches separated by colons, although this is mostly used in CI to guess at the right branch:
    ```bash
    BRANCH_NAME=my-feature-branch:main ./bin/run_hmis_system_tests.sh --dev
    ```

3. In a new terminal tab, enter the same Docker _container_ where you are running the frontend (opening a new shell session):
    ```bash
    docker exec -it $(docker ps -aqf "name=^hmis-warehouse-shell-run" | head -1) /bin/bash
    ```
    Note: If that doesn't work for you, get the Container ID from `docker ps` and pass that instead of the `$()` clause.

4. Run the rspec test(s) in that container:
    ```bash
    HOSTNAME=`hostname` RUN_SYSTEM_TESTS=true RAILS_ENV=test CAPYBARA_APP_HOST="http://$HOSTNAME:5173" rspec -f d -P "drivers/hmis/spec/system/hmis/*"
    ```


### Debugging
The `debug` helper, defined in [spec/support/e2e_tests.rb](../../spec/support/e2e_tests.rb), enables pausing the driver and inspecting what is going on at the moment.
- Add `debug` on its own line. The test will pause execution at that line.

#### Interactive Browser Session

To inspect the page in a browser while debugging, you can run the test with the `CHROME_DEBUGGING_PORT` environment variable. This allows you to connect to the Chromium instance running inside the Docker container.

1.  Set the `CHROME_DEBUGGING_PORT` in your `.env.local` file or export it in your shell:
    ```bash
    export CHROME_DEBUGGING_PORT=9222
    ```

2.  Run your test as usual. When the `debug` statement is hit, you'll see a message in the console with a URL.

3.  In your host Chrome browser, open `chrome://inspect` and add the target `localhost:9223` (or the value of `CHROME_DEBUGGING_PROXY_PORT` if you set it differently) if it is not already present. The paused pages will appear under "Remote Target"—click "inspect" to attach Chrome DevTools to the live session.

    Note: The proxy port defaults to `CHROME_DEBUGGING_PORT + 1` (9223 if debugging port is 9222).


#### Other Debugging Tips
- Use `byebug`
- Use `print page.body` to print the page contents at a given point

## Run Full E2E test suite locally

This script is designed to be run as part of a CI pipeline. It clones the frontend repo into a temporary directory, serves the frontend using yarn preview, runs the system tests against that frontend, and then shuts everything down and cleans up after the tests finish running.

1. Open a Docker shell (use the same command from [Develop E2E Tests Locally](#develop-e2e-tests-locally) above, or just `docker compose run --rm shell` if you don't need debugging).

2. In the Docker shell, run the `run_hmis_system_tests` script, indicating the branch of the `hmis-frontend` repo you want to test:
    ```bash
    BRANCH_NAME=branch-name-to-test ./bin/run_hmis_system_tests.sh
    ```

    The script supports fallback branches (useful for testing feature branches that might not exist in all repos):
    ```bash
    BRANCH_NAME=my-feature-branch:main ./bin/run_hmis_system_tests.sh
    ```
