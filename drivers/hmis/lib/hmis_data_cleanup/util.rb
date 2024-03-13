###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'csv'

# Utility functions for cleaning up HMIS data during a migration.
# Be careful, some functions modify data and don't leave a paper trail.
#
# Usage: HmisDataCleanup::Util.assign_missing_household_ids!
module HmisDataCleanup
  class Util
    include ArelHelper

    # Remove all ExportIDs from HMIS Enrollments.
    # This should be done after an HMIS migration, otherwise ServiceHistoryService generation will behave incorrectly
    def self.clear_enrollment_export_ids!
      without_papertrail_or_timestamps do
        Hmis::Hud::Enrollment.hmis.update_all(ExportID: nil)
      end
    end

    # Set the EnrollmentCoC field for all HMIS Enrollments.
    # This could eventually be updated to learn the CoC based on the Project's ProjectCoC record. We don't need that yet since
    # we are dealing with a single-CoC installation at the time of writing this.
    def self.update_all_enrollment_cocs!(coc_code)
      without_papertrail_or_timestamps do
        Hmis::Hud::Enrollment.hmis.update_all(EnrollmentCoC: coc_code)
      end
    end

    # Assign Household ID where missing
    #
    # Note: If this gets to be a large number, an upsert is probably worth doing.
    # We could `scope.find_in_batches` and then enrollment.assign_attributes and finally "import" the batch with a conflict key of id.
    def self.assign_missing_household_ids!
      scope = Hmis::Hud::Enrollment.hmis.where(household_id: nil)
      Rails.logger.info "Assigning household id to #{scope.size} enrollments"
      scope.each do |enrollment|
        hh_id = Hmis::Hud::Base.generate_uuid
        without_papertrail_or_timestamps do
          enrollment.update_columns(household_id: hh_id) # skips callbacks
        end
      end
    end

    # Find any single-member households that do not have a HoH, and make that person the HoH
    def self.make_sole_member_hoh!
      single_member_households = Hmis::Hud::Enrollment.hmis.
        group(:household_id).
        having(nf('COUNT', [:HouseholdID]).eq(1)).
        pluck(:household_id)

      num = Hmis::Hud::Enrollment.hmis.
        where(household_id: single_member_households).
        where.not(relationship_to_hoh: 1).size

      Rails.logger.info "Assigning HoH to #{num} single-member households"

      without_papertrail_or_timestamps do
        Hmis::Hud::Enrollment.hmis.
          where(household_id: single_member_households).
          where.not(relationship_to_hoh: 1).
          update_all(relationship_to_hoh: 1) # skips callbacks
      end
    end

    def self.delete_duplicate_bed_nights!
      duplicates = Hmis::Hud::Service.hmis.where(record_type: 200).
        where.not(date_provided: nil).
        group(:enrollment_id, :date_provided).
        having('count(*) > 1').select('"Services"."EnrollmentID", "Services"."DateProvided", array_agg("Services"."id") as service_ids')

      ids_to_delete = duplicates.map { |r| r.service_ids.drop(1) }.flatten
      Rails.logger.info "Deleting #{ids_to_delete.size} duplicate Bed Nights"

      Hmis::Hud::Service.where(id: ids_to_delete).update_all(DateDeleted: Time.current, source_hash: nil)
    end

    def self.delete_duplicate_exit_records!
      data_source_id = GrdaWarehouse::DataSource.hmis.first.id
      dups = GrdaWarehouse::Hud::Exit.where(data_source_id: data_source_id).
        group(:EnrollmentID).
        having('count(*) > 1').
        select('"Exit"."EnrollmentID", array_agg("Exit"."id" ORDER BY "Exit"."id") as exit_ids')

      ids_to_delete = dups.map { |r| r.exit_ids.drop(1) }.flatten
      Rails.logger.info "Deleting #{ids_to_delete.size} duplicate Exits"

      GrdaWarehouse::Hud::Exit.where(id: ids_to_delete).update_all(DateDeleted: Time.current, source_hash: nil)
    end

    # Transform all-uppercase client names to camel-cased client names
    # WARNING! Doesn't skips callbacks. Should probably be modified if we ever need to use this again.
    def self.humanize_client_names!
      name_fields = [:first_name, :middle_name, :last_name, :name_suffix]
      scope = Hmis::Hud::Client.hmis.where('"Client"."FirstName" = upper("Client"."FirstName")')
      # scope = Hmis::Hud::Client.hmis
      scope.in_batches(of: 5_000) do |batch|
        Rails.logger.info 'Next batch..'
        values = []
        batch.pluck(:id, *name_fields).each do |id_and_names|
          id = id_and_names.first
          names_arr = id_and_names.drop(1)
          names = name_fields.zip(names_arr).to_h.compact_blank
          next unless names.any?

          # puts "old: #{names.values.join(' ')}"
          names = names.transform_values { |s| s.downcase.gsub(/(\s+\w)|(^\w)/, &:upcase) }
          # puts "new: #{names.values.join(' ')}"
          names[:id] = id
          values << names
        end

        grouped_clients = values.index_by { |client| client[:id] }

        # without papertrail so it doesn't show up in Client Audit History
        without_papertrail_or_timestamps do
          Hmis::Hud::Client.update(grouped_clients.keys, grouped_clients.values)
          Rails.logger.info "Updated #{grouped_clients.size} clients"
        end
      end
    end

    # Change ProjectID of a project. Useful in staging environment if need a project ID to match prod.
    def self.change_project_id!(old_id, new_id, force: false)
      return if Rails.env.production? && !force

      project = ::Hmis::Hud::Project.hmis.find_by(project_id: old_id)
      return unless project

      Rails.logger.info "#{project.project_name}: #{old_id}=>#{new_id}"

      Hmis::Hud::Project.transaction do
        project.funders.update_all(project_id: new_id)
        project.project_cocs.update_all(project_id: new_id)
        project.inventories.update_all(project_id: new_id)
        project.affiliations.update_all(project_id: new_id)
        project.hmis_participations.update_all(project_id: new_id)
        project.ce_participations.update_all(project_id: new_id)
        project.enrollments.update_all(project_id: new_id)
        project.residential_affiliations.update_all(ResProjectID: new_id)
        project.project_id = new_id
        project.save!(validate: false)
      end
    end

    def self.write_project_unit_summary(filename: 'hmis_project_summary.csv')
      direct_entry_cded = Hmis::Hud::CustomDataElementDefinition.find_by(key: :direct_entry)
      project_pk_to_walkin_status = direct_entry_cded.values.pluck(:owner_id, :value_boolean).to_h if direct_entry_cded

      rows = []
      Hmis::Hud::Project.hmis.each do |project|
        next if project.project_id.size == 32 # Skip internal projects

        wip_enrollments = project.wip_enrollments.pluck(:id)

        open_enrollments = project.enrollments.open_on_date.pluck(:id)
        open_enrollments_with_referral = project.enrollments.open_on_date.joins(:source_postings).pluck(:id)
        open_enrollments_missing_referral = open_enrollments - open_enrollments_with_referral

        open_enrollments_with_unit = project.enrollments.open_on_date.joins(:current_unit).pluck(:id)
        open_enrollments_missing_unit = open_enrollments - open_enrollments_with_unit

        unit_capacity = project.units.size
        open_households = project.enrollments.open_on_date.pluck(:household_id).uniq
        hash = {
          ProjectID: project.project_id,
          ProjectName: project.project_name,
          OperatingEndDate: project.operating_end_date&.strftime('%Y-%m-%d'),
          UnitCapacity: unit_capacity,
          OpenHouseholds: open_households.size,
          OverCapacity: open_households.size > unit_capacity ? 'Yes' : 'No',
          OpenEnrollments: open_enrollments.size,
          OpenEnrollmentsWithoutReferral: open_enrollments_missing_referral.size,
          OpenEnrollmentsWithoutUnit: open_enrollments_missing_unit.size,
          AcceptedPendingIncompleteEnrollments: wip_enrollments.size,
        }

        if direct_entry_cded
          accepts_walk_in = project_pk_to_walkin_status[project.id]
          walkin_status = accepts_walk_in ? 'Yes' : 'No'
          walkin_status = 'Unknown' if accepts_walk_in.nil?
          hash[:DirectEntry] = walkin_status
        end

        rows << hash
      end

      CSV.open(filename, 'wb+', write_headers: true, headers: rows.first.keys) do |writer|
        rows.each do |row|
          writer << row.values
        end
      end
    end

    def self.write_potential_duplicates(filename: 'hmis_client_potential_duplicates.csv', variant: 'all', full_name: true)
      Rails.logger.info("Finding potential duplicates (variant: #{variant})")

      data_source_id = GrdaWarehouse::DataSource.hmis.first.id

      # Find all Destination clients that have >1 source client in HMIS
      destination_id_to_source_ids = GrdaWarehouse::WarehouseClient.where(data_source_id: data_source_id).
        joins(:source). # drop non existent source clients
        group(:destination_id).
        having('count(*) > 1').select('"destination_id", array_agg("source_id") as source_ids').
        map { |r| [r.destination_id, r.source_ids] }.
        to_h

      # Map source ID => demographic details
      source_id_to_info = Hmis::Hud::Client.where(id: destination_id_to_source_ids.values.flatten).
        where(data_source_id: data_source_id).
        map do |client|
          name_parts = if full_name
            [client.first_name, client.middle_name, client.last_name, client.name_suffix]
          else
            [client.first_name, client.last_name]
          end

          comparison_attrs = {
            name: name_parts.compact_blank.map(&:strip).join(' ').downcase,
            dob: client.dob&.strftime('%Y-%m-%d'),
            ssn: client.ssn,
            genders: client.gender_multi.excluding(8, 9, 99).sort.map { |k| ::HudUtility2024.gender(k) }.join(', ').presence,
          }
          [client.id, comparison_attrs]
        end.to_h

      rows = []
      destination_id_to_source_ids.each do |dest_id, source_ids|
        row = {
          WarehouseID: dest_id,
        }

        # Expect at most 10 HMIS clients per Warehouse ID (increase if needed)
        10.times do |idx|
          client_id = source_ids[idx]
          row["Client#{idx + 1}_ID"] = client_id
          info = source_id_to_info.fetch(client_id, nil) || {}
          row["Client#{idx + 1}_Name"] = info[:name]
          row["Client#{idx + 1}_DOB"] = info[:dob]
          row["Client#{idx + 1}_SSN"] = info[:ssn]
          row["Client#{idx + 1}_Gender"] = info[:genders]
        end

        client_details = source_ids.map { |id| source_id_to_info[id] }.compact
        exact_match = [:name, :dob, :ssn, :genders].all? do |field|
          client_details.map { |r| r[field] }.compact.uniq.size < 2
        end
        case variant
        when 'all'
          rows << row
        when 'only_exact_matches'
          rows << row if exact_match
        when 'only_non_exact_matches'
          rows << row unless exact_match
        else
          raise 'unsupported variant'
        end
      end

      return rows unless filename

      skipped = destination_id_to_source_ids.size - rows.size
      Rails.logger.info("Skipped #{skipped} potential duplicates; writing #{rows.count} to file")

      # Actually perform all of the merges
      #
      # actor_id = User.system_user.id
      # rows.each do |row|
      #   client_ids = []
      #   10.times do |idx|
      #     client_ids << row["Client#{idx + 1}_ID"]
      #   end
      #   Hmis::MergeClientsJob.perform_now(client_ids: client_ids.compact, actor_id: actor_id)
      # end

      CSV.open(filename, 'wb+', write_headers: true, headers: rows.first.keys) do |writer|
        rows.each do |row|
          writer << row.values
        end
      end
    end

    def self.without_papertrail_or_timestamps
      ActiveRecord::Base.record_timestamps = false
      begin
        PaperTrail.request(enabled: false) do
          yield
        end
      ensure
        ActiveRecord::Base.record_timestamps = true
      end
    end

    # Sum MonthlyTotalIncome where it is null but there are Income values
    def self.fix_missing_monthly_total_income!
      count = Hmis::Hud::IncomeBenefit.hmis.where(IncomeFromAnySource: 1, TotalMonthlyIncome: nil).size
      Rails.logger.info "#{count} income records to clean"

      amount_fields = [:EarnedAmount, :UnemploymentAmount, :SSIAmount, :SSDIAmount, :VADisabilityServiceAmount, :VADisabilityNonServiceAmount, :PrivateDisabilityAmount, :WorkersCompAmount, :TANFAmount, :GAAmount, :SocSecRetirementAmount, :PensionAmount, :ChildSupportAmount, :AlimonyAmount, :OtherIncomeAmount]

      Hmis::Hud::IncomeBenefit.hmis.where(IncomeFromAnySource: 1, TotalMonthlyIncome: nil).in_batches do |batch|
        Rails.logger.info('Processing batch...')
        values = []
        batch.each do |record|
          calculated_total = amount_fields.map { |f| record.send(f) }.compact.sum
          values << [record.id, calculated_total]
        end
        without_papertrail_or_timestamps do
          cols = [:id, :TotalMonthlyIncome]
          result = Hmis::Hud::IncomeBenefit.import(cols, values, validate: false, on_duplicate_key_update: { conflict_target: [:id], columns: [:TotalMonthlyIncome] })
          raise "error: #{result.failed_instances.inspect}" if result.failed_instances.any?
        end
      end
      Rails.logger.info 'Done'
    end

    # Cleanup function to run if/when we add a new Custom record type and forget to add it to the Hmis::MergeClientsJob.
    # WARNING: this cleanup task is not the most efficient. If there are a lot of record to clean up, may need further optimization.
    def self.cleanup_dangling_records_from_merge!(klass: Hmis::Hud::CustomCaseNote)
      dangling_records = klass.left_outer_joins(:enrollment).where(enrollment: { id: nil })
      Rails.logger.info "Found #{dangling_records.size} dangling records from deleted clients"

      personal_ids = dangling_records.pluck(:personal_id)
      raise 'Some personal IDs are not deleted' unless Hmis::Hud::Client.hmis.where(personal_id: personal_ids).zero?

      num_deleted_clients = Hmis::Hud::Client.hmis.only_deleted.where(personal_id: personal_ids).size
      Rails.logger.info "Records are from #{num_deleted_clients.size} deleted clients"

      # Note: Using ClientMergeAudit instead of ClientMergeHistory because it was introduced first
      merged_personal_ids = Hmis::ClientMergeAudit.all.map { |a| a.pre_merge_state.map { |f| f['PersonalID'] } }

      # Record id => new PersonalID
      record_to_personal_id = {}
      dangling_records.each do |record|
        match = merged_personal_ids.find { |arr| arr.include?(record.personal_id) }
        new_personal_id = if match.size == 2
          match.excluding(record.personal_id).first
        else
          Hmis::Hud::Client.hmis.where(personal_id: match).first&.personal_id
        end
        next unless new_personal_id

        record_to_personal_id[record.id] = new_personal_id
      end

      dangling_records_by_id = dangling_records.index_by(&:id)

      Rails.logger.info "Updating #{record_to_personal_id.size} records..."
      without_papertrail_or_timestamps do
        record_to_personal_id.each do |id, personal_id|
          dangling_records_by_id[id].update_columns(personal_id: personal_id)
        end
      end

      remaining_dangling = dangling_records.reload.size
      if remaining_dangling.zero?
        Rails.logger.info 'Success: all dangling records fixed!'
      else
        Rails.logger.info "WARNING: #{remaining_dangling} dangling records remain"
      end
    end

    # Method for restoring enrollments that were deleted in an import.
    # Probably needs to be called in batches, depending on the size of the enrollment scope.
    def restore_deleted_enrollments!(enrollments_to_restore, conflict_set: nil, dry_run: false)
      # Commented-out examples of parameters:
      # enrollments_to_restore = Hmis::Hud::Enrollment.hmis.only_deleted.where(project_id: 650).where(date_deleted: date)
      # conflict_set = Hmis::Hud::Enrollment.hmis.where(project_id: 650).pluck(:ProjectID, :PersonalID, :EntryDate).to_set

      valid_personal_ids = Hmis::Hud::Client.hmis.pluck(:personal_id).uniq.to_set
      personal_ids_from_deleted_records = enrollments_to_restore.pluck(:personal_id).uniq

      # Map { old personal id => new personal id } for clients that have been merged
      old_to_new_personal_id = Hmis::Hud::Client.hmis.with_deleted.where(personal_id: personal_ids_from_deleted_records).map do |client|
        [client.personal_id, client.reverse_merge_histories.first&.retained_client&.personal_id]
      end.to_h

      conflicts = 0 # num skipped due to conflict (PersonalID + Entry Date, meaning the enrollment has been re-created since it was deleted)
      enrollments_where_personal_id_updated = 0 # num enrollments where PersonalID was updated due to a merge
      enrollments_skipped_due_to_unrecognized_personal_id = 0 # num enrollments skipped because personal ID not found (and not merged)
      updated = 0

      enrollments_to_restore.each do |enrollment|
        # Find the new personal ID if this client has been merged.
        # There is no need to update Personal IDs on associated records, because those should have already been
        # updated when the merge occurred. This is assuming that those associated records are NOT deleted.
        new_personal_id = old_to_new_personal_id[enrollment.personal_id]

        if conflict_set&.include?([enrollment.project_id, new_personal_id || enrollment.personal_id, enrollment.entry_date])
          conflicts += 1
          next
        end

        if !valid_personal_ids.include?(new_personal_id || enrollment.personal_id)
          enrollments_skipped_due_to_unrecognized_personal_id += 1
          next
        end

        if new_personal_id
          enrollment.PersonalID = new_personal_id
          enrollments_where_personal_id_updated += 1
        end

        enrollment.DateDeleted = nil
        without_papertrail_or_timestamps { enrollment.save!(validate: false) } unless dry_run
        updated += 1
      end

      total_num = enrollments_to_restore.size
      Rails.logger.info("#{conflicts}/#{total_num} records skipped due to conflict on ProjectID + PersonalID + EntryDate")
      Rails.logger.info("#{enrollments_skipped_due_to_unrecognized_personal_id}/#{total_num} records skipped because the PersonalID was not found")
      Rails.logger.info("#{enrollments_where_personal_id_updated}/#{total_num} records had the PersonalID updated due to a previous HMIS Client Merge")
      Rails.logger.info("#{updated} records updated")

      # You probably want to run some cleanup:
      #
      # HmisDataCleanup::Util.assign_missing_household_ids!
      # HmisDataCleanup::Util.make_sole_member_hoh!

      # Remember to generate HUD Assessments by running the MigrateAssessmentsJob:
      #
      # Hmis::MigrateAssessmentsJob.perform_now(
      #   data_source_id: GrdaWarehouse::DataSource.hmis.first.id,
      #   project_ids: [<project ids>],
      #   clobber: false,
      #   delete_dangling_records: false,
      # )
    end
  end
end
