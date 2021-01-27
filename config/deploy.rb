# config valid only for current version of Capistrano
lock '~> 3.15.0'

set :application, 'warehouse'
set :repo_url, 'https://github.com/greenriver/hmis-warehouse.git'
set :client, ENV.fetch('CLIENT')

set :whenever_identifier, ->{ "#{fetch(:client)}-#{fetch(:application)}_#{fetch(:stage)}" }
set :cron_user, ENV.fetch('CRON_USER') { 'ubuntu'}
set :whenever_roles, [:cron, :production_cron, :staging_cron]
set :chmod_path, ENV.fetch('CHMOD_PATH') { '/bin/chmod' }
set :chown_path, ENV.fetch('CHOWN_PATH') { '/bin/chown' }
set :systemctl_path, ENV.fetch('SYSTEMCTL_PATH') { '/bin/systemctl' }

if ENV['WHENEVER_HACK']=='true'
  set :whenever_command, -> { "cat #{fetch(:release_path)}/.new_cron | sudo crontab -u #{fetch(:cron_user)} -" }
  before 'whenever:update_crontab', 'prime_whenever'
else
  set :whenever_command, -> { "bash -l -c 'cd #{fetch(:release_path)} && #{fetch(:rvm_custom_path)}/bin/rvmsudo ./bin/bundle exec whenever -u #{fetch(:cron_user)} --update-crontab #{fetch(:whenever_identifier)} --set \"environment=#{fetch(:rails_env)}\" '" }
end

if ENV['SYSTEMD_APP_SERVER_NAME'] != '' && !ENV['SYSTEMD_APP_SERVER_NAME'].nil?
  # Assuming stand-alone app server
  after 'deploy:symlink:release', :restart_puma do
    on roles(:web)  do
      # reload or restart might not switch directories correctly
      sudo "#{fetch(:systemctl_path)}", "stop", ENV['SYSTEMD_APP_SERVER_NAME']
      sudo "#{fetch(:systemctl_path)}", "start", ENV['SYSTEMD_APP_SERVER_NAME']
    end
  end
  before 'restart_puma',  :group_writable_and_owned_by_shared_user
else
  set :passenger_restart_command, 'sudo passenger-config restart-app --ignore-passenger-not-running --ignore-app-not-running'
  before 'passenger:restart',  :group_writable_and_owned_by_shared_user
end

if !ENV['FORCE_SSH_KEY'].nil?
  set :ssh_options, {
    keys: [ENV['FORCE_SSH_KEY']],
    port: ENV.fetch('SSH_PORT') { '22' },
    user: ENV.fetch('DEPLOY_USER'),
    forward_agent: true
  }
else
  set :ssh_options, {
    port: ENV.fetch('SSH_PORT') { '22' },
    user: ENV.fetch('DEPLOY_USER'),
    forward_agent: true
  }
end

set :ssh_port, ENV.fetch('SSH_PORT') { '22' }
set :deploy_user , ENV.fetch('DEPLOY_USER')

set :rvm_custom_path, ENV.fetch('RVM_CUSTOM_PATH') { '/usr/share/rvm' }
set :rvm_ruby_version, "#{File.read('.ruby-version').strip.split('-')[1]}@global"

task :group_writable_and_owned_by_shared_user do
  on roles(:app) do
    sudo "#{fetch(:chmod_path)} --quiet g+w -R #{fetch(:deploy_to)}"

    sudo "#{fetch(:chown_path)} --quiet #{fetch(:cron_user)}:#{fetch(:cron_user)} -R #{fetch(:deploy_to)}"

    # DHCD's sudo rules are brittle, thus:
    capture("ls -1 #{fetch(:deploy_to)}/shared/log/*").each_line do |line|
      sudo "#{fetch(:chown_path)} --quiet #{fetch(:cron_user)}:#{fetch(:cron_user)} -R #{line.chomp}"
    end
  end
end
after 'deploy:log_revision', :group_writable_and_owned_by_shared_user

# Default branch is :production
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
# set :deploy_to, '/var/www/my_app_name'

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: 'log/capistrano.log', color: :auto, truncate: :auto

# Default value for :pty is false
#set :pty, true

# Default value for :linked_files is []
set :linked_files, fetch(:linked_files, []).push(
  'config/secrets.yml',
  'config/cha_translations.yml',
  '.env',
  'app/views/root/_homepage_content.haml'
)

# Default value for linked_dirs is []
set :linked_dirs, fetch(:linked_dirs, []).push(
  'log',
  'tmp',
  'public/system',
  'var',
  'app/assets/stylesheets/theme/styles',
  'app/assets/images/theme/logo',
  'app/assets/images/theme/icons',
)

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

