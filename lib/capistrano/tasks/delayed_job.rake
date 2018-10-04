# Do not use capistrano-delayed job gem as it's not needed.

namespace :delayed_job do
  task :restart do
    on roles(:job) do
      execute :sudo, "bash -l -c 'systemctl stop delayed_job-#{fetch(:client)}-hmis-#{fetch(:rails_env)}.1.service || echo ok'"
      execute :sudo, "bash -l -c 'systemctl stop delayed_job-#{fetch(:client)}-hmis-#{fetch(:rails_env)}.2.service || echo ok'"
      execute :sudo, "bash -l -c 'systemctl stop delayed_job-#{fetch(:client)}-hmis-#{fetch(:rails_env)}.3.service || echo ok'"

      execute :sudo, "systemctl start delayed_job-#{fetch(:client)}-hmis-#{fetch(:rails_env)}.1.service"
      execute :sudo, "systemctl start delayed_job-#{fetch(:client)}-hmis-#{fetch(:rails_env)}.2.service"
      execute :sudo, "systemctl start delayed_job-#{fetch(:client)}-hmis-#{fetch(:rails_env)}.3.service"
    end
  end

  task :stop do
    on roles(:job) do
      execute :sudo, "systemctl stop delayed_job-#{fetch(:client)}-hmis-#{fetch(:rails_env)}.1.service"
      execute :sudo, "systemctl stop delayed_job-#{fetch(:client)}-hmis-#{fetch(:rails_env)}.2.service"
      execute :sudo, "systemctl stop delayed_job-#{fetch(:client)}-hmis-#{fetch(:rails_env)}.3.service"
    end
  end

  task :start do
    on roles(:job) do
      execute :sudo, "systemctl start delayed_job-#{fetch(:client)}-hmis-#{fetch(:rails_env)}.1.service"
      execute :sudo, "systemctl start delayed_job-#{fetch(:client)}-hmis-#{fetch(:rails_env)}.2.service"
      execute :sudo, "systemctl start delayed_job-#{fetch(:client)}-hmis-#{fetch(:rails_env)}.3.service"
    end
  end
end
