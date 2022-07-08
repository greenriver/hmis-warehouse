###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CePerformance
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
    has_many :results
    has_many :ce_aprs
    has_many :hud_ce_apr, through: :ce_aprs

    after_initialize :filter

    HOUSING_REFERRAL_EVENTS = [12, 13, 14, 15, 17, 18].freeze

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
      begin
        populate_universe
        calculate_results
      rescue Exception => e
        update(failed_at: Time.current)
        raise e
      end
      complete
    end

    def start
      update(started_at: Time.current)
    end

    def complete
      update(completed_at: Time.current)
    end

    def describe_filter_as_html(keys = nil, inline: false)
      keys ||= [
        :project_type_codes,
        :project_ids,
        :project_group_ids,
        :data_source_ids,
      ]
      filter.describe_filter_as_html(keys, inline: inline)
    end

    def known_params
      [
        :start,
        :end,
        :comparison_period,
        :coc_code,
        :project_type_codes,
        :project_ids,
        :project_group_ids,
        :data_source_ids,
        :funder_ids,
        :hoh_only,
      ]
    end

    def filter=(filter_object)
      self.options = filter_object.to_h
      # force reset the filter cache
      @filter = nil
      filter
    end

    def filter
      @filter ||= begin
        f = ::Filters::HudFilterBase.new(
          user_id: user_id,
          enforce_one_year_range: false,
        )
        f.update(options.with_indifferent_access.merge(enforce_one_year_range: false)) if options.present?
        f
      end
    end

    def self.viewable_by(user)
      GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: url).
        viewable_by(user).exists?
    end

    def self.url
      'ce_performance/warehouse_reports/reports'
    end

    def url
      ce_performance_warehouse_reports_report_url(host: ENV.fetch('FQDN'), id: id, protocol: 'https')
    end

    def title
      _('Coordinated Entry Performance')
    end

    def description
      _('A tool to track performance and utilization of Coordinated Entry resources.')
    end

    def multiple_project_types?
      true
    end

    def project_type_ids
      filter.project_type_ids
    end

    def default_project_type_codes
      GrdaWarehouse::Hud::Project::PERFORMANCE_REPORTING.keys
    end

    private def build_control_sections
      # ensure filter has been set
      filter
      [
        build_funding_section,
        build_hoh_control_section,
      ]
    end

    def report_path_array
      [
        :ce_performance,
        :warehouse_reports,
        :reports,
      ]
    end

    def report_scope_source
      GrdaWarehouse::ServiceHistoryEnrollment.entry
    end

    def can_see_client_details?(user)
      user.can_access_some_version_of_clients?
    end

    def results_for_display
      @results_for_display ||= {}.tap do |rfd|
        periods.keys.each do |period|
          results.each do |r|
            rfd[r.category] ||= {}
            rfd[r.category][period] ||= {}
            rfd[r.category][period][r.class] ||= r
          end
        end
      end
    end

    def highlight_id(category_name)
      results_for_display.keys.index(category_name) + 1
    end

    private def populate_universe
      run_ce_aprs.each do |period, ce_apr|
        report_clients = {}
        report_clients = add_q5a_clients(report_clients, period, ce_apr)
        report_clients = add_q9b_clients(report_clients, period, ce_apr)
        report_clients = add_q9d_clients(report_clients, period, ce_apr)
        # TODO:
        # Number of persons/households - CAT2: at imminent risk: prevention tool score completed; prior living situation set per HUD
        # Number of persons screened for Prevention - Number of Head of Household with a recorded Prevention Tool Score (currently from auxiliary data)
        # Sub-populations -
        #   Veterans,
        #   Adult and child households,
        #   Adult only households,
        #   Chronically Homeless at Entry,
        #   Youth (18-24),
        #   Domestic Violence (Enrollment.CurrentlyFleeing or Enrollment.DomesticViolenceVictim),
        #   LGBT (can't really do with current data, maybe Gender.Questioning, or Gender.Transgender or Gender.NoSingleGender, is availale in the auxiliary data) ,
        #   HIV - Enrollment.disabilities.DisabilityType = 8
        # Number and Types of CE Events - Group and count by ID (Q9d B15) - partially implemented
        # CE Assessment Score ranges/types - only available in auxiliary data currently (score is integer, type is Family/Single/Youth)
        # Assessment Point Connections (referral data to ensure clients are getting connected) - TBD

        # add prevention_tool_score
        # add assessment_score
        # add assessment_type
        # add initial_assessment_date
        # add latest_assessment_date

        Client.import!(
          report_clients.values,
          batch_size: 5_000,
          on_duplicate_key_update: {
            conflict_target: [:id],
            columns: Client.attribute_names.map(&:to_sym),
          },
        )
        universe.add_universe_members(report_clients)
      end
    end

    private def add_q5a_clients(report_clients, period, ce_apr)
      ce_apr_clients = answer_clients(ce_apr, 'Q5a', 'B1')
      ce_apr_clients.each do |ce_apr_client|
        report_client = report_clients[ce_apr_client[:client_id]] || Client.new(
          report_id: id,
          client_id: ce_apr_client[:client_id],
          ce_apr_id: ce_apr.id,
          ce_apr_client_id: ce_apr_client.id,
        )
        report_client.q5a_b1 = true
        report_client.first_name = ce_apr_client.first_name
        report_client.last_name = ce_apr_client.last_name
        report_client.dob = ce_apr_client.dob
        report_client.reporting_age = ce_apr_client.age
        report_client.veteran = ce_apr_client.veteran_status == 1
        report_client.entry_date = ce_apr_client.first_date_in_program
        report_client.move_in_date = ce_apr_client.move_in_date
        report_client.exit_date = ce_apr_client.last_date_in_program
        report_client.head_of_household = ce_apr_client.head_of_household
        report_client.prior_living_situation = ce_apr_client.prior_living_situation
        report_client.los_under_threshold = ce_apr_client.los_under_threshold
        report_client.previous_street_essh = ce_apr_client.date_to_street
        report_client.household_size = ce_apr_client.household_members.count
        report_client.household_ages = household_ages(ce_apr_client).uniq
        report_client.household_type = ce_apr_client.household_type
        report_client.chronically_homeless_at_entry = ce_apr_client.chronically_homeless
        report_client.period = period
        report_clients[ce_apr_client.client_id] = report_client
      end
      report_clients
    end

    private def add_q9b_clients(report_clients, period, ce_apr)
      ce_apr_clients = answer_clients(ce_apr, 'Q9b', 'B2')
      ce_apr_clients.each do |ce_apr_client|
        report_client = report_clients[ce_apr_client[:client_id]] || Client.new(
          report_id: id,
          client_id: ce_apr_client[:client_id],
          ce_apr_id: ce_apr.id,
          ce_apr_client_id: ce_apr_client.id,
        )
        report_client.assessments = ce_apr_client.hud_report_ce_assessments.map do |e|
          {
            date: e.assessment_date,
            level: e.assessment_level,
          }
        end
        min_assessment_date = ce_apr_client.hud_report_ce_assessments.map(&:assessment_date).min
        end_date = [ce_apr_client.last_date_in_program, ce_apr.end_date].compact.min
        report_client.days_before_assessment = min_assessment_date - ce_apr_client.first_date_in_program
        report_client.days_on_list = end_date - min_assessment_date if min_assessment_date.present?
        report_client.days_in_project = end_date - ce_apr_client.first_date_in_program
        report_client.period = period
        report_clients[ce_apr_client.client_id] = report_client
      end
      report_clients
    end

    private def add_q9d_clients(report_clients, period, ce_apr)
      # All clients placed on prioritization list
      ce_apr_clients = answer_clients(ce_apr, 'Q9d', 'B17')
      ce_apr_clients.each do |ce_apr_client|
        report_client = report_clients[ce_apr_client.client_id] || Client.new(
          report_id: id,
          client_id: ce_apr_client.client_id,
          ce_apr_id: ce_apr.id,
          ce_apr_client_id: ce_apr_client.id,
        )
        report_client.events = ce_apr_client.hud_report_ce_events.map do |e|
          {
            date: e.event_date,
            event: e.event,
            result: e.referral_result,
          }
        end
        report_client.diversion_event = report_client.events.any? { |e| e[:event].to_i == 2 }
        report_client.diversion_successful = report_client.events.any? do |e|
          e[:event].to_i == 2 && e[:result].to_i == 1
        end
        initial_referral_date = report_client.events.select do |e|
          e[:event].in?(HOUSING_REFERRAL_EVENTS)
        end&.map { |e| e[:date] }&.min
        report_client.initial_housing_referral_date = initial_referral_date
        # NOTE: this potentially expands outside of the permissions of the user
        if initial_referral_date.present?
          dates = ce_apr_client.source_enrollment.
            client.destination_client.
            source_enrollments.
            with_project_type(GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:ph]).
            pluck(:EntryDate, :MoveInDate)
          housing_entry_date = dates&.
            select { |d, _| d >= initial_referral_date }&.
            min
          if housing_entry_date.present?
            housing_move_in_date = dates&.
              select { |_, d| d >= housing_entry_date }&.
              min
            report_client.housing_enrollment_entry_date = housing_entry_date
            report_client.housing_enrollment_move_in_date = housing_move_in_date
            report_client.days_between_referral_and_housing = housing_entry_date - initial_referral_date
          end
        end

        report_client[:period] = period
        report_clients[ce_apr_client[:client_id]] = report_client
      end
      report_clients
    end

    private def household_ages(apr_client)
      date = [apr_client.first_date_in_program, filter.start].compact.max
      ages = [apr_client.age]
      apr_client.household_members.each do |member|
        next unless member['dob'].present?

        ages << GrdaWarehouse::Hud::Client.age(date: date, dob: member['dob'].to_date)
      end
      ages
    end

    private def result_types
      [
        CePerformance::Results::CategoryOne,
        CePerformance::Results::CategoryOneHousehold,
        CePerformance::Results::SuccessfulDiversion,
        CePerformance::Results::TimeInProjectAverage,
        CePerformance::Results::TimeInProjectMedian,
        CePerformance::Results::ReferralToHousingAverage,
        CePerformance::Results::ReferralToHousingMedian,
        CePerformance::Results::TimeOnListAverage,
        CePerformance::Results::TimeOnListMedian,
        CePerformance::Results::TimeToAssessmentAverage,
        CePerformance::Results::TimeToAssessmentMedian,
        CePerformance::Results::EventType,
      ]
    end

    private def calculate_results
      periods.each do |period, report_filter|
        result_types.each do |result_class|
          result_class.calculate(self, period, report_filter)
        end
      end
    end

    private def answer_clients(report, table, cell)
      report.answer(question: table, cell: cell).universe_members.preload(:universe_membership).map(&:universe_membership)
    end

    private def run_ce_aprs
      # puts 'Running CE APR'
      questions = [
        'Question 5',
        'Question 9',
      ]
      generator = HudApr::Generators::CeApr::Fy2021::Generator
      {}.tap do |reports|
        periods.each do |period, processed_filter|
          report = HudReports::ReportInstance.from_filter(
            processed_filter,
            generator.title,
            build_for_questions: questions,
          )
          generator.new(report).run!(email: false, manual: false)
          ce_aprs.create(
            report_id: id,
            ce_apr_id: report.id,
            start_date: processed_filter.start,
            end_date: processed_filter.end,
          )
          reports[period] = report
        end
      end
    end

    private def periods
      @periods ||= {}.tap do |periods|
        reporting_filter = ::Filters::HudFilterBase.new(user_id: user_id)
        reporting_filter.update(filter.to_h)
        reporting_filter.coc_codes = [filter.coc_code]
        comparison_filter = reporting_filter.to_comparison
        periods[:reporting] = reporting_filter
        periods[:comparison] = comparison_filter
      end
    end
  end
end
