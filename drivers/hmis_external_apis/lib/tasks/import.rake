namespace :import do
  # ./bin/rake driver:hmis_external_apis:import:ac_projects
  desc 'Import AC project data'
  task :ac_projects, [] => [:environment] do
    HmisExternalApis::AcHmis::ImportProjectsJob.perform_now
  end

  desc 'Import AC Custom Data Elements'
  task :ac_custom_data_elements, [:clobber] => [:environment] do |_task, args|
    HmisExternalApis::AcHmis::ImportCustomDataElementsJob.perform_now(clobber: args.clobber)
  end
end
