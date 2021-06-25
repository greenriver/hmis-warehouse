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
      report_scope.preload(:client, enrollment: :income_benefits)
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
      add_clients(report_clients, period: :current)
      if include_comparison?
        to_comparison
        add_clients(report_clients, period: :prior)
        to_report_period
      end
    end

    private def add_clients(report_clients, period:)
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

      inflow_report = run_inflow
      entry_client_ids = inflow_report.first_time_clients.pluck(:client_id)
      re_entry_client_ids = inflow_report.re_entry_clients.pluck(:client_id)

      outflow_report = run_outflow
      outflow_client_ids = outflow_report.client_outflow
      moved_to_housing_client_ids = outflow_report.hoh_exits_to_ph
      inactive_client_ids = outflow_client_ids - moved_to_housing_client_ids

      enrollment_scope.find_in_batches do |batch|
        batch.each do |processed_enrollment|
          client = processed_enrollment.client
          client_id = processed_enrollment.client_id
          caper_client = caper_clients[client_id]
          spm_client = spm_clients[client_id]
          rrh_client = rrh_clients[client_id]
          psh_client = psh_clients[client_id]
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

          first_time = client_id.in?(entry_client_ids)
          reentering = client_id.in?(re_entry_client_ids)

          in_outflow = client_id.in?(outflow_client_ids)
          entering_housing = client_id.in?(moved_to_housing_client_ids)
          inactive = client_id.in?(inactive_client_ids)

          existing_client = report_clients[processed_enrollment.client] || Client.new
          new_client = Client.new(
            client_id: existing_client[:client_id] || client_id,
            "#{period}_period_age" => existing_client[:age] || client.age_on(filter.start),
            "#{period}_period_earned_income_at_start" => earned_income_at_start,
            "#{period}_period_earned_income_at_exit" => earned_income_at_exit,
            "#{period}_period_other_income_at_start" => other_income_at_start,
            "#{period}_period_other_income_at_exit" => other_income_at_exit,
            "#{period}_period_days_in_es" => days_in_es,
            "#{period}_period_days_in_rrh" => days_in_rrh,
            "#{period}_period_days_in_psh" => days_in_psh,
            "#{period}_period_first_time" => first_time,
            "#{period}_period_reentering" => reentering,
            "#{period}_period_in_outflow" => in_outflow,
            "#{period}_period_entering_housing" => entering_housing,
            "#{period}_period_inactive" => inactive,
            "#{period}_period_caper" => caper_report.id,
            "#{period}_period_spm" => spm_report.id,
          )

          report_clients[client] = new_client
        end
        Client.import(report_clients.values)
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
      spm_filter = HudSpmReport::Filters::SpmFilter.new(user_id: filter.user_id).update(filter.to_h)
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

    private def run_psh
      psh_filter = WarehouseReport::Outcomes::OutcomesFilter.new(user_id: filter.user_id)
      psh_filter.update(filter.to_h)
      psh_filter.project_type_numbers = [3, 9, 10]
      WarehouseReport::Outcomes::PshReport.new(psh_filter)
    end

    private def run_outflow
      outflow_filter = ::Filters::OutflowReport.new(user_id: filter.user_id)
      outflow_filter.update(filter.to_h)
      GrdaWarehouse::WarehouseReports::OutflowReport.new(outflow_filter, filter.user)
    end

    private def run_inflow
      inflow_filter = ::Filters::FilterBase.new(
        user_id: filter.user_id,
        enforce_one_year_range: false
      )
      inflow_filter.update(filter.to_h)
      report = Reporting::MonthlyReports::Base.class_for(inflow_filter.sub_population).new(
        user: inflow_filter.user,
        filter: inflow_filter,
      )
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
