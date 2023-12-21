class MoveEnrollmentCoCCleanupToEnrollment < ActiveRecord::Migration[6.1]
  def up
    GrdaWarehouse::DataSource.where.not(import_cleanups: {}).each do |ds|
      cleanups = ds.import_cleanups
      next unless cleanups.key?('EnrollmentCoc')

      # Remove any EnrollmentCoC cleanups, they are no longer valid
      cleanups.delete('EnrollmentCoc')
      # Ensure we have an Enrollment cleanup
      cleanups['Enrollment'] ||= []
      # add ForceValidEnrollmentCoc (moving it from EnrollmentCoC to Enrollment)
      cleanups['Enrollment'] << 'HmisCsvImporter::HmisCsvCleanup::ForceValidEnrollmentCoc'

      ds.import_cleanups = cleanups
      ds.save!
    end
  end
end