namespace :deploy do

  ##########################################################
  # Bootstrap database structure the first time you deploy #
  ##########################################################
  if ENV['FIRST_DEPLOY']=='true'
    before :migrating, :load_schema do
      on roles(:db)  do
        within release_path do
          execute :rake, "db:schema:conditional_load RAILS_ENV=#{fetch(:rails_env)}"
        end
      end
    end
    before :migrating, :load_warehouse_schema do
      on roles(:db)  do
        within release_path do
          execute :rake, "warehouse:db:schema:conditional_load RAILS_ENV=#{fetch(:rails_env)}"
        end
      end
    end
    before :migrating, :load_health_schema do
      on roles(:db)  do
        within release_path do
          execute :rake, "health:db:schema:conditional_load RAILS_ENV=#{fetch(:rails_env)}"
        end
      end
    end
    before :migrating, :load_reporting_schema do
      on roles(:db)  do
        within release_path do
          execute :rake, "reporting:db:schema:conditional_load RAILS_ENV=#{fetch(:rails_env)}"
        end
      end
    end
  end
  ##############################################################
  # END Bootstrap database structure the first time you deploy #
  ##############################################################

  after :migrating, :warehouse_migrations do
    on roles(:db)  do
      within release_path do
        execute :rake, "db:migrate:warehouse RAILS_ENV=#{fetch(:rails_env)}"
      end
    end
  end
  after :migrating, :health_migrations do
    on roles(:db)  do
      within release_path do
        execute :rake, "db:migrate:health RAILS_ENV=#{fetch(:rails_env)}"
      end
    end
  end
  after :migrating, :reporting_migrations do
    on roles(:db)  do
      within release_path do
        execute :rake, "db:migrate:reporting RAILS_ENV=#{fetch(:rails_env)}"
      end
    end
  end
  after :migrating, :report_seeds do
    on roles(:db)  do
      within release_path do
        execute :rake, "reports:seed RAILS_ENV=#{fetch(:rails_env)}"
      end
    end
  end
  after :report_seeds, :regular_seeds do
    on roles(:db)  do
      within release_path do
        execute :rake, "db:seed RAILS_ENV=#{fetch(:rails_env)}"
      end
    end
  end
  before :restart, :translations do
    on roles(:db)  do
      within release_path do
        execute :rake, "gettext:sync_to_po_and_db RAILS_ENV=#{fetch(:rails_env)}"
      end
    end
  end
end

before 'deploy:assets:precompile', :npm_install

namespace :deploy do
  before 'assets:precompile', :touch_theme_variables do
    on roles(:app)  do
      within shared_path do
        # must exist for asset-precompile to succeed.
        execute :touch, 'app/assets/stylesheets/theme/styles/_variables.scss'
      end
    end
  end
end

after 'deploy:migrating', :check_for_bootability do
  on roles(:app)  do
    within release_path do
      execute :bundle, :exec, :rails, :runner, '-e', fetch(:rails_env), "User.count"
    end
  end
end

task :echo_options do
  puts "\nDid you run ssh-add before running?\n\n"
  puts "Deploying as: #{fetch(:deploy_user)} on port: #{fetch(:ssh_port)} to location: #{deploy_to}\n\n"
end
after 'git:wrapper', :echo_options

task :trigger_job_restarts do
  on roles(:app) do
    within release_path do
      # Major ruby version upgrades might need a full cache clear:
      # execute :bundle, :exec, :rails, :runner, '-e', fetch(:rails_env), "\"Rails.cache.clear\""

      execute :bundle, :exec, :rails, :runner, '-e', fetch(:rails_env), "\"Rails.cache.write('deploy-dir', Delayed::Worker::Deployment.deployed_to)\""
    end
  end
end
after 'deploy:symlink:release', :trigger_job_restarts


task :clean_bootsnap_cache do
  on roles(:app, :util, :cron, :web) do
    within shared_path do
      execute 'du', '-ms', 'tmp/cache/bootsnap-compile-cache'
      execute 'find', 'tmp/cache/bootsnap-compile-cache', '-name', '"*"', '-type', 'f', '-mtime', '+7', '-exec', 'rm', '{}', '\;'
      execute 'du', '-ms', 'tmp/cache/bootsnap-compile-cache'
    end
  end
end
after 'deploy:symlink:release', :clean_bootsnap_cache

if ENV['RELOAD_NGINX']=='true'
  task :reload_nginx do
    on roles(:web) do
      within release_path do
        sudo "#{fetch(:systemctl_path)}", "reload", 'nginx'
      end
    end
  end
  after 'passenger:restart', :reload_nginx
end

# set this variable on your first deployments to each environment.
# remove these lines after all servers are deployed.
# e.g.
#      MANUAL_SYSTEMD_RESTART=true cap aws_staging deploy
if ENV['MANUAL_SYSTEMD_RESTART']=='true'
  after 'deploy:symlink:release', 'delayed_job:restart'
end
