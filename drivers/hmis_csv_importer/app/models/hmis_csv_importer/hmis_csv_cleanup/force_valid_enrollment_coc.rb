###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvImporter::HmisCsvCleanup
  class ForceValidEnrollmentCoc < Base
    def cleanup!
      enrollment_coc_batch = []

      enrollment_coc_scope.find_each do |e_coc|
        # ignore any valid CoC-codes
        next if ::HudUtility2024.valid_coc?(e_coc.EnrollmentCoC)

        # add a dash if we have two characters and 3 numbers
        e_coc.EnrollmentCoC = "#{e_coc.EnrollmentCoC[0..1]}-#{e_coc.EnrollmentCoC[2..4]}" if e_coc.EnrollmentCoC.match?(/^[a-z]{2}[0-9]{3}$/i)

        # upcase any that match the format but aren't correctly cased
        e_coc.EnrollmentCoC.upcase! if e_coc.EnrollmentCoC.match?(/^[a-z]{2}-[0-9]{3}$/i)

        # double check the resulting code is valid, blank it if not
        e_coc.EnrollmentCoC = nil if e_coc.EnrollmentCoC.present? && ! ::HudUtility2024.valid_coc?(e_coc.EnrollmentCoC)

        e_coc.set_source_hash
        enrollment_coc_batch << e_coc
      end

      enrollment_coc_source.import(
        enrollment_coc_batch,
        on_duplicate_key_update: {
          conflict_target: conflict_target(enrollment_coc_source),
          columns: [:EnrollmentCoC, :source_hash],
        },
      )
    end

    def enrollment_coc_scope
      enrollment_coc_source.
        where(importer_log_id: @importer_log.id).
        where.not(EnrollmentCoC: nil)
    end

    def enrollment_coc_source
      importable_file_class('Enrollment')
    end

    def self.description
      'Fix Enrollment.EnrollmentCoC where possible, remove where not.'
    end

    def self.enable
      {
        import_cleanups: {
          'EnrollmentCoc': ['HmisCsvImporter::HmisCsvCleanup::ForceValidEnrollmentCoc'],
        },
      }
    end
  end
end
