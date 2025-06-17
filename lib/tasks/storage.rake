###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# This task copies data from records that are stored in the database but should have been
# stored in S3 and copies the data to S3.
# Usage looks like this:
# 1. Add a scope to your model `unprocessed_s3_migration` to identify which records have not been moved
# 2. Add a `has_one_attached` call to your model to hold your date in the ActiveStorage format
# 3. Add a method `copy_to_s3!` to your model that will download the existing attachment and re-attach using ActiveStorage
# 4. Adjust your save and view routines to save the new attachment, and show the
#    new attachment if available, but fallback on the old
# 5. Add Your class name below
# 6. Deploy and wait.  This script runs once a day, depending on the table size, it may
#    take some time to move your files
# 7. Return once the files have been moved, and comment out your file name
# 8. If you want to be less careful, you can remove the content from the source
#    record in step 3, or if you want to be more careful, you can revisit after all
#    files have been moved and clear it out.

namespace :storage do
  desc 'Move files from the database to S3 and Active Storage'
  task :move_to_s3, [] => [:environment] do
    GrdaWarehouse::Tasks::TaskInstrumentation.call('storage:move_to_s3', alert_threshold: 36.hours) do |run|
      {
        GrdaWarehouse::HmisExport => :with_attached_hmis_zip,
        GrdaWarehouse::SecureFile => :with_attached_secure_file,

        # The following are classes that remain to be moved
        # GrdaWarehouse::AdHocBatch
        # GrdaWarehouse::DashboardExportFile
        # GrdaWarehouse::NonHmisUpload
        # GrdaWarehouse::PublicFile
        # GrdaWarehouse::ReportResultFile
        # GrdaWarehouse::HealthEmergency::TestBatch
        # Health::EdIpVisitFile
        # Health::EligibilityResponse
        # Health::EnrollmentReasons
        # Health::Enrollment
        # Health::HealthFile
        # Health::PremiumPayment
        # Health::TransactionAcknowledgement
        # Health::CpMembers::FileBase
        # TxClientReports::ResearchExports::Export      #

        # The following were previously moved, leaving here to make adding
        # future files easier.
        # GrdaWarehouse::Upload => :with_attached_hmis_zip,
        # GrdaWarehouse::ClientFile => :with_attached_client_file,
      }.each do |klass, preload|
        klass.unprocessed_s3_migration.send(preload).find_each(batch_size: 10, &:copy_to_s3!)
      end

      # Final cleanup
      # If you don't remove the content from the content field in `copy_to_s3!`
      # you can add the class below and it will null the content field.
      # NOTE: this is destructive, only add your class here after successfully
      # moving files to S3
      {
        GrdaWarehouse::Upload => :content,
        GrdaWarehouse::ClientFile => :content,
      }.each do |klass, content_field|
        klass.update_all(content_field => nil)
      end
      run.complete!
    end
  end
end
