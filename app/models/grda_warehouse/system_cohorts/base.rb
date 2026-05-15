###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse::SystemCohorts
  class Base < GrdaWarehouse::Cohort
    include ArelHelper
    # Because it can take time for HMIS data to arrive in the warehouse,
    # Each day we'll re-run calculations for the prior week to smooth out back-dated data entry
    def self.update_all_system_cohorts(range: 1.weeks.ago.to_date .. Date.yesterday, date_window: nil)
      cohort_classes.each_value do |klass|
        klass.update_system_cohort(range: range, date_window: date_window)
      end
    end

    # NOTE: This should now be possible to generate historic cohort changes
    def self.update_system_cohort(range: 1.weeks.ago.to_date .. Date.yesterday, date_window: nil)
      date_window ||= ::GrdaWarehouse::Config.get(:system_cohort_date_window) || 1.day
      known_reasons = [
        'Newly identified',
        'Returned from housing',
        'Returned from inactive',
        'Inactive',
        'No longer meets criteria',
        'Housed',
      ]

      config_key = cohort_classes.invert[self]
      raise 'Unknown System Cohort Class' unless config_key
      return unless GrdaWarehouse::Config.get(config_key)

      cohort_id = transaction { ensure_system_cohort(self) }.id

      # Each date gets its own transaction to keep lock duration short on cohort_clients
      # and avoid deadlocks with concurrent writers (e.g. parallel background jobs).
      # A fresh instance is loaded per date so that memoized per-date state (e.g. candidate
      # enrollments) does not leak across iterations.
      range.each do |date|
        transaction do
          # remove any known changes that were added by the system
          GrdaWarehouse::CohortClientChange.where(
            cohort_id: cohort_id,
            user_id: User.system_user.id,
            reason: known_reasons,
            changed_at: date.to_time .. (date + 1.days).to_time,
          ).delete_all

          # sync returns false when it can't acquire the cohort write lock;
# rolling back preserves the CohortClientChange rows deleted above.
          raise ActiveRecord::Rollback unless find(cohort_id).sync(processing_date: date, date_window: date_window)
        end
      end
    end

    def self.ensure_system_cohort(klass)
      # Ensure the cohort exists
      system_cohort = klass.first_or_create! do |cohort|
        cohort.name = cohort.cohort_name
        cohort.system_cohort = true
        cohort.days_of_inactivity = 90
      end

      # Ensure the name is correct
      system_cohort.update(name: system_cohort.cohort_name)

      # Ensure the cohort has tabs
      if system_cohort.cohort_tabs.blank?
        GrdaWarehouse::CohortTab.default_rules.each do |rule|
          system_cohort.cohort_tabs.create(**rule)
        end
      end

      system_cohort
    end

    def self.find_system_cohort(cohort_key)
      cohort_classes[cohort_key]&.first
    end

    # Build household data for anyone with a residential enrollment
    private def households(hoh_only: false)
      @households ||= {}.tap do |hh|
        enrollments = GrdaWarehouse::Hud::Enrollment.residential.open_on_date
        enrollments = enrollments.heads_of_households if hoh_only
        enrollment_ids = enrollments.pluck(:id)
        enrollment_ids.each_slice(5_000) do |ids|
          GrdaWarehouse::Hud::Enrollment.where(id: ids).preload(:destination_client).find_each(batch_size: 5_000) do |enrollment|
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
        chronic_adult_only_cohort: GrdaWarehouse::SystemCohorts::ChronicAdultOnly,
      }.freeze
    end
  end
end
