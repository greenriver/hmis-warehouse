###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwenty::HmisCsvCleanup
  class ForceValidEnrollmentCoc < Base
    def cleanup!
      enrollment_coc_batch = []

      enrollment_coc_scope.find_each do |e_coc|
        # ignore any valid CoC-codes
        next if ::HUD.valid_coc?(e_coc.CoCCode)

        # add a dash if we have two characters and 3 numbers
        e_coc.CoCCode = "#{e_coc.CoCCode[0..1]}-#{e_coc.CoCCode[2..4]}" if e_coc.CoCCode.match?(/^[a-z]{2}[0-9]{3}$/i)

        # upcase any that match the format but aren't correctly cased
        e_coc.CoCCode.upcase! if e_coc.CoCCode.match?(/^[a-z]{2}-[0-9]{3}$/i)

        # double check the resulting code is valid, blank it if not
        e_coc.CoCCode = nil if e_coc.CoCCode.present? && ! ::HUD.valid_coc?(e_coc.CoCCode)

        e_coc.set_source_hash
        enrollment_coc_batch << e_coc
      end

      enrollment_coc_source.import(
        enrollment_coc_batch,
        on_duplicate_key_update: {
          conflict_target: [:id],
          columns: [:CoCCode, :source_hash],
        },
      )
    end

    def enrollment_coc_scope
      enrollment_coc_source.
        where(importer_log_id: @importer_log.id).
        where.not(CoCCode: nil)
    end

    def enrollment_coc_source
      HmisCsvTwentyTwenty::Importer::EnrollmentCoc
    end

    def self.description
      'Fix Enrollment.CoCCode where possible, remove where not.'
    end

    def self.enable
      {
        import_cleanups: {
          'EnrollmentCoc': ['HmisCsvTwentyTwenty::HmisCsvCleanup::ForceValidEnrollmentCoc'],
        },
      }
    end
  end
end
