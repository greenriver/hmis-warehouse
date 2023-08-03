namespace :export do
  # ./bin/rake driver:hmis_external_apis:export:ac_clients
  desc 'Export AC client data'
  task :ac_clients, [] => [:environment] do
    HmisExternalApis::AcHmis::UploadClientsJob.perform_now
  end
end
