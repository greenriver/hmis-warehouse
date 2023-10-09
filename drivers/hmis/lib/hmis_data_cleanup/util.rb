###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Utility functions for cleaning up HMIS data during a migration.
# Be careful, some functions modify data and don't leave a paper trail.
#
# Usage: HmisDataCleanup::Util.assign_missing_household_ids!
module HmisDataCleanup
  class Util
    include ArelHelper

    # Assign Household ID where missing
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

    # Change ProjectID of a project. Used in staging. Probably should never be run in Prod.
    def self.change_project_id!(old_id, new_id)
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
  end
end
