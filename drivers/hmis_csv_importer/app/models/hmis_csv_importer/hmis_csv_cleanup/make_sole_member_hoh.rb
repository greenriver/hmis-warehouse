###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvImporter::HmisCsvCleanup
  # Opt-in, off-by-default pre-ingest cleanup that makes the sole member of a household
  # the Head of Household. Only touches staging rows for the current importer_log.
  # Does not change HouseholdID, multi-member households, or blank HouseholdIDs.
  class MakeSoleMemberHoh < Base
    def cleanup!
      Hmis::Hud::DataIntegrity::SoleMemberHohFixer.run!(
        scope: enrollment_scope,
        conflict_target: conflict_target(enrollment_source),
      )
    end

    def enrollment_scope
      enrollment_source.where(importer_log_id: @importer_log.id)
    end

    def enrollment_source
      importable_file_class('Enrollment')
    end

    def self.description
      'Make the sole member of a household the Head of Household'
    end

    # Must run after FixBlankHouseholdIds (default 0) so newly assigned one-person households get HoH in the same import.
    def self.run_order
      10
    end

    def self.enable
      {
        import_cleanups: {
          'Enrollment': ['HmisCsvImporter::HmisCsvCleanup::MakeSoleMemberHoh'],
        },
      }
    end
  end
end
