namespace :storage do
  desc 'Move files from the database to S3 and Active Storage'
  task :move_to_s3, [] => [:environment] do
    {
      GrdaWarehouse::Upload => :with_attached_hmis_zip,
    }.each do |klass, preload|
      klass.unprocessed_s3_migration.send(preload).find_each(batch_size: 10, &:copy_to_s3!)
    end
  end
end
