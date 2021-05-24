###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HapReport
  class Report < SimpleReports::ReportInstance
    include Queries
    after_find :set_attributes

    HAP_FUNDING = 'HAP Funded'.freeze

    attr_accessor :start_date, :end_date, :project_ids

    def build_report
      # create_universe
      report_labels.values.each do |sections|
        sections.values.each do |row_scope|
          project_columns.values.each do |column_scope|
            cell_name = "#{row_scope}_#{column_scope}"
            cell = report_cells.build(name: cell_name)
            if row_scope == :total_units_of_shelter_service
              cell.summary = report_client_scope.where(send(column_scope)).sum(a_t[:nights_in_shelter])
            else
              cell_scope = send(row_scope).where(send(column_scope))
              cell.add_members(cell_scope)
              cell.summary = cell_scope.count
            end
            cell.save!
          end
        end
      end
    end

    private def create_universe
      hap_clients = {}
      enrollment_scope.find_each do |processed_enrollment|
        disabilities = processed_enrollment.enrollment.disabilities
        mental_health = disabilities.chronically_disabled.mental.exists?
        substance_abuse = disabilities.chronically_disabled.substance.exists?

        health_and_dvs = processed_enrollment.enrollment.health_and_dvs
        domestic_violence = health_and_dvs.currently_fleeing.exists?

        income_benefits = processed_enrollment.enrollment.income_benefits
        income_at_start = income_benefits.at_entry.with_earned_income.pluck(:EarnedAmount).compact.max # Should be only one
        income_at_exit = income_benefits.at_exit.with_earned_income.pluck(:EarnedAmount).compact.max # Should be only one

        client = processed_enrollment.client
        nights_in_shelter = processed_enrollment.service_history_services.
          service_between(start_date: @start_date, end_date: @end_date).
          bed_night.
          count

        hap_client = hap_clients[processed_enrollment.client] || HapClient.new
        hap_clients[processed_enrollment.client] = HapClient.new(
          client_id: hap_client[:client_id] || processed_enrollment.client_id,
          age: hap_client[:age] || client.age,
          emancipated: false,
          head_of_household: hap_client[:head_of_household] || processed_enrollment.head_of_household,
          household_ids: (Array.wrap(hap_client[:household_ids]) << processed_enrollment.household_id).uniq,
          project_types: (Array.wrap(hap_client[:project_types]) << processed_enrollment.project_type).uniq,
          veteran: hap_client[:veteran] || processed_enrollment.client.veteran?,
          mental_health: hap_client[:mental_health] || mental_health,
          substance_abuse: hap_client[:substance_abuse] || substance_abuse,
          domestic_violence: hap_client[:domestic_violence] || domestic_violence,
          income_at_start: [hap_client[:income_at_start], income_at_start].compact.max,
          income_at_exit: [hap_client[:income_at_exit], income_at_exit].compact.max,
          homeless: hap_client[:homeless] || client.service_history_enrollments.homeless.open_between(start_date: @start_date, end_date: @end_date).exists?,
          nights_in_shelter: [hap_client[:nights_in_shelter], nights_in_shelter].compact.sum,
        )
      end
      HapClient.import(hap_clients.values)
      universe.add_universe_members(hap_clients)
    end

    def members_of_families_with_children
      report_client_scope.where(families_with_children)
    end

    def head_of_families_with_children
      members_of_families_with_children.where(head_of_household).distinct
    end

    def adults_in_families_with_children
      members_of_families_with_children.where(adults)
    end

    def children_in_families_with_children
      members_of_families_with_children.where(children)
    end

    def adults_in_adult_only_households
      report_client_scope.where(adult_only_households)
    end

    def head_of_adult_only_households
      adults_in_adult_only_households.where(head_of_household).distinct
    end

    def under_sixty_in_adult_only_households
      adults_in_adult_only_households.where(under_sixty)
    end

    def sixty_plus_in_adult_only_households
      adults_in_adult_only_households.where(sixty_plus)
    end

    def adults_served
      report_client_scope.where(individuals).where(adults)
    end

    def veterans_served
      report_client_scope.where(individuals).where(adults).where(veterans)
    end

    def adults_with_mh_services
      report_client_scope.where(individuals).where(adults).where(mh_services)
    end

    def adults_with_da_services
      report_client_scope.where(individuals).where(adults).where(da_services)
    end

    def adults_with_dv_services
      report_client_scope.where(individuals).where(adults).where(dv_services)
    end

    def adults_employed_at_start
      report_client_scope.where(individuals).where(adults).where(employed_at_start)
    end

    def adults_who_gained_employment
      report_client_scope.where(individuals).where(adults).where(gained_employment)
    end

    def adults_who_received_rental_assistance_for_multiple_crises
      report_client_scope.none
    end

    def adults_with_combined_rental_assistance_payments
      report_client_scope.none
    end

    def total_clients_served
      report_client_scope
    end

    def total_clients_denied
      report_client_scope.none
    end

    def total_near_homeless_served
      report_client_scope.none
    end

    def total_homeless_served
      report_client_scope.where(homeless)
    end

    def report_labels
      {
        'HOUSEHOLDS WITH CHILDREN' =>
          {
            'A. 1. Total number of unduplicated families with children served during fiscal year' => :head_of_families_with_children,
            'A. 2. Of the total in A1. how many were adults ' => :adults_in_families_with_children,
            'A. 3. Of the total in A1 how many were children ' => :children_in_families_with_children,
          },
        'ADULT-ONLY HOUSEHOLDS' =>
          {
            'B. 1. Total number of unduplicated adult-only households (with one or more adults) served year-to-date' => :head_of_adult_only_households,
            'B. 2. Of the total number of unduplicated adult-only households, what was the number of adults who resided in these households' => :adults_in_adult_only_households,
            'B.3. Of the total in B1, how many adults were age 59 years and younger?' => :under_sixty_in_adult_only_households,
            'B.4. Of the total in B1, how many adults were age 60 years and older?' => :sixty_plus_in_adult_only_households,
          },
        'UNDUPLICATED ADULTS' =>
          {
            'C. 1. Total number of unduplicated adults served during current fiscal year' => :adults_served,
            'C. 2. Of the total in C1, how many were veterans' => :veterans_served,
            'C. 3. Of the total in C1, how many unduplicated adults were referred to or from your agency or are currently receiving MH services' => :adults_with_mh_services,
            'C. 4. Of the total in C1, how many unduplicated adults were referred to or from your agency or are currently receiving D&A services' => :adults_with_da_services,
            'C. 5. Of the total in C1, how many unduplicated adults were referred to or from or are currently receiving Domestic Violence services' => :adults_with_dv_services,
            'C. 6. Of the total number of adults served in C1, how many were employed at the point of intake?' => :adults_employed_at_start,
            'C. 7. Of the total in C1, how many who were not employed at intake were employed when exiting services?' => :adults_who_gained_employment,
            'C. 8. Of the total in C1, how many received Rental Assistance for more than one housing crisis during their 24-month period' => :adults_who_received_rental_assistance_for_multiple_crises,
            'C. 9. Of the total in C1, how many clients received a combined Rental Assistance/ESA payment? ' => :adults_with_combined_rental_assistance_payments,
          },
        'UNDUPLICATED ADULTS & CHILDREN' =>
          {
            'D. Total number of unduplicated adults & children served during fiscal year (A.2.+A.3.+B.2.)' => :total_clients_served,
            'E. Total number of adults and children who were denied services due to lack of funding' => :total_clients_denied,
            'F. The total number of adults and children for which eviction was resolved (near - homeless served)' => :total_near_homeless_served,
            'G. The total number of adults and children served who were homeless. (Homeless served)' => :total_homeless_served,
            'H. Total units of service provided in Mass and Individual Shelters' => :total_units_of_shelter_service,
          },
      }.freeze
    end

    def project_columns
      {
        'Bridge Housing' => :bridge_housing,
        'Case Management' => :case_management,
        'Rental Assistance' => :rental_assistance,
        'Emergency Shelter' => :emergency_shelter,
        'Innovative Supportive Housing' => :innovative,
        'TOTAL NUMBER SERVED ACROSS HAP COMPONENTS - UNDUPLICATED' => :total,
      }.freeze
    end

    def enrollment_scope
      GrdaWarehouse::ServiceHistoryEnrollment.
        entry.
        preload(:client, enrollment: [:disabilities, :health_and_dvs, :income_benefits]).
        where(project_id: @project_ids).
        open_between(start_date: @start_date, end_date: @end_date)
    end

    def self.hap_projects(user)
      GrdaWarehouse::Hud::Project.
        joins(:funders).
        merge(GrdaWarehouse::Hud::Funder.funding_source(funder_code: 46, other: HAP_FUNDING)).
        viewable_by(user)
    end

    private def report_client_scope
      universe.members
    end

    private def set_attributes
      @start_date = options['start_date'].to_date
      @end_date = options['end_date'].to_date
      @project_ids = options['project_ids'].map(&:to_i)
    end
  end
end
