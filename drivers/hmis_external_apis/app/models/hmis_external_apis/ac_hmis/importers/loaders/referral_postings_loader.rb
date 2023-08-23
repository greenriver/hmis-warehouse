###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis::Importers::Loaders
  class ReferralPostingsLoader < BaseLoader
    include Hmis::Concerns::HmisArelHelper

    def perform
      # warning- this destroys all referrals regardless of data source
      referral_class.destroy_all if clobber

      import_enrollment_records
      import_referral_records
      import_referral_posting_records
      import_referral_household_members_records
      assign_unit_occupancies
    end

    POSTINGS_FILENAME = 'ReferralPostings.csv'.freeze
    HOUSEHOLD_MEMBERS_FILENAME = 'ReferralHouseholdMembers.csv'.freeze

    def runnable?
      super &&
      reader.file_present?(POSTINGS_FILENAME) &&
      reader.file_present?(HOUSEHOLD_MEMBERS_FILENAME)
    end

    protected

    def referral_class
      HmisExternalApis::AcHmis::Referral
    end

    def supports_upsert?
      true
    end

    #
    # Data Access
    #
    def posting_rows
      reader.rows(POSTINGS_FILENAME)
    end

    def household_member_rows
      reader.rows(HOUSEHOLD_MEMBERS_FILENAME)
    end

    #
    # Importers
    #
    def import_enrollment_records
      # no way to easily bulk upsert here due to dependent WIP records
      without_paper_trail do
        build_enrollment_rows.each(&:save!)
      end
    end

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

    #
    # Builders
    #

    # create wip enrollments for accepted pending postings
    def build_enrollment_rows
      accepted_pending_status = HmisExternalApis::AcHmis::ReferralPosting.statuses.fetch('accepted_pending_status')
      enrollment_coc_by_project_id = Hmis::Hud::ProjectCoc
        .where(data_source: data_source)
        .pluck(:project_id, :coc_code)
        .to_h

      posting_rows.flat_map do |posting_row|
        next unless posting_status(posting_row) == accepted_pending_status

        project_id = row_value(posting_row, field: 'PROGRAM_ID')
        referral_id = row_value(posting_row, field: 'REFERRAL_ID')
        household_id = Hmis::Hud::Base.generate_uuid
        household_member_rows_by_referral(referral_id).map do |member_row|
          entry_date = parse_date(row_value(posting_row, field: 'REFERRAL_DATE'))
          mci_id = row_value(member_row, field: 'MCI_ID')
          personal_id = client_personal_id_by_mci_id(mci_id)
          client_pk = client_pk_by_mci_id(mci_id)
          next unless client_pk # skip enrollments where we can't find client

          enrollment = Hmis::Hud::Enrollment.new(default_attrs)
          enrollment.attributes = {
            personal_id: personal_id,
            entry_date: entry_date,
            household_id: household_id,
            relationship_to_hoh: relationship_to_hoh(member_row),
            enrollment_coc: enrollment_coc_by_project_id[project_id],
          }
          enrollment.build_wip(
            date: entry_date,
            client_id: client_pk,
            project_id: project_pk_by_id(project_id),
          )
          enrollment
        end.compact
      end.compact
    end

    def build_referral_records
      posting_rows.map do |row|
        referral_id = row_value(row, field: 'REFERRAL_ID')
        found_household_member = household_member_rows_by_referral(referral_id).detect do |member_row|
          mci_id = row_value(member_row, field: 'MCI_ID')
          client_pk_by_mci_id(mci_id)
        end
        if found_household_member.nil?
          log_info "#{row.context} skipping referral ID \"#{referral_id}\" - could not resolve any household member MCI IDs"
          next
        end

        referral_class.new(
          # NOTE: since the referral comes from link, the enrollment id should be NULL
          identifier: referral_id,
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
      accepted_status = HmisExternalApis::AcHmis::ReferralPosting.statuses.fetch('accepted_status')
      posting_rows.each do |posting_row|
        # only assign accepted enrollments
        next unless posting_status(posting_row) == accepted_status

        referral_id = row_value(posting_row, field: 'REFERRAL_ID')
        household_member_rows_by_referral(referral_id).each do |member_row|
          project_id = row_value(posting_row, field: 'PROGRAM_ID')
          mci_id = row_value(member_row, field: 'MCI_ID')
          enrollment_pk = client_enrollment_pk(mci_id, project_id)
          next unless enrollment_pk

          unit_type_mper_id = row_value(posting_row, field: 'UNIT_TYPE_ID')
          unit_id = assign_next_unit(
            enrollment_pk: enrollment_pk,
            unit_type_mper_id: unit_type_mper_id,
            fallback_start_date: parse_date(row_value(posting_row, field: 'STATUS_UPDATED_AT')),
          )
          unless unit_id
            msg = "could not assign a unit for project_id: \"#{project_id}\", mci_id: \"#{mci_id}\", mper_unit_type_id: \"#{unit_type_mper_id}\""
            log_info("[#{member_row.context},#{posting_row.context}] #{msg}")
          end
        end
      end
    end

    def build_household_member_records
      referral_pks_by_id = referral_class.pluck(:identifier, :id).to_h
      household_member_rows.map do |row|
        mci_id = row_value(row, field: 'MCI_ID')
        client_pk = client_pk_by_mci_id(mci_id)
        unless client_pk
          log_skipped_row(row, field: 'MCI_ID')
          next # early return
        end
        HmisExternalApis::AcHmis::ReferralHouseholdMember.new(
          referral_id: referral_pks_by_id.fetch(row_value(row, field: 'REFERRAL_ID')),
          relationship_to_hoh: relationship_to_hoh(row),
          mci_id: mci_id,
          client_id: client_pk,
        )
      end
    end

    def build_posting_records
      referral_pks_by_id = referral_class.pluck(:identifier, :id).to_h
      projects_pks_by_id = Hmis::Hud::Project
        .where(data_source: data_source)
        .pluck(:project_id, :id)
        .to_h

      unit_types_by_mper = Hmis::UnitType
        .joins(:mper_id)
        .pluck('external_ids.value', :id)
        .to_h

      posting_rows.map do |row|
        project_id = row_value(row, field: 'PROGRAM_ID')
        referral_id = row_value(row, field: 'REFERRAL_ID')

        # find household id for this posting:
        # 1) find the head-of-household's MCI for this referral
        hoh_member_row = household_member_rows_by_referral(referral_id).detect do |mr|
          row_value(mr, field: 'RELATIONSHIP_TO_HOH_ID') == '1'
        end
        hoh_mci_id = row_value(hoh_member_row, field: 'MCI_ID')
        # 2) find the household_id for the project enrollment with that MCI
        household_id = referral_household_id(hoh_mci_id, project_id)
        next unless household_id

        HmisExternalApis::AcHmis::ReferralPosting.new(
          referral_id: referral_pks_by_id.fetch(referral_id),
          data_source_id: data_source.id,
          identifier: row_value(row, field: 'POSTING_ID'),
          status: posting_status(row),
          project_id: projects_pks_by_id.fetch(project_id),
          unit_type_id: unit_types_by_mper.fetch(row_value(row, field: 'UNIT_TYPE_ID')),
          resource_coordinator_notes: row_value(row, field: 'RESOURCE_COORDINATOR_NOTES', required: false),
          HouseholdID: household_id,
          status_updated_at: parse_date(row_value(row, field: 'STATUS_UPDATED_AT')),
          created_at: parse_date(row_value(row, field: 'ASSIGNED_AT')),
        )
      end
    end

    #
    # Lookups and helpers
    #
    def household_member_rows_by_referral(referral_id)
      @household_member_rows_by_referral ||= household_member_rows.group_by { |row| row_value(row, field: 'REFERRAL_ID') }
      @household_member_rows_by_referral[referral_id] || []
    end

    def client_enrollment_pk(mci_id, project_id)
      personal_id = client_personal_id_by_mci_id(mci_id)
      key = [personal_id, project_id]
      ids_by_personal_id_project_id.dig(key, 0)
    end

    def referral_household_id(mci_id, project_id)
      personal_id = client_personal_id_by_mci_id(mci_id)
      key = [personal_id, project_id]
      ids_by_personal_id_project_id.dig(key, 1)
    end

    def ids_by_personal_id_project_id
      # {[personal_id, project_id] => [enrollment_pk, household_id]}
      @ids_by_personal_id_project_id ||= Hmis::Hud::Enrollment
        .where(data_source: data_source)
        .open_including_wip
        .preload(wip: :project)
        .to_h do |e|
          # avoid n+1 problems when calling enrollment.project
          project_id = e.project_id || e.wip.project.project_id
          [[e.personal_id, project_id], [e.id, e.household_id]]
        end
    end

    def project_pk_by_id(project_id)
      @project_pk_by_id ||= Hmis::Hud::Project.where(data_source: data_source).pluck(:project_id, :id).to_h
      @project_pk_by_id.fetch(project_id)
    end

    def client_pk_by_mci_id(mci_id)
      client_ids_by_mci_id.dig(mci_id, 0)
    end

    def client_personal_id_by_mci_id(mci_id)
      client_ids_by_mci_id.dig(mci_id, 1)
    end

    def client_ids_by_mci_id
      # {mci_id => [client_pk, personal_id]}
      @client_ids_by_mci_id ||= Hmis::Hud::Client
        .joins(:ac_hmis_mci_ids)
        .where(data_source: data_source)
        .pluck('external_ids.value', c_t[:id], c_t[:personal_id])
        .to_h { |mci_id, client_pk, personal_id| [mci_id, [client_pk, personal_id]] }
    end

    def relationship_to_hoh(row)
      @posting_status_map ||= HmisExternalApis::AcHmis::ReferralHouseholdMember
        .relationship_to_hohs
        .invert.stringify_keys
      @posting_status_map.fetch(row_value(row, field: 'RELATIONSHIP_TO_HOH_ID'))
    end

    def posting_status(row)
      value = row_value(row, field: 'STATUS')
      return unless value

      value = value.downcase.gsub(' ', '_') + '_status'
      HmisExternalApis::AcHmis::ReferralPosting.statuses.fetch(value)
    end
  end
end
