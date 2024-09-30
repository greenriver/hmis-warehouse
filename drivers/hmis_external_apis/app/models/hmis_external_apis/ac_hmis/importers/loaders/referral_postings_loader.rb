###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis::Importers::Loaders
  class ReferralPostingsLoader < BaseLoader
    include Hmis::Concerns::HmisArelHelper

    def perform
      if clobber
        # warning- this destroys all referrals regardless of data source
        referral_class.destroy_all
        # is it okay to just destroy all in-progress enrollments?
        Hmis::Hud::Enrollment.
          where(data_source: data_source).
          in_progress.
          find_each(&:really_destroy!)
      end

      import_enrollment_records
      import_referral_records
      import_referral_posting_records
      delete_orphan_referral_posting_records
      import_referral_household_members_records
      fixup_hoh_on_referrals
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
        build_enrollment_rows.each do |enrollment, unit_type_mper_id, fallback_start_date|
          enrollment.save!
          tracker.add_enrollment(enrollment)
          tracker.assign_next_unit(
            enrollment_pk: enrollment.id,
            unit_type_mper_id: unit_type_mper_id,
            fallback_start_date: fallback_start_date,
          )
        end
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

    def delete_orphan_referral_posting_records
      orphans = HmisExternalApis::AcHmis::Referral.where.not(id: HmisExternalApis::AcHmis::ReferralPosting.select(:referral_id))
      total = orphans.count
      log_info "Deleting #{total} referrals with no postings"
      orphans.find_each(&:destroy!)
    end

    def fixup_hoh_on_referrals
      hoh_client_pks_by_household_id = Hmis::Hud::Enrollment.order(:id).
        hmis.heads_of_households.
        joins(:client).
        pluck(Arel.sql('"Enrollment"."HouseholdID", "Client".id')).
        to_h

      HmisExternalApis::AcHmis::Referral.preload(:postings, :household_members).find_each do |referral|
        hoh_members = referral.household_members.filter(&:self_head_of_household?)
        # we could check if the enrollment HoH matches. Could also check if there are multiple HoHs
        next unless hoh_members.empty?

        log_info "Referral #{referral.identifier} has no HoHs, assigning new HoH"
        posting = referral.postings.first!
        enrollment_hoh_client_id = hoh_client_pks_by_household_id[posting.household_id]
        found_hoh = referral.household_members.detect { |hm| hm.client_id == enrollment_hoh_client_id }
        found_hoh ||= referral.household_members.min_by(&:id)
        found_hoh.update!(relationship_to_hoh: 'self_head_of_household')
      end
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

    # create wip enrollments for accepted pending postings, AND assigned postings in walk-ins
    def build_enrollment_rows
      assigned_status = HmisExternalApis::AcHmis::ReferralPosting.statuses.fetch('assigned_status')
      accepted_pending_status = HmisExternalApis::AcHmis::ReferralPosting.statuses.fetch('accepted_pending_status')
      enrollment_coc_by_project_id = Hmis::Hud::ProjectCoc.
        where(data_source: data_source).
        pluck(:project_id, :coc_code).
        to_h

      expected = 0
      seen = Set.new
      records = posting_rows.flat_map do |posting_row|
        project_id = row_value(posting_row, field: 'PROGRAM_ID')
        walkin_program = walkin_project_ids.include?(project_id)
        status = posting_status(posting_row)
        next unless status == accepted_pending_status || (walkin_program && status == assigned_status)

        referral_id = row_value(posting_row, field: 'REFERRAL_ID')
        unit_type_mper_id = row_value(posting_row, field: 'UNIT_TYPE_ID')
        project_pk = project_pk_by_id(project_id)
        next if seen.include?(referral_id)

        seen.add(referral_id)
        household_id = Hmis::Hud::Base.generate_uuid
        start_date = parse_date(row_value(posting_row, field: 'STATUS_UPDATED_AT'))
        expected += 1 if household_member_rows_by_referral(referral_id).blank?
        household_member_rows_by_referral(referral_id).map do |member_row|
          entry_date = parse_date(row_value(posting_row, field: 'REFERRAL_DATE'))
          mci_id = row_value(member_row, field: 'MCI_ID')
          personal_id = client_personal_id_by_mci_id(mci_id)
          client_pk = client_pk_by_mci_id(mci_id)
          expected += 1
          next unless client_pk # skip enrollments where we can't find client

          enrollment = Hmis::Hud::Enrollment.new(default_attrs)
          enrollment.attributes = {
            personal_id: personal_id,
            entry_date: entry_date,
            household_id: household_id,
            relationship_to_hoh: row_value(member_row, field: 'RELATIONSHIP_TO_HOH_ID'),
            enrollment_coc: enrollment_coc_by_project_id[project_id],
          }
          enrollment.build_wip(
            date: entry_date,
            client_id: client_pk,
            project_id: project_pk,
          )
          [enrollment, unit_type_mper_id, start_date]
        end.compact
      end.compact
      log_processed_result(name: 'Enrollments', expected: expected, actual: records.size)
      records
    end

    def build_referral_records
      seen = Set.new
      expected = 0
      records = posting_rows.map do |row|
        referral_id = row_value(row, field: 'REFERRAL_ID')
        next if seen.include?(referral_id)

        expected += 1
        seen.add(referral_id)
        household_member_rows = household_member_rows_by_referral(referral_id)
        if household_member_rows.empty?
          log_info "#{row.context} skipping referral ID \"#{referral_id}\" - has no household members. (status: #{posting_status(row)})"
          next
        end
        found_household_member = household_member_rows.detect do |member_row|
          mci_id = row_value(member_row, field: 'MCI_ID')
          client_pk_by_mci_id(mci_id)
        end
        if found_household_member.nil?
          log_info "#{row.context} skipping referral ID \"#{referral_id}\" - could not resolve any household member MCI IDs. (status: #{posting_status(row)})"
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
      end.compact
      log_processed_result(name: 'Referrals', expected: expected, actual: records.size)
      records
    end

    # assign inferred unit occupancy
    def assign_unit_occupancies
      accepted_status = HmisExternalApis::AcHmis::ReferralPosting.statuses.fetch('accepted_status')
      enrollment_pk_by_id = Hmis::Hud::Enrollment.
        where(data_source: data_source).
        pluck(:enrollment_id, :id).
        to_h

      expected = 0
      actual = 0
      posting_rows.each do |posting_row|
        # only assign accepted enrollments
        next unless posting_status(posting_row) == accepted_status

        # expect enrollment_id to be populated on accepted enrollments
        expected += 1
        enrollment_id = row_value(posting_row, field: 'ENROLLMENTID', required: false)
        unless enrollment_id.present?
          log_info("#{posting_row.context} ENROLLMENTID missing from Accepted referral")
          next
        end
        enrollment_pk = enrollment_pk_by_id[enrollment_id]
        unless enrollment_pk
          log_skipped_row(posting_row, field: 'ENROLLMENTID')
          next
        end

        # Assign the enrollment to the unit that is occupied by this household, or the next available unit.
        # Note: there is no way for a household to be spread across multiple units.
        unit_type_mper_id = row_value(posting_row, field: 'UNIT_TYPE_ID')
        unit_id = tracker.assign_next_unit(
          enrollment_pk: enrollment_pk,
          unit_type_mper_id: unit_type_mper_id,
          fallback_start_date: parse_date(row_value(posting_row, field: 'STATUS_UPDATED_AT')),
        )

        if unit_id
          actual += 1
        else
          msg = "could not assign a unit for enrollment_id: \"#{enrollment_id}\", mper_unit_type_id: \"#{unit_type_mper_id}\""
          log_info("#{posting_row.context} #{msg}")
        end
      end
      log_processed_result(name: 'Occupancies', expected: expected, actual: actual)
    end

    def build_household_member_records
      referral_pks_by_id = referral_class.pluck(:identifier, :id).to_h
      expected = 0
      records = household_member_rows.map do |row|
        expected += 1
        mci_id = row_value(row, field: 'MCI_ID')
        client_pk = client_pk_by_mci_id(mci_id)
        unless client_pk
          log_skipped_row(row, field: 'MCI_ID')
          next # early return
        end
        referral_identifier = row_value(row, field: 'REFERRAL_ID')
        referral_id = referral_pks_by_id[referral_identifier]
        if referral_id.nil?
          log_skipped_row(row, field: 'REFERRAL_ID')
          next
        end
        HmisExternalApis::AcHmis::ReferralHouseholdMember.new(
          referral_id: referral_id,
          relationship_to_hoh: relationship_to_hoh_string_enum(row),
          mci_id: mci_id,
          client_id: client_pk,
        )
      end.compact
      log_processed_result(name: 'Referral Household Members', expected: expected, actual: records.size)
      records
    end

    def household_id_from_member_rows(referral_id, project_id)
      # find household id for this posting:
      # 1) find the head-of-household's MCI for this referral
      hoh_member_row = household_member_rows_by_referral(referral_id).detect do |mr|
        row_value(mr, field: 'RELATIONSHIP_TO_HOH_ID') == '1'
      end

      if hoh_member_row
        referral_household_id(row_value(hoh_member_row, field: 'MCI_ID'), project_id)
      else
        # No HOH found, fallback to first member where can find a household id
        household_ids = household_member_rows_by_referral(referral_id).map do |mr|
          referral_household_id(row_value(mr, field: 'MCI_ID'), project_id)
        end
        household_ids.compact.first
      end
    end

    def build_posting_records
      accepted_status = HmisExternalApis::AcHmis::ReferralPosting.statuses.fetch('accepted_status')
      accepted_pending_status = HmisExternalApis::AcHmis::ReferralPosting.statuses.fetch('accepted_pending_status')

      referral_pks_by_id = referral_class.pluck(:identifier, :id).to_h
      projects_pks_by_id = Hmis::Hud::Project.
        where(data_source: data_source).
        pluck(:project_id, :id).
        to_h
      household_id_by_enrollment_id = Hmis::Hud::Enrollment.
        where(data_source: data_source).
        pluck(:enrollment_id, :household_id).
        to_h
      unit_types_by_mper = Hmis::UnitType.
        joins(:mper_id).
        pluck('external_ids.value', :id).
        to_h

      seen = Set.new
      expected = 0
      records = posting_rows.map do |row|
        project_id = row_value(row, field: 'PROGRAM_ID')
        referral_id = row_value(row, field: 'REFERRAL_ID')

        # There is one row per household member in the referral, but we only need to process one of them.
        next if seen.include?(referral_id)

        status = posting_status(row)
        # 2) Find the household_id for the enrollment linked to this ReferralPosting row, if any.
        household_id = nil
        if status == accepted_status
          # For Accepted referrals, the Enrollment ID should be present on the row.
          enrollment_id = row_value(row, field: 'ENROLLMENTID', required: false)
          unless enrollment_id.present?
            log_info("#{row.context} ENROLLMENTID missing from Accepted referral")
            next
          end
          household_id = household_id_by_enrollment_id[enrollment_id]
        elsif status == accepted_pending_status
          # find the household_id for the project enrollment with that MCI
          household_id = household_id_from_member_rows(referral_id, project_id)
        end

        # Household MUST be present on Accepted and Accepted Pending postings
        if household_id.nil? && [accepted_status, accepted_pending_status].include?(status)
          log_info "#{row.context} No enrollments match Referral #{referral_id} with status #{status}. Skipping"
          next
        end

        expected += 1

        unless referral_pks_by_id.key?(referral_id)
          log_info "#{row.context} Skipping posting for referral #{referral_id} because the referral didn't get created."
          next
        end

        # Only add to "seen" once we successfully processed the row
        seen.add(referral_id)

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
          # Assigned should be required, but its missing from some rows. Fall back to status updated date.
          created_at: parse_date(row_value(row, field: 'ASSIGNED_AT', required: false) || row_value(row, field: 'STATUS_UPDATED_AT')),
        )
      end.compact
      log_processed_result(name: 'Referral Postings', expected: expected, actual: records.size)
      records
    end

    #
    # Lookups and helpers
    #
    def household_member_rows_by_referral(referral_id)
      @household_member_rows_by_referral ||= household_member_rows.group_by { |row| row_value(row, field: 'REFERRAL_ID') }
      @household_member_rows_by_referral[referral_id] || []
    end

    def referral_household_id(mci_id, project_id)
      personal_id = client_personal_id_by_mci_id(mci_id)
      key = [personal_id, project_id]
      household_id_by_personal_id_project_id[key]
    end

    def household_id_by_personal_id_project_id
      # {[personal_id, project_id] => [enrollment_pk, household_id]}
      @household_id_by_personal_id_project_id ||= Hmis::Hud::Enrollment.
        where(data_source: data_source).
        open_including_wip.
        preload(wip: :project).
        map do |e|
          # avoid n+1 problems when calling enrollment.project
          project_id = e.project_id || e.wip&.project&.project_id
          next unless project_id

          [[e.personal_id, project_id], e.household_id]
        end.compact.to_h
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
      @client_ids_by_mci_id ||= Hmis::Hud::Client.
        joins(:ac_hmis_mci_ids).
        where(data_source: data_source).
        pluck('external_ids.value', c_t[:id], c_t[:personal_id]).
        to_h { |mci_id, client_pk, personal_id| [mci_id, [client_pk, personal_id]] }
    end

    def walkin_project_ids
      @walkin_project_ids ||= begin
        walkin_project_pks = Hmis::Hud::CustomDataElementDefinition.find_by(key: :direct_entry).values.where(value_boolean: true).pluck(:owner_id)
        Hmis::Hud::Project.where(id: walkin_project_pks).pluck(:project_id).to_set
      end
    end

    def relationship_to_hoh_string_enum(row)
      @posting_status_map ||= HmisExternalApis::AcHmis::ReferralHouseholdMember.
        relationship_to_hohs.
        invert.stringify_keys
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