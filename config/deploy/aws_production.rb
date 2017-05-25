set :deploy_to, '/var/www/boston-hmis-production'
set :rails_env, "production"

raise "You must specify DEPLOY_USER" if ENV['DEPLOY_USER'].to_s == ''

# Delayed Job
set :delayed_job_workers, 4
set :delayed_job_prefix, 'hmis'
set :delayed_job_roles, [:job]

# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp
set :branch, 'master'

puts "Allowable hosts: #{ENV['HOSTS']}"
puts "Hosts specified for deployment: #{ENV['HOST1']} #{ENV['HOST2']}"

server ENV['HOST1'], user: ENV['DEPLOY_USER'], roles: %w{app db web}
server ENV['HOST2'], user: ENV['DEPLOY_USER'], roles: %w{app web job}

set :linked_dirs, fetch(:linked_dirs, []).push('certificates', 'key', '.well_known', 'challenge')
set :linked_files, fetch(:linked_files, []).push('config/letsencrypt_plugin.yml')

namespace :deploy do
  before :finishing, :warehouse_migrations do
    on roles(:db)  do
      within current_path do
        execute :rake, 'grda_warehouse:migrate RAILS_ENV=production'
      end
    end
  end
  before :finishing, :report_seeds do
    on roles(:db)  do
      within current_path do
        execute :rake, 'reports:seed RAILS_ENV=production'
      end
    end
  end
end 
