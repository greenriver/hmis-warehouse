###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module MaReports::MonthlyPerformance
  class Report < SimpleReports::ReportInstance
    include Rails.application.routes.url_helpers
    include Reporting::Status
    # after_initialize :set_attributes

    def run_and_save!
      start
      create_universe

      # run!
      complete
    end

    def start
      update(started_at: Time.current)
    end

    def complete
      update(completed_at: Time.current)
    end

    def title
      'Project Utilization by Month'
    end

    def filter
      @filter ||= begin
        f = Filters::FilterBase.new(user_id: user_id, enforce_one_year_range: false)
        f.update(options)
      end
    end

    def url
      warehouse_reports_monthly_project_utilization_url(host: ENV.fetch('FQDN'), id: id, protocol: 'https')
    end

    private def create_universe
      enrollment_scope.find_in_batches do |batch|
        # hap_clients = {}
        # batch.each do |processed_enrollment|
        #   disabilities = processed_enrollment.enrollment.disabilities
        #   mental_health = disabilities.chronically_disabled.mental.exists?
        #   substance_use_disorder = disabilities.chronically_disabled.substance.exists?

        #   health_and_dvs = processed_enrollment.enrollment.health_and_dvs
        #   domestic_violence = health_and_dvs.currently_fleeing.exists?

        #   income_benefits = processed_enrollment.enrollment.income_benefits
        #   income_at_start = income_benefits.at_entry.with_earned_income.pluck(:EarnedAmount).compact.max # Should be only one
        #   income_at_exit = income_benefits.at_exit.with_earned_income.pluck(:EarnedAmount).compact.max # Should be only one

        #   client = processed_enrollment.client
        #   nights_in_shelter = processed_enrollment.service_history_services.
        #     service_between(start_date: @start_date, end_date: @end_date).
        #     bed_night.
        #     count

        #   household_id = processed_enrollment.household_id || "#{processed_enrollment.enrollment_group_id}*hh"
        #   head_of_household = if processed_enrollment.household_id
        #     processed_enrollment.head_of_household?
        #   else
        #     true
        #   end

        #   existing_client = hap_clients[processed_enrollment.client] || HapClient.new
        #   new_client = HapClient.new(
        #     client_id: existing_client[:client_id] || processed_enrollment.client_id,
        #     age: existing_client[:age] || client.age([@start_date, processed_enrollment.first_date_in_program].max),
        #     emancipated: false,
        #     head_of_household: existing_client[:head_of_household] || head_of_household,
        #     household_ids: (Array.wrap(existing_client[:household_ids]) << household_id).uniq,
        #     project_types: (Array.wrap(existing_client[:project_types]) << processed_enrollment.project_type).uniq,
        #     veteran: existing_client[:veteran] || processed_enrollment.client.veteran?,
        #     mental_health: existing_client[:mental_health] || mental_health,
        #     substance_use_disorder: existing_client[:substance_use_disorder] || substance_use_disorder,
        #     domestic_violence: existing_client[:domestic_violence] || domestic_violence,
        #     income_at_start: [existing_client[:income_at_start], income_at_start].compact.max,
        #     income_at_exit: [existing_client[:income_at_exit], income_at_exit].compact.max,
        #     homeless: existing_client[:homeless] || client.service_history_enrollments.homeless.open_between(start_date: @start_date, end_date: @end_date).exists?,
        #     nights_in_shelter: [existing_client[:nights_in_shelter], nights_in_shelter].compact.sum,
        #   )
        #   new_client[:head_of_household_for] = if head_of_household
        #     (Array.wrap(existing_client[:head_of_household_for])) << household_id
        #   else
        #     existing_client[:head_of_household_for] || []
        #   end

        #   hap_clients[client] = new_client
        # end
        # HapClient.import(hap_clients.values)
        # universe.add_universe_members(hap_clients)
      end
    end

    def enrollment_scope
      scope = GrdaWarehouse::ServiceHistoryEnrollment.
        entry.
        preload(:client, enrollment: [:exit])
      filter.apply(scope)
    end

    private def report_client_scope
      universe.members
    end
  end
end
