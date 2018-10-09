# Developer Setup
The warehouse application consists of three parts:
1. The Rails Application Code
2. The Rails Application Database
3. THe Warehouse Database

## Setup Your Development Environment

1. Clone the git repository
```
git clone git@github.com:greenriver/hmis-warehouse.git
```
2. GEM dependencies - you may need to install the following dependencies prior to running `bin/setup`.
```shell
brew install freetds
brew install icu4c
brew install openssl
brew install libmagic
```
Sometimes icu4c and charlock_holmes give us issues.  Here's a relatively complete fix.
```shell
brew uninstall icu4c --force --ignore-dependencies
brew reinstall node
gem install charlock_holmes --version 0.7.6 -- --with-icu-dir=/usr/local/opt/icu4c --with-cxxflags=-std=c++11
bundle
```
Install R and Rserve
Download and install the latest package from here:
https://cran.r-project.org/bin/macosx/
Open an R terminal and install Rserve
```shell
r
install.packages("Rserve")
q()
```
Set Rserve to start when R starts
Place the following in `~.Rprofile`
```shell
useDynLib(Rserve)
export(Rserve, self.ctrlEval, self.ctrlSource, self.oobSend, self.oobMessage, run.Rserve)
```

3. Create a `.env` file and add values for each of the variables in the `config/*.yml` files.

4. You may experience issues with openssl, brew, postgres and rvm not playing nicely together.  The following should help with trouble shooting.  At the time of writing, we're looking for OpenSSL 1.1.x
```shell
ruby -ropenssl -e 'puts OpenSSL::OPENSSL_VERSION'
```

5. Run the setup file
```
cd hmis-warehouse
bin/setup
```

6. Seed the data sources
```shell
bin/rake grda_warehouse:seed_data_sources
```

## Anonymized Data
1. In your production environment, export a batch of anonymized data
```
bin/rake grda_warehouse:dump_hud_csvs_for_dev[2500]
```

2. In your development environment, place the exported files in folders in `var/hmis/<data_source_name>`

3. Import the batch
```
bin/rake grda_warehouse:import_dev_hud_csvs
```

4. Run through the daily imports, you may want to do this manually, though it can be done in a single pass with
```
bin/rake grda_warehouse:daily
```
