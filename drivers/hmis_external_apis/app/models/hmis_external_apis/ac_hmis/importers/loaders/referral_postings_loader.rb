###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis::Importers::Loaders
  class ReferralPostingsLoader < BaseLoader
    def perform
      init_enrollment_ids_by_referral_id

      # destroy existing records and re-import
      referral_scope.destroy_all if clobber

      import_referral_records
      import_referral_posting_records
      import_referral_household_members_records
      assign_unit_occupancies
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
      ]
    end

    protected

    def import_referral_records
      ar_import(
        referral_class,
        build_referral_records,
        on_duplicate_key_update: { conflict_target: :identifier, columns: :all },
      )
    end

    def import_referral_posting_records
      ar_import(
        HmisExternalApis::AcHmis::ReferralPosting,
        build_posting_records,
        on_duplicate_key_update: { conflict_target: :identifier, columns: :all },
      )
    end

    def import_referral_household_members_records
      ar_import(
        HmisExternalApis::AcHmis::ReferralHouseholdMember,
        build_household_member_records,
        on_duplicate_key_update: { conflict_target: [:client_id, :referral_id], columns: :all },
      )
    end

    def supports_upsert?
      true
    end

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
      posting_rows.map do |row|
        referral_id = row_value(row, field: 'REFERRAL_ID')
        referral_class.new(
          identifier: referral_id,
          enrollment_id: referral_enrollment_id(referral_id),
          referral_date: parse_date(row_value(row, field: 'REFERRAL_DATE')),
          service_coordinator: row_value(row, field: 'SERVICE_COORDINATOR'),
          referral_notes: row_value(row, field: 'REFERRAL_NOTES', required: false),
          chronic: yn_boolean(row_value(row, field: 'CHRONIC', required: false)),
          score: row_value(row, field: 'SCORE', required: false),
          needs_wheelchair_accessible_unit: yn_boolean(row_value(row, field: 'NEEDS_WHEELCHAIR_ACCESSIBLE_UNIT', required: false)),
        )
      end
    end

    # assign inferred unit occupancy
    def assign_unit_occupancies
      household_member_rows_by_referral = household_member_rows.group_by { |row| row_value(row, field: 'REFERRAL_ID') }
      posting_rows.each do |posting_row|
        referral_id = row_value(posting_row, field: 'REFERRAL_ID')
        household_member_rows = household_member_rows_by_referral[referral_id] || []
        household_member_rows.each do |member_row|
          project_id = row_value(posting_row, field: 'PROGRAM_ID')
          mci_id = row_value(member_row, field: 'MCI_ID')
          enrollment_pk = client_enrollment_pk(mci_id, project_id)
          assign_next_unit(
            enrollment_pk: enrollment_pk,
            unit_type_mper_id: row_value(posting_row, field: 'UNIT_TYPE_ID'),
            start_date: parse_date(row_value(posting_row, field: 'STATUS_UPDATED_AT')),
          )
        end
      end
    end

    def referral_household_id(referral_id)
      @enrollment_ids_by_referral_id.fetch(referral_id)[1]
    end

    def referral_enrollment_id(referral_id)
      @enrollment_ids_by_referral_id.fetch(referral_id)[0]
    end

    def client_enrollment_pk(mci_id, project_id)
      ids_by_personal_id_project_id[[mci_id, project_id]][0]
    end

    def ids_by_personal_id_project_id
      # {[personal_id, project_id] => [enrollment_id, household_id]}
      @ids_by_personal_id_project_id ||= Hmis::Hud::Enrollment
        .where(data_source: data_source)
        .pluck(:personal_id, :project_id, :id, :household_id)
        .to_h { |personal_id, project_id, id, household_id| [[personal_id, project_id], [id, household_id]] }
    end

    # we don't have enrollment id on the referrals csv so we have to infer it
    # from the referral.project_id and MCI ID on household member.
    # Assumes the MCI ID is the PersonalID
    def init_enrollment_ids_by_referral_id
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

    def build_household_member_records
      client_ids_by_mci_id = Hmis::Hud::Client
        .where(data_source: data_source)
        .pluck(:personal_id, :id)
        .to_h
      referral_pks_by_referral_id = referral_scope.pluck(:identifier, :id).to_h
      record_class = HmisExternalApis::AcHmis::ReferralHouseholdMember
      household_member_rows.map do |row|
        mci_id = row_value(row, field: 'MCI_ID')
        referral_id = row_value(row, field: 'REFERRAL_ID')
        record_class.new(
          referral_id: referral_pks_by_referral_id.fetch(referral_id),
          relationship_to_hoh: relationship_to_hoh(row),
          mci_id: mci_id,
          client_id: client_ids_by_mci_id.fetch(mci_id),
        )
      end
    end

    def build_posting_records
      record_class = HmisExternalApis::AcHmis::ReferralPosting
      referral_pks_by_referral_id = referral_scope.pluck(:identifier, :id).to_h
      projects_by_project_id = Hmis::Hud::Project
        .where(data_source: data_source)
        .pluck(:project_id, :id)
        .to_h
      unit_types_by_mper = Hmis::UnitType
        .joins(:mper_id)
        .pluck('external_ids.value', :id)
        .to_h
      posting_rows.map do |row|
        referral_id = row_value(row, field: 'REFERRAL_ID')
        record = record_class.new(
          referral_id: referral_pks_by_referral_id.fetch(referral_id),
          data_source_id: data_source.id,
          identifier: row_value(row, field: 'POSTING_ID'),
          status: posting_status(row),
          project_id: projects_by_project_id.fetch(row_value(row, field: 'PROGRAM_ID')),
          unit_type_id: unit_types_by_mper.fetch(row_value(row, field: 'UNIT_TYPE_ID')),
          resource_coordinator_notes: row_value(row, field: 'RESOURCE_COORDINATOR_NOTES', required: false),
          HouseholdID: referral_household_id(referral_id),
        )
        # not totally sure how to treat these dates
        if record.assigned_status?
          record.status_updated_at = parse_date(row_value(row, field: 'ASSIGNED_AT'))
        else
          record.status_updated_at = parse_date(row_value(row, field: 'STATUS_UPDATED_AT'))
        end
        record
      end
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

    def referral_scope
      enrollments = Hmis::Hud::Enrollment.where(data_source: data_source)
      referral_class.where(enrollment_id: enrollments.select(:id))
    end
  end
end
