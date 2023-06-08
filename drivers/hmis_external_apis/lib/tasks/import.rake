namespace :import do
  # ./bin/rake driver:hmis_external_apis:import:ac_projects
  desc 'Import AC project data'
  task :ac_projects, [] => [:environment] do
    if Rails.env.development?
      HmisExternalApis::AcHmis::ImportProjectsJob.perform_now
    else
      HmisExternalApis::AcHmis::ImportProjectsJob.perform_later
    end
  end
end
