source 'https://rubygems.org'

gem 'rails', '~>5.2.6'
gem 'rails_drivers'

# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', group: :doc

gem 'nokogiri', '>= 1.11.0.rc4' # >= 1.11.0.rc4 due to CVE-2020-26247
gem 'rubyzip',  '>= 1.2.1' # >= 1.2.1 due to CVE-2017-5946
gem 'sshkit'
gem 'paranoia', '~> 2.0'
# gem 'composite_primary_keys', '~> 11'
gem 'composite_primary_keys', '=11.3.1' #branch: 'active-record-5.2.4-compatability'
gem 'pg'
# version 5.2.1 lacks a small fix we need that's currently at the head of the 5-2-stable branch.
gem 'activerecord-sqlserver-adapter'
gem 'activerecord-import'
gem 'order_as_specified'

# locking active record extended here temporarily since upgrading it to 2.0.0 gives
# NoMethodError: undefined method `relation' for "DATE_TRUNC('month', date_of_activity)":Arel::Nodes::SqlLiteral
# on .count for active record queries of Arel
gem 'active_record_extended', '~> 1.4.0'
gem 'active_median'

# style-inliner https://github.com/premailer/premailer
gem 'premailer'

gem 'census_api', github: 'greenriver/census_api'

# spatial manipulations
gem 'activerecord-postgis-adapter'
gem 'ffi-geos'
gem 'rgeo'
gem 'rgeo-geojson'
gem 'rgeo-proj4'

gem 'active_record_distinct_on'
gem 'charlock_holmes', require: false
gem 'bootsnap'
gem 'bcrypt'
gem 'haml-rails'
gem 'sassc-rails'
gem 'autoprefixer-rails'
gem 'kaminari'
gem 'pagy'
gem 'with_advisory_lock'
# gem 'schema_plus_views'
gem 'scenic'
gem 'memoist', require: false
gem 'rserve-client', require: false
gem 'rserve-simpler', require: false
gem 'encryptor'

# File processing
gem 'carrierwave', '~> 1'
gem 'carrierwave-i18n'
gem 'carrierwave-aws'
gem 'ruby-filemagic'
gem 'mini_magick'
# there are no obvious breaking changes but
# since there are no tests for this
# it should be tested manually
gem 'acts-as-taggable-on', '~> 7.0'
# this doesn't install cleanly on a Mac
# We aren't currently using this anyway
gem 'seven_zip_ruby'
gem 'hellosign-ruby-sdk'

gem 'devise', '~> 4'
gem 'devise_invitable', '~> 2.0'
gem 'devise-pwned_password'
gem 'devise-security'
gem 'devise-two-factor'

gem 'omniauth-oauth2'
gem 'omniauth-rails_csrf_protection'

gem 'pretender'
gem 'rqrcode-rails3'
gem 'rqrcode', '~> 0.4' # pin to support current version of rqrcode-rails3

gem 'authtrail' # for logging login attempts
gem 'maxminddb' # for local geocoding of login attempts

gem 'paper_trail'
gem 'validate_url'
gem 'validates_email_format_of'
gem 'ruby-mailchecker'
gem 'email_check'
gem 'text'

gem 'lograge'
gem 'logstop'
gem 'activerecord-session_store'
gem 'attribute_normalizer'
gem 'delayed_job'
#locking temporarily to protect the delayed job monkey patch
gem 'delayed_job_active_record'#, '4.1.4'
gem 'uglifier'
gem 'daemons'

gem 'simple_form'
gem 'virtus'

# Asset related
gem 'bootstrap', '~> 4.3'
gem 'jquery-rails'
gem 'coffee-rails'
gem 'handlebars_assets'
gem 'execjs'
gem 'sprockets', '~> 3'
gem 'sprockets-es6'
gem 'jquery-ui-rails'
# gem 'chart-js-rails'
gem 'nominatim'
gem 'linefit'
gem 'jquery-minicolors-rails'
gem 'htmlentities'
# gem 'jquery-datatables-rails'
# gem 'bootstrap4-datetime-picker-rails'
gem 'bootstrap3-datetimepicker-rails', '~> 4.17.42'
# gem 'stimulusjs-rails', '~> 1.1.1'

# ETO API related
gem 'rest-client', '~> 2.0'
gem 'curb', require: false
gem 'gmail', require: false
# gem 'savon'
# gem 'qaaws', require: false, git: 'https://github.com/greenriver/eis-ruby-qaaws.git', branch: 'master'

