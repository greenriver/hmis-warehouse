###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# This task copies data from records that are stored in the database but should have been
# stored in S3 and copies the data to S3.
# Usage looks like this:
# 1. Add a scope to your model `unprocessed_s3_migration` to identify which records have not been moved
# 2. Add a `has_one_attached` call to your model to hold your data in the ActiveStorage format
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
        GrdaWarehouse::AdHocBatch => :with_attached_batch_file,
        GrdaWarehouse::NonHmisUpload => :with_attached_upload_file,
        GrdaWarehouse::PublicFile => :with_attached_public_file,
        GrdaWarehouse::DashboardExportFile => :with_attached_dashboard_export_file,
        GrdaWarehouse::ReportResultFile => :with_attached_report_result_file,
        TxClientReports::ResearchExports::Export => :with_attached_research_export_file,
        Health::TransactionAcknowledgement => :with_attached_acknowledgement_file,

        # The following are classes that remain to be moved
        # GrdaWarehouse::DashboardExportFile => :with_attached_dashboard_export_file,
        # GrdaWarehouse::HealthEmergency::TestBatch => :with_attached_test_batch_file,
        # Health::EdIpVisitFile => :with_attached_ed_ip_visit_file,
        # Health::EligibilityResponse => :with_attached_eligibility_response_file,
        # Health::EnrollmentReasons => :with_attached_enrollment_reasons_file,
        # Health::Enrollment => :with_attached_enrollment_file,
        # Health::HealthFile => :with_attached_health_file,
        # Health::PremiumPayment => :with_attached_premium_payment_file,
        # Health::CpMembers::FileBase => :with_attached_member_file,

        # The following were previously moved, leaving here to make adding
        # future files easier.
        # GrdaWarehouse::SecureFile => :with_attached_secure_file,
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
