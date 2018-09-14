# config valid only for current version of Capistrano
lock '3.11.0'

set :application, 'boston_hmis'
set :repo_url, 'git@github.com:greenriver/hmis-warehouse.git'
set :client, ENV.fetch('CLIENT')

set :whenever_identifier, ->{ "#{fetch(:application)}_#{fetch(:stage)}" }
set :cron_user, ENV.fetch('CRON_USER') { 'ubuntu'}
set :whenever_roles, [:cron, :production_cron, :staging_cron]
set :whenever_command, -> { "bash -l -c 'cd #{fetch(:release_path)} && /usr/share/rvm/bin/rvmsudo ./bin/bundle exec whenever -u #{fetch(:cron_user)} --update-crontab #{fetch(:whenever_identifier)} --set \"environment=#{fetch(:rails_env)}\" '" }
set :passenger_restart_command, 'sudo passenger-config restart-app'

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

unless ENV['SKIP_JOBS']=='true'
  after 'passenger:restart', 'delayed_job:restart'
end

set :ssh_port, ENV.fetch('SSH_PORT') { '22' }
set :deploy_user , ENV.fetch('DEPLOY_USER')

set :rvm_custom_path, ENV.fetch('RVM_CUSTOM_PATH') { '/usr/share/rvm' }
set :rvm_ruby_version, "#{File.read('.ruby-version').strip.split('-')[1]}@global"

task :group_writable_and_owned_by_ubuntu do
  on roles(:web) do
    execute "sudo chmod --quiet g+w -R  #{fetch(:deploy_to)}"
    execute "sudo chown --quiet ubuntu:ubuntu -R #{fetch(:deploy_to)}"
  end
end
before 'passenger:restart',  :group_writable_and_owned_by_ubuntu
after 'deploy:log_revision', :group_writable_and_owned_by_ubuntu

# Default branch is :master
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
# set :pty, true

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
  after :migrating, :warehouse_migrations do
    on roles(:db)  do
      within release_path do
        execute :rake, "warehouse:db:migrate RAILS_ENV=#{fetch(:rails_env)}"
      end
    end
  end
  after :migrating, :health_migrations do
    on roles(:db)  do
      within release_path do
        execute :rake, "health:db:migrate RAILS_ENV=#{fetch(:rails_env)}"
      end
    end
  end
  after :migrating, :reporting_migrations do
    on roles(:db)  do
      within release_path do
        execute :rake, "reporting:db:migrate RAILS_ENV=#{fetch(:rails_env)}"
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
  before :restart, :translations do
    on roles(:db)  do
      within release_path do
        execute :rake, "gettext:sync_to_po_and_db RAILS_ENV=#{fetch(:rails_env)}"
      end
    end
  end
end

namespace :deploy do
  before 'assets:precompile', :touch_theme_variables do
    on roles(:app)  do
      within shared_path do
        # must exist for asset-precompile to succeed.
        execute :touch, 'app/assets/stylesheets/theme/styles/_variables.scss'
      end
    end
  end

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
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
