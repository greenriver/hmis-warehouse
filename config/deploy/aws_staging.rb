set :deploy_to, '/var/www/boston-hmis-staging'
set :rails_env, "staging"

ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

server ENV['STAGING_HOST'], user: 'ubuntu', roles: %w{app web}

namespace :deploy do
  before :finishing, :warehouse_migrations do
    on roles(:db)  do
      within current_path do
        execute :rake, 'grda_warehouse:migrate RAILS_ENV=staging'
      end
    end
  end
  before :finishing, :report_seeds do
    on roles(:db)  do
      within current_path do
        execute :rake, 'reports:seed RAILS_ENV=staging'
      end
    end
  end
  before :finishing, :nginx_restart do
    on roles(:web) do
      execute :sudo, '/etc/init.d/nginx restart'
    end
  end
end 
