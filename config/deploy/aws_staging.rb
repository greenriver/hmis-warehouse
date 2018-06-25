set :deploy_to, "/var/www/#{fetch(:client)}-hmis-staging"
set :rails_env, 'staging'
ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Delayed Job
set :delayed_job_pools, { low_priority: 2, default_priority: 1, high_priority: 1, nil => 1}

server ENV['STAGING_HOST'], user: fetch(:deploy_user), roles: %w{app db web job cron}, port: fetch(:ssh_port)

set :linked_dirs, fetch(:linked_dirs, []).push('certificates', 'key', '.well_known', 'challenge')

set :linked_files, fetch(:linked_files, []).push('config/letsencrypt_plugin.yml')

namespace :deploy do
  after :updated, :warehouse_migrations do
    on roles(:db)  do
      within release_path do
        execute :rake, 'warehouse:db:migrate RAILS_ENV=staging'
      end
    end
  end
  after :updated, :health_migrations do
    on roles(:db)  do
      within release_path do
        execute :rake, 'health:db:migrate RAILS_ENV=staging'
      end
    end
  end
  after :updated, :report_seeds do
    on roles(:db)  do
      within release_path do
        execute :rake, 'reports:seed RAILS_ENV=staging'
      end
    end
  end
  before :restart, :translations do
    on roles(:db)  do
      within release_path do
        execute :rake, 'gettext:sync_to_po_and_db RAILS_ENV=staging'
      end
    end
  end
end
