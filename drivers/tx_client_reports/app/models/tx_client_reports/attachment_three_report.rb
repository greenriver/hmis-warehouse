###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module TxClientReports
  class AttachmentThreeReport
    include ::Filter::FilterScopes
    include ArelHelper

    def initialize(filter)
      @filter = filter
    end

    def rows
      return [] unless @filter.project_ids.any? || @filter.project_group_ids.any?

      enrollments = enrollment_scope.
        preload(
          service_history_enrollment_for_head_of_household: { enrollment: :income_benefits_at_entry },
          project: :project_cocs,
          household_enrollments: :client,
        ).
        where(client_id: client_ids).
        order(first_date_in_program: :desc). # index by uses the last value, so this selects the oldest enrollment
        index_by(&:client_id)

      client_scope.map do |client|
        enrollment = enrollments[client.id]
        project = enrollment.project
        hoh_income = enrollment.
          service_history_enrollment_for_head_of_household&.
          enrollment&.
          income_benefits_at_entry&.
          TotalMonthlyIncome
        household = if enrollment.household_id.present?
          enrollment.household_enrollments&.map(&:client)
        else
          [client]
        end
        {
          project_id: project.id,
          project_name: project.ProjectName,
          service_date: enrollment.first_date_in_program,
          report_start: @filter.start,
          entry_after_start: enrollment.first_date_in_program > @filter.start,
          fort_worth_resident: nil, # leave blank
          service_location: nil, # leave blank
          client_name: client.name,
          client_id: client.id,
          street_address: enrollment.project.project_cocs&.first&.Address1, # Shelter address
          age: enrollment.age, # Age at project entry to keep report stable
          genders: client.gender,
          ethnicity: client.Ethnicity,
          races: client.race_fields,
          race_description: client.race_description,
          disabled: client_disabled?(client),
          hh_size: household.count,
          income: hoh_income, # HoH income
          female_hoh: enrollment.head_of_household? && client.Female == 1,
          any_veterans: household.map(&:VeteranStatus).any?(1),
          over_62_in_household: household.map(&:age).any? { |age| age.present? && age >= 62 },
          child_in_household: household.map(&:age).any? { |age| age.present? && age < 18 },
          disability_in_household: enrollment.household_enrollments.map(&:DisablingCondition).any?(1),
        }
      end.sort_by { |row| row[:service_date] }
    end

    private def client_disabled?(client)
      disabled_client_ids.include?(client.id)
    end

    private def disabled_client_ids
      @disabled_client_ids ||= GrdaWarehouse::Hud::Client.disabled_client_scope.
        where(id: client_ids).
        pluck(:id)
    end

    private def enrollment_scope
      scope = filter_for_user_access(GrdaWarehouse::ServiceHistoryEnrollment.entry)
      scope = filter_for_projects(scope)
      scope = filter_for_range(scope)

      scope
    end

    private def client_ids
      @client_ids ||= client_scope.pluck(:id)
    end

    private def client_scope
      client_source.
        distinct.
        joins(:service_history_enrollments).
        where(id: enrollment_scope.distinct.pluck(:client_id))
    end

    private def client_source
      GrdaWarehouse::Hud::Client.destination
    end
  end
end
