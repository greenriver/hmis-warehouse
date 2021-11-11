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
      enrollments = enrollment_scope.
        preload(
          :service_history_services,
          service_history_enrollment_for_head_of_household: { enrollment: :income_benefits },
          project: :project_cocs,
        ).
        where(client_id: client_scope.select(:id)).
        order(first_date_in_program: :asc).
        group_by(&:client_id)

      client_scope.
        map do |client|
          enrollment = enrollments[client.id].first
          program_name = enrollment.project.ProjectName
          bed_night = enrollment.service_history_services.order(date: :asc).bed_night.first
          hoh_income = enrollment.
            service_history_enrollment_for_head_of_household.
            enrollment.
            income_benefits_at_entry.
            TotalMonthlyIncome

          {
            program_name: program_name,
            service_date: bed_night&.date || enrollment.first_date_in_program, # first bed night, or entry date
            fort_worth_resident: nil, # leave blank
            service_location: nil, # leave blank
            client_name: client.name,
            street_address: enrollment.project.project_cocs.first.Address1, # Shelter address
            age: client.age,
            genders: client.gender,
            ethnicity: client.Ethnicity,
            races: client.race_fields,
            disabled: client.currently_disabled?,
            hh_size: 1 + enrollment.other_clients_over_25 + enrollment.other_clients_under_18 + enrollment.other_clients_between_18_and_25, # Sum household membmers
            income: hoh_income, # HoH income
            female_hoh: enrollment.head_of_household? && client.Female == 1,
          }
        end.sort_by { |row| row[:service_date] }
    end

    private def enrollment_scope
      enrollment_scope = filter_for_user_access(GrdaWarehouse::ServiceHistoryEnrollment.entry)
      enrollment_scope = filter_for_projects(enrollment_scope)
      enrollment_scope = filter_for_range(enrollment_scope)

      enrollment_scope
    end

    private def client_scope
      client_scope = client_source.
        distinct.
        joins(:service_history_enrollments).
        where(id: enrollment_scope.select(:client_id))

      client_scope
    end

    private def client_source
      GrdaWarehouse::Hud::Client.destination
    end
  end
end