gem 'stupidedi' #, require: false #, git: 'https://github.com/greenriver/stupidedi.git', branch: '820'

gem 'redcarpet'

gem 'kiba'
gem 'kiba-common'

# For exporting
gem 'caxlsx'
gem 'caxlsx_rails'
gem 'roo', require: false
gem 'roo-xls', require: false
gem 'rubyXL', require: false
gem 'soundex', require: false # for HMIS 6.11 + exports that use SHA-256 of soundex

# PDF Exports
gem 'wicked_pdf'
gem 'combine_pdf'
gem 'grover'

gem 'whenever', require: false
gem 'progress_bar', require: false

gem 'slack-notifier'
gem 'exception_notification'

gem 'puma', '~> 4.3.9'

gem 'dotenv-rails'

gem 'net-sftp', require: false
gem 'redis-rails'

# AWS SDK is needed for deployment and within the application
gem 'aws-sdk-rails'
gem 'aws-sdk-cloudwatchevents', '~> 1'
gem 'aws-sdk-cloudwatchlogs', '~> 1'
gem 'aws-sdk-cloudwatch', '~> 1'
gem 'aws-sdk-ecs', '~> 1'
gem 'aws-sdk-ec2', '~> 1'
gem 'aws-sdk-ecr', '~> 1'
gem 'aws-sdk-glacier', '~> 1'
gem 'aws-sdk-rds', '~> 1'
gem 'aws-sdk-s3', '~> 1'
gem 'aws-sdk-secretsmanager', '~> 1'
gem 'aws-sdk-ses', '~> 1'
gem 'aws-sdk-iam', '~> 1'
gem 'aws-sdk-sns', require: false
gem 'json'
gem 'oj'
gem 'amazing_print'

gem 'auto-session-timeout'

# Translations
gem 'gettext_i18n_rails'
gem 'fast_gettext'
gem 'gettext', '>=3.0.2'
gem 'grosser-pomo'

gem 'responders'
gem 'ransack'

gem 'rack-attack'

gem 'attr_encrypted', '~> 3.1.0'

gem 'ajax_modal_rails', '~> 1.0'
gem 'browser'
gem 'ansi'

gem 'parallel'
gem 'todo_or_die'
gem 'reline', '~> 0.2'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'
  gem 'pry-rails'
  gem 'bundler-audit', require: false
  gem 'brakeman', require: false
  gem 'rspec-rails', require: false
  gem 'factory_bot_rails'
  gem 'guard-rspec', require: false
  gem 'vcr'
  gem 'webmock'
  # gem 'rb-readline'
end

group :development do
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring', require: false
  gem 'html2haml', require: false
  gem 'capistrano-bundler', require: false
  gem 'capistrano-rvm', require: false
  gem 'capistrano-passenger', require: false
  gem 'capistrano-rails', require: false
  gem 'rails-erd', require: false
  gem 'web-console'
  gem 'aws-sdk-dynamodb', require: false
  # gem 'quiet_assets'

  gem 'list_matcher', require: false # for the forms:desmush rake task

  gem 'ruby-prof', require: false
  gem 'memory_profiler', require: false
  gem 'get_process_mem', require: false
  gem 'rack-mini-profiler', require: false
  gem 'flamegraph', require: false
  gem 'stackprof', require: false
  gem 'active_record_query_trace', require: false
  gem 'marginalia'
  gem 'overcommit', require: false
  gem 'rubocop', require: false
  gem 'rubocop-rspec', require: false
  gem 'rubocop-rails', require: false

  # boot time/memory profiling
  gem 'derailed_benchmarks', require: false
  gem 'bumbler', require: false
end

group :test do
  gem 'capybara'
  gem 'fixpoints'
  gem 'minitest-reporters'
  gem 'rspec-mocks'
  gem 'shoulda'
  gem 'timecop'
  gem 'after_commit_exception_notification'
  gem 'rails-controller-testing'
  # gem 'simplecov'
  # gem 'simplecov-console'
end

group :development, :staging, :test do
  # Faker queries translations db in development to look for user overrides of fake data
  # There is no way to disable this
  gem 'faker', '>= 1.7.2', require: false
end

# This is really unhappy on travis
group :production, :development, :staging do
  gem 'tiny_tds'
end

gem "business_time", "~> 0.10.0"

gem "cable_ready", "~> 4.5"
