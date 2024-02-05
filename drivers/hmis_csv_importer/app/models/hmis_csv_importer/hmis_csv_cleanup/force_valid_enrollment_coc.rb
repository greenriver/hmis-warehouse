###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvImporter::HmisCsvCleanup
  class ForceValidEnrollmentCoc < Base
    def cleanup!
      enrollment_batch = []

      enrollment_scope.find_each do |enrollment|
        # ignore any valid CoC-codes
        next if ::HudUtility2024.valid_coc?(enrollment.EnrollmentCoC)

        # add a dash if we have two characters and 3 numbers
        enrollment.EnrollmentCoC = "#{enrollment.EnrollmentCoC[0..1]}-#{enrollment.EnrollmentCoC[2..4]}" if enrollment.EnrollmentCoC.match?(/^[a-z]{2}[0-9]{3}$/i)

        # upcase any that match the format but aren't correctly cased
        enrollment.EnrollmentCoC.upcase! if enrollment.EnrollmentCoC.match?(/^[a-z]{2}-[0-9]{3}$/i)

        # double check the resulting code is valid, blank it if not
        enrollment.EnrollmentCoC = nil if enrollment.EnrollmentCoC.present? && ! ::HudUtility2024.valid_coc?(enrollment.EnrollmentCoC)

        enrollment.set_source_hash
        enrollment_batch << enrollment
      end

      enrollment_source.import(
        enrollment_batch,
        on_duplicate_key_update: {
          conflict_target: conflict_target(enrollment_source),
          columns: [:EnrollmentCoC, :source_hash],
        },
      )
    end

    def enrollment_scope
      enrollment_source.
        where(importer_log_id: @importer_log.id).
        where.not(EnrollmentCoC: nil)
    end

    def enrollment_source
      importable_file_class('Enrollment')
    end

    def self.description
      'Fix Enrollment.EnrollmentCoC where possible, remove where not.'
    end

    def self.enable
      {
        import_cleanups: {
          'Enrollment': ['HmisCsvImporter::HmisCsvCleanup::ForceValidEnrollmentCoc'],
        },
      }
    end
  end
end
