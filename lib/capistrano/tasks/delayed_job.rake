# Do not use capistrano-delayed job gem as it's not needed.

namespace :delayed_job do
  task :restart do
    on roles(:job) do
      if ENV['DELAYED_JOB_SYSTEMD']=='true'
        execute :sudo, "systemctl restart delayed_job-#{fetch(:client)}-hmis-#{fetch(:rails_env)}.service"
      end
    end
  end

  task :stop do
    on roles(:job) do
      if ENV['DELAYED_JOB_SYSTEMD']=='true'
        execute :sudo, "systemctl stop delayed_job-#{fetch(:client)}-hmis-#{fetch(:rails_env)}.service"
      end
    end
  end

  task :start do
    on roles(:job) do
      if ENV['DELAYED_JOB_SYSTEMD']=='true'
        execute :sudo, "systemctl start delayed_job-#{fetch(:client)}-hmis-#{fetch(:rails_env)}.service"
      end
    end
  end
end

