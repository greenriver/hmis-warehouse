# frozen_string_literal: true

namespace :site do
  task :down do
    on roles(:web) do
      execute "ln -nfs #{fetch(:deploy_to)}/current/public/maintenance_503.html #{fetch(:deploy_to)}/current/public/maintenance_on.html"
    end
  end

  task :up do
    on roles(:web) do
      execute "rm -f #{fetch(:deploy_to)}/current/public/maintenance_on.html"
    end
  end
end
