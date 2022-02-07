###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Tasks

  # for accelerating queries asking for clients who entered homelessness within a particular date range
  class EarliestResidentialService
    include TsqlImport
    include ArelHelper

    def initialize(replace_all=false, dry_run: false)
      @replace_all = replace_all.present?
      @dry_run = dry_run
    end

    def run!
      if @replace_all
        Rails.logger.info 'Deprecated, default run now corrects any that are incorrect'
      end

      Rails.logger.info 'Finding records to update'

      to_remove = existing_first_dates - earliest_dates
      Rails.logger.info "Found #{to_remove.size} records that are no longer correct"
      to_add = earliest_dates - existing_first_dates
      Rails.logger.info "Adding #{to_add.size} new first-time residential records"

      GrdaWarehouse::ServiceHistoryEnrollment.transaction do
        if @dry_run
          Rails.logger.info 'DRY RUN, not deleting records'
        else
          if to_remove.any?
            GrdaWarehouse::ServiceHistoryEnrollment.first_date.where(client_id: to_remove.map(&:first)).delete_all
          end
        end

        new_first_entries = []
        if to_add.any?
          to_add.each do |client_id, date|
            first_entry = service_history_source.entry.in_project_type(GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPE_IDS).where(client_id: client_id, first_date_in_program: date).first
            first_entry.record_type = 'first'
            first_entry.id = nil
            new_first_entries << first_entry.attributes.except('id')
          end
          columns = new_first_entries.first.keys
          if @dry_run
            Rails.logger.info "DRY RUN, not adding #{new_first_entries.count} new records"
          else
            insert_batch GrdaWarehouse::ServiceHistoryEnrollment, columns, new_first_entries.map(&:values)
          end
        end
      end

      Rails.logger.info 'done processing first-time residential records'
    end

    def existing_first_dates
      @existing_first_dates ||= GrdaWarehouse::ServiceHistoryEnrollment.first_date.pluck(:client_id, :first_date_in_program)
    end

    def earliest_dates
      @earliest_dates ||= service_history_source.entry.in_project_type(GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPE_IDS).group(:client_id).pluck(:client_id, Arel.sql('min(first_date_in_program)'))
    end

    # limit to enrollments with service
    def service_history_source
      GrdaWarehouse::ServiceHistoryEnrollment.distinct.joins(:service_history_services)
    end
  end
end
