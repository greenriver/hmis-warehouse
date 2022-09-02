###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::SystemCohorts
  class Base < GrdaWarehouse::Cohort
    # Factory
    def self.update_system_cohorts(processing_date: nil, date_window: nil)
      processing_date ||= ::GrdaWarehouse::Config.get(:system_cohort_processing_date) || Date.current
      date_window ||= ::GrdaWarehouse::Config.get(:system_cohort_date_window) || 1.day
      cohort_classes.each do |config_key, klass|
        next unless GrdaWarehouse::Config.get(config_key)

        system_cohort = klass.first_or_create! do |cohort|
          cohort.name = cohort.cohort_name
          cohort.system_cohort = true
          cohort.days_of_inactivity = 90
        end
        system_cohort.update(name: system_cohort.cohort_name)
        system_cohort.sync(processing_date: processing_date, date_window: date_window)
      end
    end

    def self.find_system_cohort(cohort_key)
      cohort_classes[cohort_key]&.first
    end

    private def add_clients(client_ids, reason)
      system_user_id = User.setup_system_user.id
      client_ids -= cohort_clients.pluck(:client_id) # Do not touch existing clients
      cohort_clients_by_client_id = cohort_clients.only_deleted.where(client_id: client_ids).index_by(&:client_id)
      cohort_client_batch = []
      client_ids.each do |client_id|
        # Create (or resurrect) added clients
        cohort_client = cohort_clients_by_client_id[client_id] || GrdaWarehouse::CohortClient.new(cohort_id: id, client_id: client_id)
        cohort_client.deleted_at = nil

        # Set any default columns
        self.class.available_columns.each do |column|
          if column.default_value?
            column.cohort = self
            cohort_client[column.column] = column.default_value(client_id)
          end
        end

        cohort_client_batch << cohort_client
      end

      # Save the cohort clients, and log the create reasons
      update_columns = self.class.available_columns.map { |c| c.column.to_sym if c.column_editable? }.compact.uniq + [:deleted_at]
      results = GrdaWarehouse::CohortClient.import!(
        cohort_client_batch,
        on_duplicate_key_update: { columns: update_columns },
      )
      changes_batch = []
      results.ids.each do |cohort_client_id|
        changes_batch << cohort_client_changes_source.new(
          cohort_id: id,
          cohort_client_id: cohort_client_id,
          user_id: system_user_id,
          change: 'create',
          reason: reason,
          changed_at: Time.current,
        )
      end
      cohort_client_changes_source.import(changes_batch)
      client_ids
    end

    private def remove_clients(client_ids, reason)
      return unless client_ids

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

    # Build household data for anyone with a residential enrollment
    private def households(hoh_only: false)
      @households ||= {}.tap do |hh|
        enrollments = GrdaWarehouse::Hud::Enrollment.residential.open_on_date
        enrollments = enrollments.heads_of_households if hoh_only
        enrollments.preload(:destination_client).find_in_batches(batch_size: 250) do |batch|
          batch.each do |enrollment|
            next unless enrollment.destination_client

            hh[get_hh_id(enrollment)] ||= []
            hh[get_hh_id(enrollment)] << {
              client_id: enrollment.destination_client.id,
              age: enrollment.destination_client.age,
              relationship_to_hoh: enrollment.RelationshipToHoH,
            }.with_indifferent_access
          end
          GC.start
        end
      end
    end

    private def adult_and_child_client_ids
      @adult_and_child_client_ids ||= households.select do |_, enrollments|
        adult_and_child?(enrollments)
      end.map do |_, enrollments|
        enrollments.map { |client| client[:client_id] }
      end.flatten
    end

    private def adult_only_client_ids
      @adult_only_client_ids ||= households.select do |_, enrollments|
        all_over_18?(enrollments)
      end.map do |_, enrollments|
        enrollments.map { |client| client[:client_id] }
      end.flatten
    end

    private def youth_only_client_ids
      @youth_only_client_ids ||= households.select do |_, enrollments|
        only_under_25?(enrollments)
      end.map do |_, enrollments|
        enrollments.map { |client| client[:client_id] }
      end.flatten
    end

    private def youth_no_child_client_ids
      @youth_no_child_client_ids ||= households.select do |_, enrollments|
        only_under_25?(enrollments) && all_over_18?(enrollments)
      end.map do |_, enrollments|
        enrollments.map { |client| client[:client_id] }
      end.flatten
    end

    private def youth_and_child_client_ids
      @youth_and_child_client_ids ||= households.select do |_, enrollments|
        only_under_25?(enrollments) && adult_and_child?(enrollments)
      end.map do |_, enrollments|
        enrollments.map { |client| client[:client_id] }
      end.flatten
    end

    private def youth_and_hoh_client_ids
      @youth_and_hoh_client_ids ||= households(hoh_only: true).select do |_, enrollments|
        only_under_25?(enrollments)
      end.map do |_, enrollments|
        enrollments.map { |client| client[:client_id] }
      end.flatten
    end

    private def household(enrollment)
      households[get_hh_id(enrollment)]
    end

    private def get_hh_id(enrollment)
      enrollment.HouseholdID || "#{enrollment.EnrollmentID}*HH"
    end

    private def only_under_25?(enrollments)
      enrollments.all? { |client| client[:age].present? && client[:age] < 25 }
    end

    private def all_over_18?(enrollments)
      enrollments.all? { |client| client[:age].present? && client[:age] >= 18 }
    end

    private def adult_and_child?(enrollments)
      enrollments.any? { |client| client[:age].present? && client[:age] >= 18 } && enrollments.any? { |client| client[:age].present? && client[:age] < 18 }
    end

    def self.cohort_classes
      @cohort_classes ||= {
        currently_homeless_cohort: GrdaWarehouse::SystemCohorts::CurrentlyHomeless,
        veteran_cohort: GrdaWarehouse::SystemCohorts::Veteran,
        youth_cohort: GrdaWarehouse::SystemCohorts::Youth,
        chronic_cohort: GrdaWarehouse::SystemCohorts::Chronic,
        adult_and_child_cohort: GrdaWarehouse::SystemCohorts::AdultAndChild,
        adult_only_cohort: GrdaWarehouse::SystemCohorts::AdultOnly,
        youth_no_child_cohort: GrdaWarehouse::SystemCohorts::YouthNoChild,
        youth_and_child_cohort: GrdaWarehouse::SystemCohorts::YouthAndChild,
        youth_hoh_cohort: GrdaWarehouse::SystemCohorts::YouthHoh,
      }.freeze
    end
  end
end
