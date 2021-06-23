###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceMetrics
  class Report < SimpleReports::ReportInstance
    include Filter::ControlSections
    include Filter::FilterScopes
    include Reporting::Status
    include Rails.application.routes.url_helpers
    include ActionView::Helpers::NumberHelper
    include ArelHelper

    acts_as_paranoid

    belongs_to :user
    has_many :clients

    after_initialize :filter

    # NOTE: this differs from viewable_by which looks at the report definitions
    scope :visible_to, ->(user) do
      return all if user.can_view_all_reports?
      return where(user_id: user.id) if user.can_view_assigned_reports?

      none
    end

    scope :ordered, -> do
      order(updated_at: :desc)
    end

    def run_and_save!
      start
      create_universe
      comparison_periods.each do |period|
        report_labels.values.each do |sections|
          sections.values.each do |row_scope|
            # project_columns.values.each do |column_scope|
            #   cell_name = "#{row_scope}_#{column_scope}"
            #   next if blank_cells.include?(cell_name)

            #   cell = report_cells.create(name: cell_name)
            #   if row_scope == :total_units_of_shelter_service
            #     cell.summary = report_client_scope.where(send(column_scope)).sum(a_t[:nights_in_shelter])
            #   else
            #     cell_scope = send(row_scope).where(send(column_scope))
            #     cell.add_members(cell_scope)
            #     cell.summary = cell_scope.count
            #   end
            #   cell.save!
            # end
          end
        end
      end
      complete
    end

    private def comparison_periods
      @comparison_periods ||= begin
        periods = [filter.range]
        periods << filter.to_comparison.range if include_comparison?
      end
    end

    def start
      update(started_at: Time.current)
    end

    def complete
      update(completed_at: Time.current)
    end

    def filter=(filter_object)
      self.options = filter_object.to_h
      # force reset the filter cache
      @filter = nil
      filter
    end

    def filter
      @filter ||= begin
        f = ::Filters::FilterBase.new(user_id: user_id)
        f.update(options.with_indifferent_access) if options.present?
        f
      end
    end

    private def to_comparison
      @original_filter = @filter
      @filter = filter.to_comparison
    end

    private def to_report_period
      @filter = @original_filter
    end

    def comparison_pattern
      @comparison_pattern ||= filter.comparison_pattern
    end

    def self.comparison_patterns
      {
        no_comparison_period: 'None',
        prior_year: 'Same period, prior year',
        prior_period: 'Prior Period',
      }.invert.freeze
    end

    def self.viewable_by(user)
      GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: url).
        viewable_by(user).exists?
    end

    def self.url
      'performance_metrics/warehouse_reports/report'
    end

    def url
      performance_metrics_warehouse_reports_report_url(host: ENV.fetch('FQDN'), id: id, protocol: 'https')
    end

    def title
      _('Performance Metrics')
    end

    def multiple_project_types?
      true
    end

    protected def build_control_sections
      # ensure filter has been set
      filter
      [
        build_general_control_section,
        build_coc_control_section,
        build_household_control_section,
        build_demographics_control_section,
      ]
    end

    def report_path_array
      [
        :performance_metrics,
        :warehouse_reports,
        :reports,
      ]
    end

    def include_comparison?
      comparison_pattern != :no_comparison_period
    end

    # @return filtered scope
    def report_scope
      # Report range
      scope = report_scope_source
      scope = filter_for_user_access(scope)
      scope = filter_for_range(scope)
      scope = filter_for_cocs(scope)
      scope = filter_for_sub_population(scope)
      scope = filter_for_household_type(scope)
      scope = filter_for_head_of_household(scope)
      scope = filter_for_age(scope)
      scope = filter_for_gender(scope)
      scope = filter_for_race(scope)
      scope = filter_for_ethnicity(scope)
      scope = filter_for_veteran_status(scope)
      scope = filter_for_project_type(scope)
      scope = filter_for_data_sources(scope)
      scope = filter_for_organizations(scope)
      scope = filter_for_projects(scope)
      scope = filter_for_funders(scope)
      scope = filter_for_ca_homeless(scope)
    end

    def enrollment_scope
      report_scope.preload(enrollment: :income_benefits)
    end

    def report_scope_source
      GrdaWarehouse::ServiceHistoryEnrollment.entry
    end

    def can_see_client_details?(user)
      user.can_access_some_version_of_clients?
    end

    def yn(boolean)
      boolean ? 'Yes' : 'No'
    end

    def report_labels
      {
        'People Served' => {
          'Clients' => :enrolled_clients,
        },
      }.freeze
    end

    private def create_universe
      report_clients = {}
      add_clients(report_clients)
      if include_comparison?
        to_comparison
        add_clients(report_clients)
        to_report_period
      end
    end

    private def add_clients(report_clients)
      caper_report = run_caper
      caper_clients = answer_clients(caper_report, 'Q16', 'D14')
      adult_leaver_count = answer(caper_report, 'Q5a', 'B6')

      spm_report = run_spm
      spm_clients = answer_clients(spm_report, '2', 'J7')
      exited_spm_clients = answer(spm_report, '2', 'B7')

      rrh_report = run_rrh
      rrh_clients = rrh_report.support_for(
        :time_in_stabilization,
        {
          selected_project: 'All',
          start_date: filter.start,
          end_date: filter.end,
        },
      ).to_h.index_by{ |m| m['Warehouse ID'] }

      psh_report = run_psh
      psh_clients = run_psh.support_for(
        :time_in_stabilization,
        {
          selected_project: 'All',
          start_date: filter.start,
          end_date: filter.end,
        },
      ).to_h.index_by{ |m| m['Warehouse ID'] }

      # TODO: inflow

      outflow_report = run_outflow
      # TODO: from outflow_report
      outflow_count
      moved_to_housing_count
      inactive_count

      enrollment_scope.find_in_batches do |batch|
        batch.each do |processed_enrollment|
          caper_client = caper_clients[processed_enrollment.client_id]
          spm_client = spm_clients[processed_enrollment.client_id]
          rrh_client = rrh_clients[processed_enrollment.client_id]
          psh_client = psh_clients[processed_enrollment.client_id]
          # Only looking at income for leavers
          earned_income_at_start = caper_client.income_sources_at_start['EarnedAmount'] || 0
          earned_income_at_exit = caper_client.income_sources_at_exit['EarnedAmount'] || 0
          other_income_at_start = caper_client.income_total_at_start - earned_income_at_start
          other_income_at_exit = caper_client.income_total_at_exit - earned_income_at_exit

          days_in_es = spm_client&.m1a_es_sh_th_days

          housed_date = rrh_client['Date Housed']
          exit_date = rrh_client['Housing Exit']
          days_in_rrh = (exit_date - housed_date).to_i

          housed_date = psh_client['Date Housed']
          exit_date = psh_client['Housing Exit']
          days_in_psh = (exit_date - housed_date).to_i


          # client = processed_enrollment.client
          # nights_in_shelter = processed_enrollment.service_history_services.
          #   service_between(start_date: @start_date, end_date: @end_date).
          #   bed_night.
          #   count

          # household_id = processed_enrollment.household_id || "#{processed_enrollment.enrollment_group_id}*hh"
          # head_of_household = if processed_enrollment.household_id
          #   processed_enrollment.head_of_household?
          # else
          #   true
          # end

          # existing_client = report_clients[processed_enrollment.client] || HapClient.new
          # new_client = HapClient.new(
          #   client_id: existing_client[:client_id] || processed_enrollment.client_id,
          #   age: existing_client[:age] || client.age,
          #   emancipated: false,
          #   head_of_household: existing_client[:head_of_household] || head_of_household,
          #   household_ids: (Array.wrap(existing_client[:household_ids]) << household_id).uniq,
          #   project_types: (Array.wrap(existing_client[:project_types]) << processed_enrollment.project_type).uniq,
          #   veteran: existing_client[:veteran] || processed_enrollment.client.veteran?,
          #   mental_health: existing_client[:mental_health] || mental_health,
          #   substance_use_disorder: existing_client[:substance_use_disorder] || substance_use_disorder,
          #   domestic_violence: existing_client[:domestic_violence] || domestic_violence,
          #   income_at_start: [existing_client[:income_at_start], income_at_start].compact.max,
          #   income_at_exit: [existing_client[:income_at_exit], income_at_exit].compact.max,
          #   homeless: existing_client[:homeless] || client.service_history_enrollments.homeless.open_between(start_date: @start_date, end_date: @end_date).exists?,
          #   nights_in_shelter: [existing_client[:nights_in_shelter], nights_in_shelter].compact.sum,
          # )
          # new_client[:head_of_household_for] = if head_of_household
          #   (Array.wrap(existing_client[:head_of_household_for])) << household_id
          # else
          #   existing_client[:head_of_household_for] || []
          # end

          # report_clients[client] = new_client
        end
        HapClient.import(report_clients.values)
        universe.add_universe_members(report_clients)
      end
    end

    private def run_caper
      # Run CAPER Q5 to get Q5a B6 (adult leavers) for the denominator
      # Looking for CAPER Q16 D14 to identify leavers who had income at exit (we'll only take those with an increase as the numerator)
      questions = [
        'Question 5',
        'Question 16',
      ]
      caper_filter = HudApr::Filters::AprFilter.new(user_id: filter.user_id).update(filter.to_h)
      generator = HudApr::Generators::Caper::Fy2020::Generator
      caper_report = HudReports::ReportInstance.from_filter(caper_filter, generator.title, build_for_questions: questions)
      generator.new(caper_report).run!(email: false)
      caper_report
    end

    private def answer(report, table, cell)
      report.answer(question: table, cell: cell).summary
    end

    private def answer_clients(report, table, cell)
      report.answer(question: table, cell: cell).universe_members.
        map(&:universe_membership).
        index_by(&:client_id)
    end

    private def run_spm
      # Looking for SPM Measure 1A E3
      # Looking for SPM Measure 2 J7 (total returns to homelessness within 2 years)
      questions = [
        'Measure 1',
        'Measure 2',
      ]
      spm_filter = HudApr::Filters::SpmFilter.new(user_id: filter.user_id).update(filter.to_h)
      generator = HudSpmReport::Generators::Fy2020::Generator
      spm_report = HudReports::ReportInstance.from_filter(spm_filter, generator.title, build_for_questions: questions)
      generator.new(spm_report).run!(email: false)
      spm_report
    end

    private def run_rrh
      rrh_filter = WarehouseReport::Outcomes::OutcomesFilter.new(user_id: filter.user_id)
      rrh_filter.update(filter.to_h)
      rrh_filter.project_type_numbers = [13]
      WarehouseReport::Outcomes::RrhReport.new(rrh_filter)
    end

    private def run_outflow
      outflow_filter = ::Filters::OutflowReport.new(user_id: filter.user_id)
      outflow_filter.update(filter.to_h)
      GrdaWarehouse::WarehouseReports::OutflowReport.new(outflow_filter, filter.user)
    end

    # private def outflow_clients(report)
    #   enrollment_scope = report.entries_scope.
    #     residential.
    #     joins(:client).
    #     preload(:client).
    #     order(c_t[:LastName], c_t[:FirstName])
    #   key = report.metrics.keys.detect { |key| key.to_s == params[:key] }
    #   enrollments = enrollment_scope.where(client_id: report.send(key)).group_by(&:client_id)
    # end
  end
end
