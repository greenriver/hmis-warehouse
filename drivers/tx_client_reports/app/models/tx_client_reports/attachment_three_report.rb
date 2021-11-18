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
        ).
        where(client_id: client_ids).
        order(first_date_in_program: :desc). # index by uses the last value, so this selects the oldest enrollment
        index_by(&:client_id)

      client_scope.map do |client|
        enrollment = enrollments[client.id]
        program_name = enrollment.project.ProjectName
        hoh_income = enrollment.
          service_history_enrollment_for_head_of_household&.
          enrollment&.
          income_benefits_at_entry&.
          TotalMonthlyIncome

        {
          program_name: program_name,
          service_date: enrollment.first_date_in_program,
          fort_worth_resident: nil, # leave blank
          service_location: nil, # leave blank
          client_name: client.name,
          street_address: enrollment.project.project_cocs&.first&.Address1, # Shelter address
          age: enrollment.age, # Age at project entry to keep report stable
          genders: client.gender,
          ethnicity: client.Ethnicity,
          races: client.race_fields,
          disabled: client_disabled?(client),
          hh_size: 1 + enrollment.other_clients_over_25 + enrollment.other_clients_under_18 + enrollment.other_clients_between_18_and_25, # Sum household members
          income: hoh_income, # HoH income
          female_hoh: enrollment.head_of_household? && client.Female == 1,
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
