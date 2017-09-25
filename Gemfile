source 'https://rubygems.org'

# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc

gem 'nokogiri', '>= 1.7.1' # >= 1.7.1 due to CVE-2016-4658
gem 'rubyzip',  '>= 1.2.1' # >= 1.2.1 due to CVE-2017-5946
gem 'sshkit'
gem 'paranoia', '~> 2.0'
gem 'composite_primary_keys', '~> 8.0'
gem "pg"
gem 'activerecord-import'
gem 'charlock_holmes', require: false
gem "rails", '~> 4.2.8'
gem 'bcrypt'
gem "haml-rails"
gem "sass-rails"
gem 'autoprefixer-rails'
gem 'kaminari'
gem 'with_advisory_lock'
gem 'schema_plus_views'
gem 'memoist', require: false

# File processing
gem 'carrierwave'
gem 'acts-as-taggable-on', '~> 4.0'
# this doesn't install cleanly on a Mac
# We aren't currently using this anyway
# gem 'seven_zip_ruby', group: :seven_zip

gem 'devise', '~> 3.5'
gem 'devise_invitable'
gem 'paper_trail'
gem 'validates_email_format_of'
gem 'text'

gem "lograge"
gem 'activerecord-session_store'
gem 'attribute_normalizer'
gem 'delayed_job_active_record'
gem 'uglifier'
gem 'daemons'

gem "simple_form"
gem 'virtus'

# Asset related
gem 'bootstrap-sass'
gem "jquery-rails"
gem 'coffee-rails'
gem 'handlebars_assets'
gem 'execjs'
gem 'sprockets-es6'
gem 'select2-rails'
gem 'font-awesome-sass'
gem 'jquery-ui-rails'
# gem 'chart-js-rails'
gem 'nominatim'
gem 'linefit'
gem 'jquery-minicolors-rails'
gem 'jquery-datatables-rails'

# ETO API related
gem "rest-client", "~> 2.0"
gem "gmail", require: false

# for de-duping clients
gem 'redcarpet'

# For exporting
# As of 2017-05-02 the most recent rubygem version of axlsx
# depended on nokogiri and rubyzip with active CVE's
# we needed https://github.com/randym/axlsx/commit/776037c0fc799bb09da8c9ea47980bd3bf296874
# and https://github.com/randym/axlsx/commit/e977cf5232273fa45734cdb36f6fae4db2cbe781
gem 'axlsx', git: 'https://github.com/randym/axlsx.git'
gem 'axlsx_rails'
gem 'roo', require: false
# gem 'wicked_pdf'
# gem 'wkhtmltopdf-binary'

gem 'whenever', require: false
gem 'ruby-progressbar', require: false

gem 'slack-notifier'
gem 'exception_notification'

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Unicorn as the app server
gem 'puma', '~> 3.7.1'
gem 'letsencrypt_plugin'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

gem 'newrelic_rpm', require: false
# gem "temping", require: false
gem 'dotenv-rails'

gem 'net-sftp', require: false
gem 'redis-rails'

#AWS SDK
gem 'aws-sdk-rails', require: false

gem 'auto-session-timeout'

#Translations
gem 'gettext_i18n_rails'
gem 'fast_gettext'
gem 'gettext', '>=3.0.2', require: false
gem 'ruby_parser', require: false
gem 'grosser-pomo'

gem 'responders'
gem 'ransack'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'
  gem 'pry-rails'
  gem 'foreman'
  gem 'rspec-rails'
  gem 'factory_girl_rails'
  gem 'guard-rspec', require: false
end

group :development do
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'html2haml'
  gem 'brakeman', require: false
  gem 'bundler-audit', require: false
  gem 'capistrano', '~> 3.6.1'
  gem 'capistrano-bundler'
  gem 'capistrano-rvm'
  gem 'capistrano-passenger'
  gem 'capistrano-rails'
  gem 'capistrano3-delayed-job', '~> 1.0'
  gem 'rails-erd'
  gem 'web-console'
  gem 'quiet_assets'
  gem 'letter_opener'
  gem 'list_matcher', require: false   # for the forms:desmush rake task


  gem 'ruby-prof'
  gem 'memory_profiler'
  gem 'rack-mini-profiler', require: false
  gem 'flamegraph'
  gem 'stackprof'     # For Ruby MRI 2.1+
  gem 'rb-readline'
end

group :test do
  gem "capybara"
  gem "launchy"
  gem 'minitest-reporters'
  gem 'rspec-mocks'
  gem 'shoulda'
end

group :development, :staging do
  # Faker queries translations db in development to look for user overrides of fake data
  # There is no way to disable this
  gem 'faker', '>= 1.7.2', require: false
end
