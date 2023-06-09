namespace :import do
  task remote_data: [
    'driver:hmis_external_apis:import:ac_projects',
    'eto:import:demographics_and_touch_points',
  ]

  # ./bin/rake driver:hmis_external_apis:import:ac_projects
  desc 'Import AC project data'
  task :ac_projects, [] => [:environment] do
    HmisExternalApis::AcHmis::ImportProjectsJob.perform_now
  end
end
