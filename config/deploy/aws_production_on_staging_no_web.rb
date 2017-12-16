set :deploy_to, "/var/www/#{fetch(:client)}-hmis-production-temp"
set :rails_env, 'production'
ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Delayed Job
set :delayed_job_prefix, "#{ENV['CLIENT']}-hmis-production-temp"
set :delayed_job_pools, { low_priority: 4, default_priority: 1, high_priority: 1, nil => 1}

server ENV['STAGING_HOST'], user: 'ubuntu', roles: %w{app job}

set :linked_dirs, fetch(:linked_dirs, []).push('certificates', 'key', '.well_known', 'challenge')

set :linked_files, fetch(:linked_files, []).push('config/letsencrypt_plugin.yml', 'app/mail_interceptors/sandbox_email_interceptor.rb')

namespace :deploy do
  
end
