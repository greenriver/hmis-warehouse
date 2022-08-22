###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
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

    belongs_to :user, optional: true
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

    # Sections
    def clients_served
      @clients_served ||= begin
        columns = []
        columns << ['Prior Period', clients.served(:prior).count] if include_comparison?
        columns << ['Current Period', clients.served(:current).count]
        columns
      end
    end

    def returns
      @returns ||= begin
        returns = []
        if include_comparison?
          period = :prior
          no_return_count = clients.did_not_return_in_two_years(period).count
          returned_count = clients.returned_in_two_years(period).count
          returns << [
            'Prior Period',
            [
              ['Returned to Homelessness Within 2 Years', returned_count],
              ['Did not return', no_return_count],
            ],
          ]
        end
        period = :current
        no_return_count = clients.did_not_return_in_two_years(period).count
        returned_count = clients.returned_in_two_years(period).count
        returns << [
          'Current Period',
          [
            ['Returned to Homelessness Within 2 Years', returned_count],
            ['Did not return', no_return_count],
          ],
        ]
        returns
      end
    end

    def entering_housing
      @entering_housing ||= begin
        entering = []
        if include_comparison?
          entering << [
            'Prior Period',
            clients.entering_housing(:prior).count,
          ]
        end
        entering << [
          'Current Period',
          clients.entering_housing(:current).count,
        ]
        entering
      end
    end

    def income
      @income ||= begin
        incomes = []
        if include_comparison?
          period = :prior
          clients_served = clients.served(period).count
          with_increased_earned_income = clients.with_increased_earned_income(period).count
          percentage_earned_change = 0
          percentage_earned_change = (with_increased_earned_income / clients_served.to_f * 100).round if clients_served.positive?

          with_increased_other_income = clients.with_increased_other_income(period).count
          percentage_other_change = 0
          percentage_other_change = (with_increased_other_income / clients_served.to_f * 100).round if clients_served.positive?
          incomes << [
            'Prior Period', [
              ['Employment Income', percentage_earned_change],
              ['Non-Employment Income', percentage_other_change],
            ]
          ]
        end
        period = :current
        clients_served = clients.served(period).count
        with_increased_earned_income = clients.with_increased_earned_income(period).count
        percentage_earned_change = 0
        percentage_earned_change = (with_increased_earned_income / clients_served.to_f * 100).round if clients_served.positive?

        with_increased_other_income = clients.with_increased_other_income(period).count
        percentage_other_change = 0
        percentage_other_change = (with_increased_other_income / clients_served.to_f * 100).round if clients_served.positive?

        incomes << [
          'Current Period', [
            ['Employment Income', percentage_earned_change],
            ['Non-Employment Income', percentage_other_change],
          ]
        ]
      end
    end

    def average_stay_length
      @average_stay_length ||= begin
        stay_lengths = []
        if include_comparison?
          period = :prior
          es = clients.with_es_stay(period)
          es_count = es.count
          es_length = es.sum("#{period}_period_days_in_es")
          es_average = 0
          es_average = (es_length / es_count).round if es_count.positive?

          rrh = clients.with_rrh_stay(period)
          rrh_count = rrh.count
          rrh_length = rrh.sum("#{period}_period_days_in_rrh")
          rrh_average = 0
          rrh_average = (rrh_length / rrh_count).round if rrh_count.positive?

          psh = clients.with_psh_stay(period)
          psh_count = psh.count
          psh_length = psh.sum("#{period}_period_days_in_psh")
          psh_average = 0
          psh_average = (psh_length / psh_count).round if psh_count.positive?
          stay_lengths << [
            'Prior Period', [
              ['Emergency Shelter', es_average],
              ['Rapid Rehousing', rrh_average],
              ['PSH', psh_average],
            ]
          ]
        end
        period = :current
        es = clients.with_es_stay(period)
        es_count = es.count
        es_length = es.sum("#{period}_period_days_in_es")
        es_average = 0
        es_average = (es_length / es_count).round if es_count.positive?

        rrh = clients.with_rrh_stay(period)
        rrh_count = rrh.count
        rrh_length = rrh.sum("#{period}_period_days_in_rrh")
        rrh_average = 0
        rrh_average = (rrh_length / rrh_count).round if rrh_count.positive?

        psh = clients.with_psh_stay(period)
        psh_count = psh.count
        psh_length = psh.sum("#{period}_period_days_in_psh")
        psh_average = 0
        psh_average = (psh_length / psh_count).round if psh_count.positive?
        stay_lengths << [
          'Current Period', [
            ['Emergency Shelter', es_average],
            ['Rapid Rehousing', rrh_average],
            ['PSH', psh_average],
          ]
        ]
        stay_lengths
      end
    end

    def inflow_outflow
      @inflow_outflow ||= begin
        flows = []
        if include_comparison?
          period = :prior
          percent_entering_housing = 0
          percent_entering_housing = ((clients.entered_housing(period).count / clients.served(period).count.to_f) * 100).round if clients.served(period).count.positive?
          flows << [
            'Prior Period', [
              ['Inflow', clients.in_inflow(period).count],
              ['Outflow', clients.in_outflow(period).count],
              ['First Time', clients.first_time(period).count],
              ['Re-entering', clients.reentering(period).count],
              ['Entered Housing', clients.entered_housing(period).count],
              ['Entered Housing %', "#{percent_entering_housing} %"],
              ['Inactive', clients.inactive(period).count],
            ]
          ]
        end
        period = :current
        percent_entering_housing = 0
        percent_entering_housing = ((clients.entered_housing(period).count / clients.served(period).count.to_f) * 100).round if clients.served(period).count.positive?
        flows << [
          'Current Period', [
            ['Inflow', clients.in_inflow(period).count],
            ['Outflow', clients.in_outflow(period).count],
            ['First Time', clients.first_time(period).count],
            ['Re-entering', clients.reentering(period).count],
            ['Entered Housing', clients.entered_housing(period).count],
            ['Entered Housing %', "#{percent_entering_housing} %"],
            ['Inactive', clients.inactive(period).count],
          ]
        ]

        flows
      end
    end
    # End Sections

    def comparison_periods
      @comparison_periods ||= begin
        periods = []
        periods << filter.to_comparison.range if include_comparison?
        periods << filter.range
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

    private def available_support
      {
        clients_served: {
          title: _('Clients Served'),
          clients_served: {
            scope: :served,
            title: '',
          },
        },
        returns: {
          title: _('Returns to Homelessness'),
          in_outflow: {
            scope: :did_not_return_in_two_years,
            title: 'Did Not Return Within 2 Years',
          },
          returned_in_two_years: {
            scope: :returned_in_two_years,
            title: 'Returned to Homelessness Within 2 Years',
          },
        },
        entering_housing: {
          title: _('Clients moving into permanent housing'),
          entering_housing: {
            scope: :entering_housing,
            title: '',
          },
        },
        income: {
          title: _('Percentage of clients with increased income'),
          with_increased_earned_income: {
            scope: :with_increased_earned_income,
            title: 'Employment Income',
          },
          with_increased_other_income: {
            scope: :with_increased_other_income,
            title: 'Non-Employment Income',
          },
        },
        average_stay_length: {
          title: _('Average length of stay'),
          with_es_stay: {
            scope: :with_es_stay,
            title: 'Emergency Shelter',
          },
          with_rrh_stay: {
            scope: :with_rrh_stay,
            title: 'Rapid Rehousing',
          },
          with_psh_stay: {
            scope: :with_psh_stay,
            title: 'PSH',
          },
        },
        inflow_outflow: {
          title: _('Inflow / Outflow'),
          in_inflow: {
            scope: :in_inflow,
            title: 'Inflow',
          },
          in_outflow: {
            scope: :in_outflow,
            title: 'Outflow',
          },
          first_time: {
            scope: :first_time,
            title: 'First Time',
          },
          reentering: {
            scope: :reentering,
            title: 'Re-entering',
          },
          entered_housing: {
            scope: :entered_housing,
            title: 'Entered Housing',
          },
          inactive: {
            scope: :inactive,
            title: 'Inactive',
          },
        },
      }.freeze
    end

    def support_title(key)
      support = available_support[key.to_sym]
      return unless support

      support[:title]
    end

    def detail_scope(key, sub_key, comparison)
      support = available_support[key.to_sym]
      return clients.none unless support

      sub_support = support[sub_key.to_sym]
      return unless sub_support

      period = :current
      period = :prior if comparison

      clients.send(sub_support[:scope], period)
    end

    def header_for(key, sub_key)
      support = available_support[key.to_sym]
      return unless support

      sub_support = support[sub_key.to_sym]
      return unless sub_support

      sub_support[:title]
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
      scope = filter_for_ce_cls_homeless(scope)
      scope = filter_for_cohorts(scope)
      scope
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
      return unless include_comparison?

      to_comparison
      add_clients(report_clients, period: :prior)
      to_report_period
    end

    private def add_clients(report_clients, period:)
      caper_report = run_caper
      # Q16 D14 is Total Adults - Income at Exit for Leavers
      caper_clients = answer_clients(caper_report, 'Q16', 'D14')

      rrh_clients = run_rrh.support_for(
        :time_in_stabilization,
        {
          selected_project: 'All',
          start_date: filter.start,
          end_date: filter.end,
        },
      ).to_h.index_by { |m| m['Warehouse ID'] }

      psh_clients = run_psh.support_for(
        :time_in_stabilization,
        {
          selected_project: 'All',
          start_date: filter.start,
          end_date: filter.end,
        },
      ).to_h.index_by { |m| m['Warehouse ID'] }

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
          next unless client

          earned_income_at_start = nil
          earned_income_at_exit = nil
          other_income_at_start = nil
          other_income_at_exit = nil
          days_in_rrh = nil
          days_in_psh = nil

          client_id = processed_enrollment.client_id
          caper_client = caper_clients[client_id]
          rrh_client = rrh_clients[client_id]
          psh_client = psh_clients[client_id]
          # Only looking at income for leavers
          caper_leaver = false
          if caper_client
            earned_income_at_start = caper_client.income_sources_at_start['EarnedAmount'] || 0
            earned_income_at_exit = caper_client.income_sources_at_exit['EarnedAmount'] || 0
            other_income_at_start = caper_client.income_total_at_start.to_i - earned_income_at_start.to_i
            other_income_at_exit = caper_client.income_total_at_exit.to_i - earned_income_at_exit.to_i
            caper_leaver = true
          end

          if rrh_client
            housed_date = rrh_client['Date Housed']
            exit_date = rrh_client['Housing Exit']
            days_in_rrh = (exit_date - housed_date).to_i
          end

          if psh_client
            housed_date = psh_client['Date Housed']
            exit_date = psh_client['Housing Exit']
            days_in_psh = (exit_date - housed_date).to_i
          end

          first_time = client_id.in?(entry_client_ids)
          reentering = client_id.in?(re_entry_client_ids)

          in_outflow = client_id.in?(outflow_client_ids)
          entering_housing = client_id.in?(moved_to_housing_client_ids)
          inactive = client_id.in?(inactive_client_ids)

          report_client = report_clients[client_id] || Client.new
          report_client.assign_attributes(
            client_id: client_id,
            first_name: client.FirstName,
            last_name: client.LastName,
            report_id: id,
            "include_in_#{period}_period" => true,
            "#{period}_period_age" => client.age_on(filter.start),
            "#{period}_period_earned_income_at_start" => earned_income_at_start,
            "#{period}_period_earned_income_at_exit" => earned_income_at_exit,
            "#{period}_period_other_income_at_start" => other_income_at_start,
            "#{period}_period_other_income_at_exit" => other_income_at_exit,
            "#{period}_caper_leaver" => caper_leaver,
            "#{period}_period_days_in_rrh" => days_in_rrh,
            "#{period}_period_days_in_psh" => days_in_psh,
            "#{period}_period_first_time" => first_time,
            "#{period}_period_reentering" => reentering,
            "#{period}_period_in_outflow" => in_outflow,
            "#{period}_period_entering_housing" => entering_housing,
            "#{period}_period_inactive" => inactive,
            "#{period}_period_caper_id" => caper_report.id,
          )
          report_clients[client_id] = report_client
        end

        # NOTE: SPM has a 2 year look-back so they may not be in the enrolled clients
        spm_report = run_spm
        # M2 B7 is TOTAL Returns to Homeless - Number of Returns in 2 Years
        spm_returners = answer_clients(spm_report, '2', 'I7')
        # M2 I7 is Total Number of Persons who Exited to a Permanent Housing Destination (2 Years Prior)
        spm_leavers = answer_clients(spm_report, '2', 'B7')
        spm_leavers.each do |client_id, spm_client|
          days_in_es = nil
          days_to_return = nil

          spm_returner = spm_returners[client_id]
          spm_leaver = spm_leavers.keys.include?(client_id)
          if spm_returner
            days_in_es = spm_returner.m1a_es_sh_th_days
            days_to_return = spm_returner.m2_reentry_days
          end
          report_client = report_clients[client_id] || Client.new
          report_client.assign_attributes(
            client_id: client_id,
            first_name: spm_client.first_name,
            last_name: spm_client.last_name,
            report_id: id,
            "#{period}_period_days_in_es" => days_in_es,
            "#{period}_period_days_to_return" => days_to_return,
            "#{period}_period_spm_leaver" => spm_leaver,
            "#{period}_period_spm_id" => spm_report.id,
          )
          report_clients[client_id] = report_client
        end

        Client.import(
          report_clients.values,
          on_duplicate_key_update: {
            conflict_target: [:id],
            columns: Client.attribute_names.map(&:to_sym),
          },
        )
        universe.add_universe_members(report_clients)
      end
    end

    private def caper_generator_class
      HudApr::Generators::Caper::Fy2021::Generator
    end

    private def run_caper
      # puts 'Running CAPER'
      # Run CAPER Q5 to get Q5a B6 (adult leavers) for the denominator
      # Looking for CAPER Q16 D14 to identify leavers who had income at exit (we'll only take those with an increase as the numerator)
      questions = [
        'Question 5',
        'Question 16',
      ]
      caper_filter = ::Filters::HudFilterBase.new(user_id: filter.user_id).update(filter.to_h)
      caper_report = HudReports::ReportInstance.from_filter(caper_filter, caper_generator_class.title, build_for_questions: questions)
      caper_generator_class.new(caper_report).run!(email: false, manual: false)
      caper_report
    end

    private def answer(report, table, cell)
      report.answer(question: table, cell: cell).summary
    end

    private def answer_clients(report, table, cell)
      report.answer(question: table, cell: cell).universe_members.
        map(&:universe_membership).
        index_by(&destination_client_column(report))
    end

    private def destination_client_column(report)
      return :destination_client_id if report.report_name == caper_generator_class.title

      :client_id
    end

    private def run_spm
      # puts 'Running SPM'
      # Looking for SPM Measure 1A E3
      # Looking for SPM Measure 2 J7 (total returns to homelessness within 2 years)
      questions = [
        'Measure 1',
        'Measure 2',
      ]
      # NOTE: we need to include all homeless projects visible to this user, plus the chosen scope,
      # so that the returns calculation will work.
      options = filter.to_h
      options[:project_type_codes] ||= []
      options[:project_type_codes] += [:es, :so, :sh, :th]
      options.delete(:comparison_pattern)
      spm_filter = ::Filters::HudFilterBase.new(user_id: filter.user_id).update(options)
      generator = HudSpmReport::Generators::Fy2020::Generator
      spm_report = HudReports::ReportInstance.from_filter(spm_filter, generator.title, build_for_questions: questions)
      generator.new(spm_report).run!(email: false, manual: false)
      spm_report
    end

    private def run_rrh
      rrh_filter = WarehouseReport::Outcomes::OutcomesFilter.new(user_id: filter.user_id)
      options = filter.to_h
      options.delete(:comparison_pattern)
      rrh_filter.update(options)
      rrh_filter.project_type_numbers = [13]
      WarehouseReport::Outcomes::RrhReport.new(rrh_filter)
    end

    private def run_psh
      psh_filter = WarehouseReport::Outcomes::OutcomesFilter.new(user_id: filter.user_id)
      options = filter.to_h
      options.delete(:comparison_pattern)
      psh_filter.update(options)
      psh_filter.project_type_numbers = [3, 9, 10]
      WarehouseReport::Outcomes::PshReport.new(psh_filter)
    end

    private def run_outflow
      outflow_filter = ::Filters::OutflowReport.new(user_id: filter.user_id)
      options = filter.to_h
      options.delete(:comparison_pattern)
      outflow_filter.update(options)
      GrdaWarehouse::WarehouseReports::OutflowReport.new(outflow_filter, filter.user)
    end

    private def run_inflow
      inflow_filter = ::Filters::FilterBase.new(
        user_id: filter.user_id,
        enforce_one_year_range: false,
      )
      # FIXME: need to send symbolic project_types in addition to numeric
      # filter[:project_type_codes] =
      options = filter.to_h
      options.delete(:comparison_pattern)
      inflow_filter.update(options)
      Reporting::MonthlyReports::Base.class_for(inflow_filter.sub_population).new(
        user: inflow_filter.user,
        filter: inflow_filter,
      )
    end
  end
end
