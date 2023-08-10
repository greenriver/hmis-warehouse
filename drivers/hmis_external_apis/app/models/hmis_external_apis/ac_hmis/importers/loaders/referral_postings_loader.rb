###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis::Importers::Loaders
  class ReferralPostingsLoader < BaseLoader
    # @param rows [Array<Hash>]
    def perform(posting_rows:, household_member_rows:, clobber: false)
      records = build_records(posting_rows)
      # destroy existing records and re-import
      model_class.where(data_source: data_source).destroy_all if clobber
      model_class.import(records, validate: false, recursive: true, batch_size: 1_000)
    end

    protected

    def model_class
      HmisExternalApis::AcHmis::Referral
    end

    def build_records(posting_rows:, household_member_rows:)
      # {[personal_id, project_id] => enrollment_id}
      ids_by_personal_id = Hmis::Hud::Enrollment
        .where(data_source: data_source)
        .pluck(:personal_id, :project_id, :id)
        .to_h {|personal_id, project_id, id| [[personal_id, project_id], id]}

      project_ids_by_referral_id = {}
      posting_rows.each do |row|
        referral_id = row_value(row, field: 'REFERRAL_ID')
        project_id = row_value(row, field: 'PROGRAM_ID')
        project_ids_by_referral_id[referral_id] = project_id
      end

      enrollment_ids_by_referral_id = {}
      household_member_rows.map do |row|
        project_id = project_ids_by_referral_id.fetch(row_value(row, field: 'REFERRAL_ID')])
        mci_id = row_value(row, field: 'MCI_ID')
        # MCI ID is PersonalID
        enrollment_ids_by_referral_id[referral_id] = ids_by_personal_id.fetch([mci_id, project_id])
      end

      posting_rows.map do |row|
        referral_id = row_value(row, field: 'REFERRAL_ID')
        enrollment_id = enrollment_ids_by_referral_id[referral_id]

        {
          identifier: referral_id,
          referral_date: row_value(row, field: 'REFERRAL_DATE'),
          service_coordinator: row_value(row, field: : row_value(row, field: 'SERVICE_COORDINATOR'),
          referral_notes: row_value(row, field: : row_value(row, field: 'REFERRAL_NOTES'),
          chronic: row_value(row, field: : row_value(row, field: 'CHRONIC'),
          score: row_value(row, field: : row_value(row, field: 'SCORE'),
          needs_wheelchair_accessible_unit: row_value(row, field: : row_value(row, field: 'NEEDS_WHEELCHAIR_ACCESSIBLE_UNIT'),
          enrollment_id: enrollment_id,
        }

         # POSTING_ID
         # STATUS
         # PROGRAM_ID
         # UNIT_TYPE_ID
         # ASSIGNED_AT
         # STATUS_UPDATED_AT
         # RESOURCE_COORDINATOR_NOTES
         # STATUS_NOTE/DENIAL_NOTE
         # DENIAL_REASON
         # REFERRAL_RESULT
      end
    end

    # file = 'ReferralPostings.csv'
    # col_map = [
    #  ["identifier", 'postingId']
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
    # ]
    # rows = records_from_csv(file).map do |csv_row|
    #  attrs = {}
    #  col_map.each do |attr, csv_col|
    #    attrs[attr] = csv_row.fetch(csv_col)
    #  end
    #  #
    #  # map status
    #  # map referral_id
    #  # map unit_type
    #  attrs
    # end

    # columns_to_update = rows.first.keys - ['identifier']
    # klass = Hmis::Hud::CustomService
    # result = class.import!(
    #  records,
    #  validate: false,
    #  batch_size: 1_000,
    #  on_duplicate_key_update: {
    #    conflict_target: 'identifier',
    #    columns: columns_to_update,
    #  },
    # )
  end
end
