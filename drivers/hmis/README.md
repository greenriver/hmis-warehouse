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

1. Start the docker container for headless Chrome. This is in our `docker-compose.yml` file, but it's part of the `test` profile, so it isn't started when running `docker-compose up` normally.
    ```bash
    docker compose up chrome
    ```

2. In another tab, open a Docker shell.
    ```bash
    docker compose run --rm shell  # `dcr shell` if you have that alias
    ```

3. In the Docker shell, run the `run_hmis_system_tests` script, indicating the branch of the `hmis-frontend` repo you want to test. This script will start the vite "preview" process

    ```bash
    BRANCH_NAME=release-X ./bin/run_hmis_system_tests.sh --dev
    ```

4. In a new tab, enter the same Docker shell where you are running the frontend:
    ```bash
    docker exec -it $(docker ps -aqf "name=^hmis-warehouse_shell_run" | head -1) /bin/bash
    ```

5. Run the rspec test(s) in that container:
    ```bash
    HOSTNAME=`hostname` RUN_SYSTEM_TESTS=true RAILS_ENV=test CAPYBARA_APP_HOST="http://$HOSTNAME:5173" rspec -f d -P "drivers/hmis/spec/system/hmis/*"
    ```


### Debugging
The `debug` helper, defined in [e2e_tests.rb](e2e_tests.rb), enables pausing the driver and inspecting what is going on at the moment in the browserless Chrome.
- Add `debug` on its own line. The test will pause execution at that line, output "Cuprite execution paused" to stdout, and output a localhost link to open the Chrome inspector. Open that localhost link.
- Click the icon for Current Sessions (left sidebar between `<>` and the Settings gear icon).
- Under "Current Sessions" there should be a link to "Open Path HMIS." Clicking this link will take you to the current session, in which you can interact and inspect the DOM.


## Run Full E2E test suite locally

This script is designed to be run as part of a CI pipeline. It clones the frontend repo into a temporary directory, serves the frontend using yarn preview, runs the system tests against that frontend, and then shuts everything down and cleans up after the tests finish running.

1. Bring up chrome.
    ```bash
    docker compose up chrome
    ```

2. In another tab, open a Docker shell.
    ```bash
    docker compose run --rm shell  # `dcr shell` if you have that alias
    ```

3. In the Docker shell, run the `run_hmis_system_tests` script, indicating the branch of the `hmis-frontend` repo you want to test:
    ```bash
    BRANCH_NAME=branch-name-to-test ./bin/run_hmis_system_tests.sh
    ```
