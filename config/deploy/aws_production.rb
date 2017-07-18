set :deploy_to, "/var/www/#{fetch(:client, 'boston')}-hmis-production"
set :rails_env, "production"

raise "You must specify DEPLOY_USER" if ENV['DEPLOY_USER'].to_s == ''

# Delayed Job
set :delayed_job_workers, 4
set :delayed_job_prefix, 'hmis'
set :delayed_job_roles, [:job]

# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp
set :branch, 'master'

puts "Allowable hosts: #{ENV['HOSTS']}"
puts "Hosts specified for deployment: #{ENV['HOST1']} #{ENV['HOST2']} #{ENV['HOST3']}"

server ENV['HOST1'], user: ENV['DEPLOY_USER'], roles: %w{app db web}
server ENV['HOST2'], user: ENV['DEPLOY_USER'], roles: %w{app web job}
server ENV['HOST3'], user: ENV['DEPLOY_USER'], roles: %w{app web}

set :linked_dirs, fetch(:linked_dirs, []).push('certificates', 'key', '.well_known', 'challenge')
set :linked_files, fetch(:linked_files, []).push('config/letsencrypt_plugin.yml')

namespace :deploy do
  after :updated, :warehouse_migrations do
    on roles(:db)  do
      within release_path do
        execute :rake, 'warehouse:db:migrate RAILS_ENV=production'
      end
    end
  end
  after :updated, :health_migrations do
    on roles(:db)  do
      within release_path do
        execute :rake, 'health:db:migrate RAILS_ENV=production'
      end
    end
  end
  after :updated, :report_seeds do
    on roles(:db)  do
      within release_path do
        execute :rake, 'reports:seed RAILS_ENV=production'
      end
    end
  end
  before :published, :translations do
    on roles(:db)  do
      within release_path do
        execute :rake, 'gettext:sync_to_po_and_db RAILS_ENV=production'
      end
    end
  end
end 
