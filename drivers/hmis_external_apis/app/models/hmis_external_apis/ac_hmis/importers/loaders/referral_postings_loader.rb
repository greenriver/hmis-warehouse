###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis::Importers::Loaders
  class ReferralPostingsLoader < BaseLoader
    # @param reader [CsvReader]
    # @param clobber [Boolean] destroy existing records?
    def perform(reader:, clobber: false)
      self.reader = reader
      init_enrollment_ids_by_referral_id
      records = build_referral_records
      # destroy existing records and re-import
      model_class.where(data_source: data_source).destroy_all if clobber
      model_class.import(records, validate: false, recursive: true, batch_size: 1_000)
    end

    POSTINGS_FILENAME = 'ReferralPostings.csv'
    HOUSEHOLD_MEMBERS_FILENAME = 'ReferralHouseholdMembers.csv'

    def data_file_provided?
      reader.file_present?(POSTINGS_FILENAME) &&
      reader.file_present?(HOUSEHOLD_MEMBERS_FILENAME)
    end

    def table_names
      [
        HmisExternalApis::AcHmis::ReferralHouseholdMember.table_name,
        HmisExternalApis::AcHmis::ReferralPosting.table_name,
      ]
    end

    protected

    def posting_rows
      reader.rows(POSTINGS_FILENAME)
    end

    def household_member_rows
      reader.rows(HOUSEHOLD_MEMBERS_FILENAME)
    end

    def model_class
      HmisExternalApis::AcHmis::Referral
    end

    def build_referral_records
      household_member_rows_by_referral = household_member_rows.group_by { |row| row_value(row, field: 'REFERRAL_ID') }
      posting_rows.map do |row|
        referral_id = row_value(row, field: 'REFERRAL_ID')
        household_members = build_household_member_records(household_member_rows_by_referral[referral_id] || [])
        postings = build_posting_records([row])

        model_class.new(
          identifier: referral_id,
          enrollment_id: referral_enrollment_id(referral_id),
          referral_date: parse_date(row_value(row, field: 'REFERRAL_DATE')),
          service_coordinator: row_value(row, field: 'SERVICE_COORDINATOR'),
          referral_notes: row_value(row, field: 'REFERRAL_NOTES'),
          chronic: yn_boolean(row_value(row, field: 'CHRONIC')),
          score: row_value(row, field: 'SCORE'),
          needs_wheelchair_accessible_unit: yn_boolean(row_value(row, field: 'NEEDS_WHEELCHAIR_ACCESSIBLE_UNIT')),
          household_members: household_members,
          postings: postings,
        )
      end
    end

    def yn_boolean(str)
      str ? str.downcase == 'yes' : nil
    end

    def referral_household_id(referral_id)
      @enrollment_ids_by_referral_id.fetch(referral_id)[1]
    end

    def referral_enrollment_id(referral_id)
      @enrollment_ids_by_referral_id.fetch(referral_id)[0]
    end

    # we don't have enrolment id on the referrals csv so we have to infer it
    # from the referral.project_id and MCI ID on household member.
    # Assumes the MCI ID is the PersonalID
    def init_enrollment_ids_by_referral_id
      # {[personal_id, project_id] => [enrollment_id, household_id]}
      ids_by_personal_id_project_id = Hmis::Hud::Enrollment
        .where(data_source: data_source)
        .pluck(:personal_id, :project_id, :id, :household_id)
        .to_h { |personal_id, project_id, id, household_id| [[personal_id, project_id], [id, household_id]] }

      project_ids_by_referral_id = posting_rows.map do |row|
        referral_id = row_value(row, field: 'REFERRAL_ID')
        project_id = row_value(row, field: 'PROGRAM_ID')
        [referral_id, project_id]
      end.to_h

      @enrollment_ids_by_referral_id = household_member_rows.map do |row|
        mci_id = row_value(row, field: 'MCI_ID')
        referral_id = row_value(row, field: 'REFERRAL_ID')
        project_id = project_ids_by_referral_id.fetch(referral_id)
        [referral_id, ids_by_personal_id_project_id.fetch([mci_id, project_id])]
      end.to_h
    end

    def build_household_member_records(rows)
      client_ids_by_mci_id = Hmis::Hud::Client
        .where(data_source: data_source)
        .pluck(:personal_id, :id)
        .to_h

      record_class = HmisExternalApis::AcHmis::ReferralHouseholdMember
      rows.map do |row|
        mci_id = row_value(row, field: 'MCI_ID')
        record_class.new(
          relationship_to_hoh: relationship_to_hoh(row),
          mci_id: mci_id,
          client_id: client_ids_by_mci_id.fetch(mci_id),
        )
      end
    end

    HOH_MAP = {
      'Self' => 'self_head_of_household',
      'Aunt' => 'other_relative',
      'Brother' => 'other_relative',
      'Cousin' => 'other_relative',
      'Grandchild' => 'other_relative',
      'Grandparent' => 'other_relative',
      'Nephew' => 'other_relative',
      'Niece' => 'other_relative',
      'Parent' => 'other_relative',
      'Sister' => 'other_relative',
      'Daughter' => 'child',
      'Son' => 'child',
      'Spouse/Partner' => 'spouse_or_partner',
      'Uncle' => 'other_relative',
      'Friend' => 'unrelated_household_member',
      'Live-In Aide' => 'unrelated_household_member',
    }.freeze
    def relationship_to_hoh(row)
      value = row_value(row, field: 'RELATIONSHIP_TO_HOH')
      HOH_MAP.fetch(value)
    end

    def build_posting_records(rows)
      record_class = HmisExternalApis::AcHmis::ReferralPosting
      projects_by_project_id = Hmis::Hud::Project
        .where(data_source: data_source)
        .pluck(:project_id, :id)
        .to_h
      unit_types_by_mper = Hmis::UnitType
        .joins(:mper_id)
        .pluck('external_ids.value', :id)
        .to_h
      rows.map do |row|
        record = record_class.new(
          data_source_id: data_source.id,
          identifier: row_value(row, field: 'POSTING_ID'),
          status: posting_status(row),
          project_id: projects_by_project_id.fetch(row_value(row, field: 'PROGRAM_ID')),
          unit_type_id: unit_types_by_mper.fetch(row_value(row, field: 'UNIT_TYPE_ID')),
          resource_coordinator_notes: row_value(row, field: 'RESOURCE_COORDINATOR_NOTES'),
          referral_result: row_value(row, field: 'REFERRAL_RESULT'),
          status_updated_at: parse_date(row_value(row, field: 'ASSIGNED_AT') || row_value(row, field: 'STATUS_UPDATED_AT')),
          HouseholdID: referral_household_id(row_value(row, field: 'REFERRAL_ID')),
          # fields not used in CSV
          # referral_result: row_value(row, field: 'REFERRAL_RESULT'),
          # denial_reason: row_value(row, field: 'DENIAL_REASON'),
          # denial_note:  row_value(row, field: 'STATUS_NOTE/DENIAL_NOTE'),
        )
        record
      end
    end

    def posting_status(row)
      value = row_value(row, field: 'STATUS')
      return unless value

      value = value.downcase.gsub(' ', '_') + '_status'
      HmisExternalApis::AcHmis::ReferralPosting.statuses.fetch(value)
    end
  end
end
