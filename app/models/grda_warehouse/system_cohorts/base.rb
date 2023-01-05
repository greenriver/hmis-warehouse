###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::SystemCohorts
  class Base < GrdaWarehouse::Cohort
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

      transaction do
        range.each do |date|
          next unless GrdaWarehouse::Config.get(config_key)

          system_cohort = ensure_system_cohort(self)

          # remove any known changes that were added by the system
          GrdaWarehouse::CohortClientChange.where(
            cohort_id: system_cohort.id,
            user_id: User.system_user.id,
            reason: known_reasons,
            changed_at: date.to_time .. (date + 1.days).to_time,
          ).delete_all

          system_cohort.sync(processing_date: date, date_window: date_window)
        end
      end
    end

    def self.ensure_system_cohort(klass)
      system_cohort = klass.first_or_create! do |cohort|
        cohort.name = cohort.cohort_name
        cohort.system_cohort = true
        cohort.days_of_inactivity = 90
      end
      system_cohort.update(name: system_cohort.cohort_name)
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
