###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis::Importers::Loaders
  class ReferralPostingsLoader < BaseLoader
    def perform
      init_enrollment_ids_by_referral_id
      referral_records, unit_occupancy_records = build_referral_records

      # destroy existing records and re-import
      if clobber
        referral_class.where(data_source: data_source).destroy_all
        enrollments = Hmis::Hud::Enrollment.where(data_source: data_source)
        Hmis::UnitOccupancy
          .where(enrollment_id: enrollments.select(:id))
          .destroy_all
      end
      referral_class.import(referral_records, validate: false, recursive: true, batch_size: 1_000)
      Hmis::UnitOccupancy.import(unit_occupancy_records, validate: false, batch_size: 1_000)
    end

    POSTINGS_FILENAME = 'ReferralPostings.csv'.freeze
    HOUSEHOLD_MEMBERS_FILENAME = 'ReferralHouseholdMembers.csv'.freeze

    def data_file_provided?
      reader.file_present?(POSTINGS_FILENAME) &&
      reader.file_present?(HOUSEHOLD_MEMBERS_FILENAME)
    end

    def table_names
      [
        HmisExternalApis::AcHmis::ReferralHouseholdMember.table_name,
        HmisExternalApis::AcHmis::ReferralPosting.table_name,
        Hmis::UnitOccupancy.table_name,
      ]
    end

    protected

    def posting_rows
      reader.rows(POSTINGS_FILENAME)
    end

    def household_member_rows
      reader.rows(HOUSEHOLD_MEMBERS_FILENAME)
    end

    def referral_class
      HmisExternalApis::AcHmis::Referral
    end

    def build_referral_records
      household_member_rows_by_referral = household_member_rows.group_by { |row| row_value(row, field: 'REFERRAL_ID') }
      referral_records = []
      unit_occupancy_records = []
      posting_rows.each do |row|
        referral_id = row_value(row, field: 'REFERRAL_ID')
        household_members = build_household_member_records(household_member_rows_by_referral[referral_id] || [])
        posting = build_posting_record(row)

        referral = referral_class.new(
          identifier: referral_id,
          enrollment_id: referral_enrollment_id(referral_id),
          referral_date: parse_date(row_value(row, field: 'REFERRAL_DATE')),
          service_coordinator: row_value(row, field: 'SERVICE_COORDINATOR'),
          referral_notes: row_value(row, field: 'REFERRAL_NOTES', required: false),
          chronic: yn_boolean(row_value(row, field: 'CHRONIC', required: false)),
          score: row_value(row, field: 'SCORE', required: false),
          needs_wheelchair_accessible_unit: yn_boolean(row_value(row, field: 'NEEDS_WHEELCHAIR_ACCESSIBLE_UNIT', required: false)),
          household_members: household_members,
          postings: [posting],
        )
        referral_records.push(referral)

        next unless posting.accepted_status? || posting.accepted_pending_status?

        ## infer unit occupancy
        occupancies = household_members.map do |hm|
          unit_id = project_unit_tracker.next_unit_id(
            enrollment_pk: referral.enrollment_id,
            unit_type_mper_id: row_value(row, field: 'UNIT_TYPE_ID'),
          )
          {
            unit_id: unit_id,
            enrollment_id: referral.enrollment_id,
          }
        end
        unit_occupancy_records += occupancies
      end
      [referral_records, unit_occupancy_records]
    end

    def referral_household_id(referral_id)
      @enrollment_ids_by_referral_id.fetch(referral_id)[1]
    end

    def referral_enrollment_id(referral_id)
      @enrollment_ids_by_referral_id.fetch(referral_id)[0]
    end

    # we don't have enrollment id on the referrals csv so we have to infer it
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

    def build_posting_record(row)
      record_class = HmisExternalApis::AcHmis::ReferralPosting
      projects_by_project_id = Hmis::Hud::Project
        .where(data_source: data_source)
        .pluck(:project_id, :id)
        .to_h
      unit_types_by_mper = Hmis::UnitType
        .joins(:mper_id)
        .pluck('external_ids.value', :id)
        .to_h
      record_class.new(
        data_source_id: data_source.id,
        identifier: row_value(row, field: 'POSTING_ID'),
        status: posting_status(row),
        project_id: projects_by_project_id.fetch(row_value(row, field: 'PROGRAM_ID')),
        unit_type_id: unit_types_by_mper.fetch(row_value(row, field: 'UNIT_TYPE_ID')),
        resource_coordinator_notes: row_value(row, field: 'RESOURCE_COORDINATOR_NOTES', required: false),
        status_updated_at: parse_date(row_value(row, field: 'ASSIGNED_AT') || row_value(row, field: 'STATUS_UPDATED_AT')),
        HouseholdID: referral_household_id(row_value(row, field: 'REFERRAL_ID')),
        # fields not used in CSV
        # referral_result: row_value(row, field: 'REFERRAL_RESULT'),
        # denial_reason: row_value(row, field: 'DENIAL_REASON'),
        # denial_note:  row_value(row, field: 'STATUS_NOTE/DENIAL_NOTE'),
      )
    end

    def relationship_to_hoh(row)
      @posting_status_map ||= HmisExternalApis::AcHmis::ReferralHouseholdMember
        .relationship_to_hohs
        .invert.stringify_keys
      @posting_status_map.fetch(row_value(row, field: 'RELATIONSHIP_TO_HOH'))
    end

    def posting_status(row)
      value = row_value(row, field: 'STATUS')
      return unless value

      value = value.downcase.gsub(' ', '_') + '_status'
      HmisExternalApis::AcHmis::ReferralPosting.statuses.fetch(value)
    end
  end
end
