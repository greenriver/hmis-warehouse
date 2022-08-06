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
        :coc_codes,
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
            rfd[r.category][period][r.class] ||= r if r.period == period.to_s && r.overview
          end
        end
      end
    end

    def highlight_id(category_name)
      results_for_display.keys.index(category_name) + 1
    end

    def vispdat_ranges
      @vispdat_ranges ||= clients.distinct.where.not(vispdat_range: nil).pluck(:vispdat_range)
    end

    def clients_title(sub_population_title: nil, vispdat_range: nil, event_type: nil)
      return "VI-SPDAT Range: #{vispdat_range}" if vispdat_range.present?
      return "Event Type: #{::HUD.event(event_type)}" if event_type.present?

      return sub_population_title
    end

    private def populate_universe
      run_ce_aprs.each do |period, ce_apr|
        report_clients = {}
        report_clients = add_q5a_clients(report_clients, period, ce_apr)
        report_clients = add_q9b_clients(report_clients, period, ce_apr)
        report_clients = add_q9d_clients(report_clients, period, ce_apr)
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
        # was the client ever literally homeless during the report range
        report_client.cls_literally_homeless = any_cls_literally_homeless?(ce_apr_client)
        report_client.los_under_threshold = ce_apr_client.los_under_threshold
        report_client.previous_street_essh = ce_apr_client.date_to_street
        report_client.household_size = ce_apr_client.household_members.count
        report_client.household_ages = household_ages(ce_apr_client).uniq
        report_client.household_type = ce_apr_client.household_type
        report_client.chronically_homeless_at_entry = ce_apr_client.chronically_homeless
        if include_supplemental?
          most_recent_supplement = pick_supplement(ce_apr_client.source_enrollment.tpc_supplemental_enrollment_datum, period)
          if most_recent_supplement.present?
            report_client.vispdat_type = most_recent_supplement.vispdat_type
            report_client.vispdat_range = most_recent_supplement.vispdat_range
            report_client.assessment_score = most_recent_supplement.vispdat_grand_total
            report_client.prevention_tool_score = most_recent_supplement.prevention_tool_score
            report_client.prioritization_tool_type = most_recent_supplement.prioritization_tool_type
            report_client.prioritization_tool_score = most_recent_supplement.prioritization_tool_score
            report_client.community = most_recent_supplement.community
            report_client.lgbtq_household_members = most_recent_supplement.lgbtq_household_members || false
            report_client.client_lgbtq = most_recent_supplement.client_lgbtq || false
            report_client.dv_survivor = most_recent_supplement.dv_survivor || false
          end
        end
        report_client.period = period
        report_clients[ce_apr_client.client_id] = report_client
      end
      report_clients
    end

    def include_supplemental?
      RailsDrivers.loaded.include?(:supplemental_enrollment_data) && SupplementalEnrollmentData::Tpc.exists?
    end

    # find the newest that is before the report end date
    private def pick_supplement(supplements, period)
      active_filter = periods[period]
      supplements.select do |m|
        [m.entry_date, m.vispdat_ended_at].compact.all? { |d| d <= active_filter.end }
      end.max_by do |m|
        [m.entry_date, m.vispdat_ended_at].compact.max
      end
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
      active_filter = periods[period]
      # All clients placed on prioritization list
      ce_apr_clients = answer_clients(ce_apr, 'Q9d', 'B16')
      # NOTE: this potentially expands outside of the permissions of the user
      # Find all PH enrollments for the destination client associated with the ce_apr_clients
      # that are also visible by the user, and started within the report range
      ph_enrollments = GrdaWarehouse::Hud::Client.
        where(id: ce_apr_clients.map(&:destination_client_id)).
        joins(source_enrollments: :project).
        merge(GrdaWarehouse::Hud::Project.ph.viewable_by(user)).
        merge(GrdaWarehouse::Hud::Enrollment.opened_during_range(active_filter.range)).
        pluck(:id, e_t[:EntryDate], e_t[:MoveInDate]).
        group_by(&:shift)
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
        report_client.diversion_event = report_client.events.any? { |e| e.with_indifferent_access[:event].to_i == 2 }
        report_client.diversion_successful = report_client.events.any? do |e|
          e.with_indifferent_access[:event].to_i == 2 && e.with_indifferent_access[:result].to_i == 1
        end
        initial_referral_date = report_client.events.select do |e|
          e.with_indifferent_access[:event].in?(HOUSING_REFERRAL_EVENTS)
        end&.map { |e| e.with_indifferent_access[:date] }&.min&.to_date
        report_client.initial_housing_referral_date = initial_referral_date
        if initial_referral_date.present?
          report_client.days_between_entry_and_initial_referral = initial_referral_date - report_client.entry_date
          dates = ph_enrollments[ce_apr_client.destination_client_id]
          housing_entry_date = dates&.
            map(&:first)&.
            select { |d| d.present? && d >= initial_referral_date }&.
            min
          if housing_entry_date.present?
            housing_move_in_date = dates&.
              map(&:last)&.
              select { |d| d.present? && d >= housing_entry_date }&.
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

    private def any_cls_literally_homeless?(ce_apr_client)
      ce_apr_client.hud_report_apr_living_situations.any? do |m|
        m.living_situation.in?(::HUD.homeless_situations(as: :current))
      end
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
      types = [
        CePerformance::Results::CategoryOne,
        CePerformance::Results::CategoryOneHousehold,
        CePerformance::Results::CategoryTwo,
        CePerformance::Results::CategoryTwoHousehold,
      ]
      if include_supplemental?
        types += [
          CePerformance::Results::ClientsScreened,
        ]
      end
      types += [
        CePerformance::Results::SuccessfulDiversion,
        CePerformance::Results::TimeInProjectAverage,
        CePerformance::Results::TimeInProjectMedian,
        CePerformance::Results::EntryToReferralAverage,
        CePerformance::Results::EntryToReferralMedian,
        CePerformance::Results::ReferralToHousingAverage,
        CePerformance::Results::ReferralToHousingMedian,
        CePerformance::Results::TimeOnListAverage,
        CePerformance::Results::TimeOnListMedian,
        CePerformance::Results::TimeToAssessmentAverage,
        CePerformance::Results::TimeToAssessmentMedian,
        CePerformance::Results::EventType,
        CePerformance::Results::Vispdat,
        CePerformance::Results::VispdatAdult,
        CePerformance::Results::VispdatAdultAndChild,
        CePerformance::Results::VispdatYouth,
      ]
      types
    end

    private def calculate_results
      periods.each_key do |period|
        result_types.each do |result_class|
          result_class.calculate(self, period)
        end
      end
    end

    private def answer_clients(report, table, cell)
      preloads = if RailsDrivers.loaded.include?(:supplemental_enrollment_data)
        {
          universe_membership: [
            :hud_report_apr_living_situations,
            source_enrollment: :tpc_supplemental_enrollment_datum,
          ],
        }
      else
        { universe_membership: :hud_report_apr_living_situations }
      end
      report.answer(question: table, cell: cell).universe_members.preload(preloads).map(&:universe_membership)
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

    def detail_headers(key: nil) # rubocop:disable Lint/UnusedMethodArgument
      @detail_headers ||= {}.tap do |headers|
        headers.merge!(
          {
            'client_id' => 'Warehouse Client ID',
            'dob' => 'DOB',
            'veteran' => 'Veteran Status',
            'first_name' => 'First Name',
            'last_name' => 'Last Name',
            'reporting_age' => 'Reporting Age',
            'head_of_household' => 'Head of Household',
            'household_size' => 'Household Size',
            'household_type' => 'Household Type',
            'prior_living_situation' => 'Prior Living Situation',
            'los_under_threshold' => 'Length of time Under Threshold',
            'previous_street_essh' => 'Previous Street ES/SH',
            'entry_date' => 'Entry Date',
            'exit_date' => 'Exit Date',
            'events' => 'Events',
            'diversion_event' => 'Diversion Event',
            'diversion_successful' => 'Diversion Successful',
            'days_between_entry_and_initial_referral' => 'Days Between Entry and Initial Referral',
            'days_between_referral_and_housing' => 'Days Between Referral and Housing',
            'days_in_project' => 'Days in Project',
            'days_on_list' => 'Days on the Prioritization List',
            'source_client.race_description' => 'Race',
          },
        )
        if include_supplemental?
          headers ['vispdat_type'] = 'VI-SPDAT Type'
          headers ['vispdat_range'] = 'VI-SPDAT Range'
          headers ['assessment_score'] = 'VI-SPDAT Score'
          headers ['prioritization_tool_type'] = 'Prioritization Tool Type'
          headers ['prioritization_tool_score'] = 'Prioritization Tool Score'
          headers ['community'] = 'Community'
          headers ['client_lgbtq'] = 'Client Identifies as LGBTQ'
          headers ['lgbtq_household_members'] = 'Household Identifies as LGBTQ'
          headers['dv_survivor'] = 'Survivor of Domestic Violence'
        end
      end.freeze
    end

    def client_value(client, column)
      return client.public_send(column) unless column.include?('source_client')

      client.source_client.public_send(column.gsub('source_client.', ''))
    end

    def available_periods
      periods.keys
    end

    private def periods
      @periods ||= {}.tap do |periods|
        reporting_filter = ::Filters::HudFilterBase.new(user_id: user_id)
        reporting_filter.update(filter.to_h)
        comparison_filter = reporting_filter.to_comparison
        periods[:reporting] = reporting_filter
        periods[:comparison] = comparison_filter
      end
    end
  end
end
