set :deploy_to, "/var/www/#{fetch(:client)}-hmis-staging"
set :rails_env, 'staging'
ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Delayed Job
set :delayed_job_pools, { low_priority: 2, default_priority: 1, high_priority: 1, nil => 1}

server ENV['STAGING_HOST'], user: fetch(:deploy_user), roles: %w{app db web job cron}, port: fetch(:ssh_port)

set :linked_dirs, fetch(:linked_dirs, []).push('certificates', 'key', '.well_known', 'challenge')

set :linked_files, fetch(:linked_files, []).push('config/letsencrypt_plugin.yml')
