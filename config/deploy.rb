# config valid only for current version of Capistrano
lock '3.6.1'

set :application, 'boston_hmis'
set :repo_url, 'git@github.com:greenriver/hmis-warehouse.git'
set :client, ENV.fetch('CLIENT')

# Delayed Job
set :delayed_job_prefix, "#{ENV['CLIENT']}-hmis"
set :delayed_job_roles, [:job]

# see config/initializers/delayed_job
set :low_priority_priority, 5
set :low_priority_delayed_job_workers, 4
set :default_priority, 0
set :default_delayed_job_workers, 3
set :high_priority_priority, -5
set :high_priority_delayed_job_workers, 2

if !ENV['FORCE_SSH_KEY'].nil?
  set :ssh_options, {
    keys: [ENV['FORCE_SSH_KEY']]
  }
end

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
  '.env',
  'app/views/root/_homepage_content.haml'
)

# Default value for linked_dirs is []
set :linked_dirs, fetch(:linked_dirs, []).push(
  'log', 
  'tmp/pids', 
  'tmp/cache',
  'tmp/client_images',
  'public/system', 
  'tmp/sockets', 
  'var',
  'app/assets/stylesheets/theme/styles',
  'app/assets/images/theme/logo',
  'app/assets/images/theme/icons',
)

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

def run_dj_command(cmd, args)
  execution_string = "cd #{current_path} && RAILS_ENV=#{rails_env} bin/delayed_job -m --prefix #{delayed_job_prefix}"
  if args.include? :num
    execution_string += " -n #{args[:num]}"
  end
  if args.include? :min_p
    execution_string += " --min-priority #{args[:min_p]}"
  end
  if args.include? :max_p
    execution_string += " --max-priority #{args[:max_p]}"
  end
  if args.include? :queue
    execution_string += " --queue=#{args[:queue]} --pid-dir #{shared_path}/pids/worker-group-#{args[:queue]}"
  end
  if args.include? :pool
    execution_string += " --pool=#{args[:pool]}"
  end
  execution_string += " #{cmd}"
  run execution_string
end

namespace :delayed_job do

  desc "Start all low priority processes"
  task :start_low_priority do
    on roles(delayed_job_roles) do
      run_dj_command('start', {num: low_priority_delayed_job_workers, 
                               queue: :low_priority, 
                               min_p: low_priority_priority, 
                               max_p: low_priority_priority})
    end
  end

  desc "Stop all low priority processes"
  task :stop_low_priority do
    on roles(delayed_job_roles) do
      run_dj_command('stop', {num: low_priority_delayed_job_workers, 
                               queue: :low_priority, 
                               min_p: low_priority_priority, 
                               max_p: low_priority_priority})
    end
  end

  desc "Restart all low priority processes"
  task :restart_low_priority do
    on roles(delayed_job_roles) do
      stop_low_priority
      run 'sleep 2'
      start_low_priority
    end
  end

  desc "Start all high priority processes"
  task :start_high_priority do
    on roles(delayed_job_roles) do
      run_dj_command('start', {num: high_priority_delayed_job_workers, 
                               queue: :high_priority, 
                               min_p: high_priority_priority, 
                               max_p: high_priority_priority})
    end
  end

  desc "Stop all high priority processes"
  task :stop_high_priority do
    on roles(delayed_job_roles) do
      run_dj_command('stop', {num: high_priority_delayed_job_workers, 
                               queue: :high_priority, 
                               min_p: high_priority_priority, 
                               max_p: high_priority_priority})
    end
  end

  desc "Restart all high priority processes"
  task :restart_high_priority do
    on roles(delayed_job_roles) do
      stop_high_priority
      run 'sleep 2'
      start_high_priority
    end
  end

  desc "Start all default priority processes"
  task :start_default do
    on roles(delayed_job_roles) do
      run_dj_command('start', {num: default_delayed_job_workers, 
                               queue: :default, 
                               min_p: low_priority_priority - 1, 
                               max_p: high_priority_priority + 1})
    end
  end

  desc "Stop all default priority processes"
  task :stop_default do
    on roles(delayed_job_roles) do
      run_dj_command('stop', {num: default_delayed_job_workers, 
                               queue: :default, 
                               min_p: low_priority_priority - 1, 
                               max_p: high_priority_priority + 1})
    end
  end

  desc "Restart all non service_history processes"
  task :restart_default do
    on roles(delayed_job_roles) do
      stop_default
      run 'sleep 2'
      start_default
    end
  end

  desc "Start all delayed_job processes" 
  task :start_all do
    on roles(delayed_job_roles) do
      start_default
      start_low_priority
      start_high_priority
    end
  end

  desc "Stop all delayed_job processes" 
  task :stop_all do
    on roles(delayed_job_roles) do
      stop_default
      stop_low_priority
      stop_high_priority
    end
  end

  desc "Restart all delayed_job processes"
  task :restart_all do
    on roles(delayed_job_roles) do
      stop_all
      run 'sleep 2'
      start_all
    end
  end
end
after "deploy:started", "delayed_job:start_all" 
after "passenger:restart", "delayed_job:restart_all"


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
