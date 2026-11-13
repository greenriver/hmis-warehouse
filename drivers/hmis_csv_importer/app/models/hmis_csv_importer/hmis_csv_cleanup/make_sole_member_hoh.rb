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
      if HmisCsvImporter::HmisCsvCleanup::EnforceRelationshipToHoh.checked?(@importer_log.data_source)
        Rails.logger.info 'Skipping MakeSoleMemberHoh; EnforceRelationshipToHoh already covers one-person households'
        return
      end

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
      'When a household has exactly one member, set RelationshipToHoH to 1. Does not change multi-member households. Unnecessary if "Enforce only one Head of Household per household" is already enabled.'
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
