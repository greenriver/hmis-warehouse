###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::SystemCohorts
  class Base < GrdaWarehouse::Cohort
    # Factory
    def self.update_system_cohorts
      cohort_classes.each do |config_key, klass|
        next unless GrdaWarehouse::Config.get(config_key)

        klass.first_or_create! do |cohort|
          cohort.name = cohort.cohort_name
          cohort.system_cohort = true
        end.sync
      end
    end

    private def add_clients(client_ids, reason)
      system_user_id = User.setup_system_user.id
      client_ids -= cohort_clients.pluck(:client_id) # Do not touch existing clients

      client_ids.each do |client_id|
        # Create (or resurrect) added clients
        cohort_client = cohort_clients.
          with_deleted.
          where(client_id: client_id).first_or_initialize
        cohort_client.deleted_at = nil

        # Set any default columns
        self.class.available_columns.each do |column|
          if column.default_value?
            column.cohort = self
            cohort_client[column.column] = column.default_value(client_id)
          end
        end

        # Save the cohort client, and log the create reason
        cohort_client.save
        cohort_client_changes_source.create(
          cohort_id: id,
          cohort_client_id: cohort_client.id,
          user_id: system_user_id,
          change: 'create',
          reason: reason,
          changed_at: Time.current,
        )
      end
      client_ids
    end

    private def remove_clients(client_ids, reason)
      system_user_id = User.setup_system_user.id
      cohort_clients.where(client_id: client_ids).update_all(deleted_at: Time.current)
      cohort_client_changes_source.import(
        client_ids.map do |client_id|
          cohort_client_changes_source.new(
            cohort_id: id,
            cohort_client_id: client_id,
            user_id: system_user_id,
            change: 'destroy',
            reason: reason,
            changed_at: Time.current,
          )
        end,
      )
      client_ids
    end

    private def cohort_client_changes_source
      GrdaWarehouse::CohortClientChange
    end

    def self.cohort_classes
      @cohort_classes ||= {
        currently_homeless_cohort: GrdaWarehouse::SystemCohorts::CurrentlyHomeless,
      }.freeze
    end
  end
end
