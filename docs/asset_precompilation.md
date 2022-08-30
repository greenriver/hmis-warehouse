## Asset Checksumming

`bin/asset_checksum`

In order to make it easy to tell if the assets need to be recompiled or if the cached versions can be used, we generate a checksum based on the content of `app/assets` (including client theme files). The goal is for the checksum to be guaranteed to change if a change is made to the source assets that will alter the compiled output, *and* guaranteed *not* to change otherwise.

*Note: Because the checksum when stored in "cache" (S3) will be namespaced to client/environment, it is not necessary to hash any of the client ENV secrets (CLIENT or RAILS_ENV would have been the only ones affecting compiled output).*

## The GitHub Actions Workflow

`.github/workflows/asset_compilation.yml`

This workflow iterates through every client (for both environments). It uses a [matrix](https://docs.github.com/en/actions/using-jobs/using-a-matrix-for-your-jobs) to iterate over a list of anonymized identifiers (`gha_staging_load_1`, `gha_production_load_3`), which are used to preserve client anonymity in an open source code base. Each identifier is passed to `bin/compile_assets.rb`.

## The Asset Compiler

`bin/compile_assets.rb`
`config/deploy/docker/lib/asset_compiler.rb`

`bin/compile_assets.rb` is analogous to `bin/deploy.rb`. It uses `config/deploy/docker/lib/command_args.rb` to pull down the secrets.yml file from AWS Secrets Manager (the credentials are stored in the GitHub [repository secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets) and are not loaded for non-internal workflow runs). It takes the anonymized identifier passed by the workflow and finds it in the list of client group identifiers at the bottom of the secrets.yml file, where it is mapped to real client identifying information. Currently each anonymized "group" has only 1 client, in order to maximize speed of the parallel asset compilation. The client information is passed to `AssetCompiler.run!`

`config/deploy/docker/lib/asset_compiler.rb` is analogous to `config/deploy/docker/lib/deployer.rb`. It starts by performing an asset_checksum and checking if that checksum has been stored in S3 yet. If it has, we don't need to do anything else, since the compiled output of the source assets would match the stored compiled output. If the checksum hasn't been stored, then there has been a change to the assets. In this case we pull down the client ENV secrets to bootstrap the client environment, and run asset precompilation via rake. These assets are then uploaded to S3 under the client, environment, and checksum.

## The Deployed Containers

`config/deploy/docker/assets/entrypoint.sh`

When a container spins up, the Docker entrypoint script generates an asset_checksum and pulls down the assets from S3. If the assets don't exist yet, the script will wait (`bin/wait_for_compiled_assets.rb`) and check again every 60 seconds. Note that this will happen in the deploy container before any of the application containers are spun up, meaning that you should be able to catch missing assets before the deploy goes through.

**NOTE:** If you make a change in the remote client theme files, you will need to ensure that the GitHub Actions workflow runs at least once to pick up that change. Otherwise the checksum generated in the entrypoint won't match the last stored checksum and the waiting will never finish.
