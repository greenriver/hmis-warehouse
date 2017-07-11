client = ENV.fetch('CLIENT') { 'boston' }

set :deploy_to, "/var/www/#{client}-hmis-staging"
set :rails_env, 'staging'
ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Delayed Job
set :delayed_job_workers, 2
set :delayed_job_prefix, 'hmis'
set :delayed_job_roles, [:job]

server ENV['STAGING_HOST'], user: 'ubuntu', roles: %w{app db web job}

set :linked_dirs, fetch(:linked_dirs, []).push('certificates', 'key', '.well_known', 'challenge')

set :linked_files, fetch(:linked_files, []).push('config/letsencrypt_plugin.yml', 'app/mail_interceptors/sandbox_email_interceptor.rb')

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
  before :published, :translations do
    on roles(:db)  do
      within release_path do
        execute :rake, 'gettext:sync_to_po_and_db RAILS_ENV=staging'
      end
    end
  end
end
