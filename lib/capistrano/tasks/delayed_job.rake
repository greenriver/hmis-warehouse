# Do not use capistrano-delayed job gem as it's not needed.

namespace :delayed_job do
  task :restart do
    on roles(:job) do
      raise fetch(:delayed_job_systemd)
      execute :sudo, "systemctl restart delayed_job-#{fetch(:client)}-hmis-#{fetch(:rails_env)}.service"
    end
  end

  task :stop do
    on roles(:job) do
      execute :sudo, "systemctl stop delayed_job-#{fetch(:client)}-hmis-#{fetch(:rails_env)}.service"
    end
  end

  task :start do
    on roles(:job) do
      execute :sudo, "systemctl start delayed_job-#{fetch(:client)}-hmis-#{fetch(:rails_env)}.service"
    end
  end
end

