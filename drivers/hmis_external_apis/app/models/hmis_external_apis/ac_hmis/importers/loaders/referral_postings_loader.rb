###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis::Importers::Loaders
  class ReferralPostingsLoader < BaseLoader

    # referrals and referral postings
    def import_referral_postings
      raise "tbd"

      file = 'ReferralPostings.csv'
      col_map = [
        ["identifier", 'postingId']
        # ["status", 'postingStatusId'], # fixme enum
        # ["referral_id", ], #fixme needs lookup
        # ["project_id"], mapping
        # "referral_request_id",
        # "unit_type_id",
        # "HouseholdID",
        # "resource_coordinator_notes",
        # "status_updated_at",
        # "status_updated_by_id",
        # "status_note",
        # "status_note_updated_by_id",
        # "denial_reason",
        # "referral_result",
        # "denial_note",
        # "status_note_updated_at",
        # "data_source_id"
      ]
      rows = records_from_csv(file).map do |csv_row|
        attrs = {}
        col_map.each do |attr, csv_col|
          attrs[attr] = csv_row.fetch(csv_col)
        end
        #
        # map status
        # map referral_id
        # map unit_type
        attrs
      end

      columns_to_update = rows.first.keys - ['identifier']
      klass = Hmis::Hud::CustomService
      result = lass.import!(
        records,
        validate: false,
        batch_size: 1_000,
        on_duplicate_key_update: {
          conflict_target: 'identifier',
          columns: columns_to_update,
        },
      )
    end

    def import_referral_household_members
      raise "tbd"
      file = 'ReferralHouseholdMembers.csv'
    end

  end
end
