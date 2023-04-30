###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SystemPathways
  class Report < SimpleReports::ReportInstance
    include Filter::ControlSections
    include Filter::FilterScopes
    include Reporting::Status
    include Rails.application.routes.url_helpers
    include ActionView::Helpers::NumberHelper
    include ArelHelper
    include ApplicationHelper
    include HudReports::Households

    belongs_to :user, optional: true
    has_many :clients
    has_many :enrollments

    after_initialize :filter

    # NOTE: this differs from viewable_by which looks at the report definitions
    scope :visible_to, ->(user) do
      return all if user.can_view_all_reports?
      return where(user_id: user.id) if user.can_view_assigned_reports?

      none
    end

    scope :diet, -> do
      select(column_names - ['build_for_questions', 'remaining_questions'])
    end

    scope :ordered, -> do
      order(created_at: :desc)
    end

    def run_and_save!
      start
      create_universe
      complete
    end

    def start
      update(started_at: Time.current)
    end

    def complete
      update(completed_at: Time.current)
    end

    def self.untranslated_title
      'System Pathways'
    end

    def title
      _(self.class.untranslated_title)
    end

    def description
      _('A tool to look at client pathways through the continuum including some equity analysis.')
    end

    def describe_filter_as_html(keys = nil, inline: false, limited: true)
      keys ||= [
        :project_type_codes,
        :project_ids,
        :project_group_ids,
        :data_source_ids,
      ]
      filter.describe_filter_as_html(keys, inline: inline, limited: limited)
    end

    def known_params
      [
        :start,
        :end,
        :coc_codes,
        :project_type_codes,
        :project_ids,
        :project_group_ids,
        :data_source_ids,
        :funder_ids,
        :default_project_type_codes,
      ]
    end

    def known_detail_params
      known_params + [
        :ethnicities,
        :races,
        :veteran_statuses,
        :household_type,
        :hoh_only,
        :involves_ce,
        :chronic_status,
        :disabling_condition,
      ]
    end

    def known_sections
      [
        'equity',
        'time',
      ]
    end

    def allowed_section(section)
      known_sections.detect { |m| m == section } || known_sections.first
    end

    def chart_data_path(section)
      chart_data_system_pathways_warehouse_reports_report_path(self, allowed_section(section), format: :json)
    end

    private def build_control_sections
      # ensure filter has been set
      filter
      [
        build_funding_section,
        build_hoh_control_section,
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
          require_service_during_range: false,
        )
        f.update(options.with_indifferent_access.merge(enforce_one_year_range: false, require_service_during_range: false)) if options.present?
        f
      end
    end

    def self.url
      'hmis_data_quality_tool/warehouse_reports/reports'
    end

    def url
      system_pathways_warehouse_reports_report_url(host: ENV.fetch('FQDN'), id: id, protocol: 'https')
    end

    def show_path
      system_pathways_warehouse_reports_report_path(self)
    end

    def index_path
      system_pathways_warehouse_reports_reports_path
    end

    def report_path_array
      [
        :system_pathways,
        :warehouse_reports,
        :reports,
      ]
    end

    def multiple_project_types?
      true
    end

    def project_type_ids
      # any project type we know how to display plus CE
      allowed_states[nil] + [HudUtility.project_type_number('CE')]
    end

    def default_project_type_codes
      [
        :ph,
        :oph,
        :th,
        :es,
        :so,
        :sh,
        :ce,
        :rrh,
        :psh,
      ]
    end

    def self.available_project_types
      [1, 2, 3, 4, 8, 9, 10, 13, 14]
    end

    def detail_headers
      {
        'First Name' => ->(en) {
          en.client.first_name
        },
        'Last Name' => ->(en) {
          en.client.last_name
        },
        'Ethnicity' => ->(en) {
          HudUtility.ethnicity(en.client.ethnicity)
        },
        'Race' => ->(en) {
          races = []
          race_col_lookup.each_key do |k|
            races << race_col_lookup[k] if en.client[k]
          end
          races.map do |r|
            HudUtility.race(r)
          end.join(',')
        },
        'Disabling Condition' => ->(en) {
          HudUtility.no_yes_reasons_for_missing_data(en.disabling_condition)
        },
        'Veteran Status' => ->(en) {
          HudUtility.veteran_status(en.client.veteran_status)
        },
        'Stay Length' => ->(en) {
          en.stay_length
        },
        'Days Before Move-In' => ->(en) {
          en.days_to_move_in
        },
        'Days to Return' => ->(en) {
          en.client.days_to_return
        },
        'Household Chronic at Entry' => ->(en) {
          yn(en.chronic_at_entry)
        },
        'Participated in Coordinated Entry' => ->(en) {
          yn(en.client.involves_ce)
        },
      }
    end

    def race_columns
      race_col_lookup.keys
    end

    def race_col_lookup
      {
        'am_ind_ak_native' => 'AmIndAKNative',
        'asian' => 'Asian',
        'black_af_american' => 'BlackAfAmerican',
        'native_hi_pacific' => 'NativeHIPacific',
        'white' => 'White',
        'race_none' => 'RaceNone',
      }
    end

    def chart_model(slug = 'pathways')
      models = {
        'pathways' => SystemPathways::PathwaysChart,
        'equity' => SystemPathways::Equity,
        'time' => SystemPathways::TimeChart,
      }
      models[slug] || models['pathways']
    end

    def allowed_states
      {
        # Transition order is defined by array
        # ES (1), SH (8), TH (2), SO (4), PH - RRH (13), PH - PSH (3), PH - PH (9), PH - OPH (10)
        nil => [1, 8, 2, 4, 13, 3, 9, 10],
        1 => [2, 3, 9, 10, 13],
        2 => [3, 9, 10, 13],
        3 => [],
        4 => [1, 2, 3, 8, 9, 10, 13],
        8 => [2, 3, 9, 10, 13],
        9 => [],
        10 => [],
        13 => [3, 9, 10],
      }
    end

    private def accept_enrollments(subsequent_enrollments, current_project_type = nil, accepted_enrollments = [])
      return accepted_enrollments if subsequent_enrollments.blank?

      enrollment = subsequent_enrollments.first
      # If the next enrollment is in the allowed categories
      if allowed_states[current_project_type].include?(enrollment.computed_project_type)
        # Push it into the accepted batch
        accepted_enrollments << enrollment
        # and return if it is a "final" enrollment
        return accepted_enrollments if enrollment.exit_date.blank? || HudUtility.destination_type(enrollment.destination) == 'Permanent'

        # otherwise move on to the next
        accept_enrollments(subsequent_enrollments.drop(1), enrollment.computed_project_type, accepted_enrollments)
      else
        # if it's not in the acceptable types, just move on to the next one
        accept_enrollments(subsequent_enrollments.drop(1), current_project_type, accepted_enrollments)
      end
    end

    private def create_universe
      clients.delete_all
      enrollments.delete_all
      client_ids.each_slice(250) do |ids|
        enrollment_batch = enrollment_scope.where(client_id: ids)

        report_clients = {}
        report_enrollments = []
        enrollment_batch.group_by(&:client).each do |client, enrollments|
          served_by_ce = enrollments.any?(:ce?)
          involved_enrollments = enrollments.
            reject(&:ce?). # remove CE, we only use it for filtering
            # move the most-recently exited or open enrollments to the end
            sort_by { |en| en.exit_date || Date.tomorrow }.
            group_by(&:computed_project_type).
            # keep only the last enrollment in each category
            transform_values(&:last).
            values

          accepted_enrollments = accept_enrollments(involved_enrollments)
          final_enrollment = accepted_enrollments.last
          next unless final_enrollment.present?

          returned_enrollment = enrollments.detect do |en|
            # If we're still enrolled, we can't return
            next false if final_enrollment.exit_date.blank?
            # If our final enrollment didn't exit to a permanent destination we can't return
            next false unless HudUtility.destination_type(final_enrollment.destination) == 'Permanent'
            # If this enrollment starts before the end of the final enrollment, we can't have returned
            next false unless en.entry_date > final_enrollment.exit_date

            en.homeless?
          end

          # NOTE: we'll calculate age from the latter of the first enrollment entry date or report start
          date = [accepted_enrollments.first.entry_date, filter.start].max
          days_to_return = nil
          days_to_return = returned_enrollment.entry_date - final_enrollment.exit_date if returned_enrollment.present?
          report_client = report_clients[client] || Client.new(
            client_id: client.id,
            report_id: id,
            first_name: client.first_name,
            last_name: client.last_name,
            personal_ids: client.source_clients.map(&:personal_id).uniq.join('; '),
            dob: client.dob,
            age: client.age(date),
            am_ind_ak_native: client.am_ind_ak_native == 1,
            asian: client.asian == 1,
            black_af_american: client.black_af_american == 1,
            native_hi_pacific: client.native_hi_pacific == 1,
            white: client.white == 1,
            ethnicity: client.ethnicity,
            male: client.male == 1,
            female: client.female == 1,
            transgender: client.transgender == 1,
            questioning: client.questioning == 1,
            no_single_gender: client.no_single_gender == 1,
            veteran_status: client.veteran_status,
            involves_ce: served_by_ce,
            destination: final_enrollment.destination,
            destination_homeless: HudUtility.destination_type(final_enrollment.destination) == 'Homeless',
            destination_temporary: HudUtility.destination_type(final_enrollment.destination) == 'Temporary',
            destination_institutional: HudUtility.destination_type(final_enrollment.destination) == 'Institutional',
            destination_other: HudUtility.destination_type(final_enrollment.destination) == 'Other',
            destination_permanent: HudUtility.destination_type(final_enrollment.destination) == 'Permanent',
            returned_project_type: returned_enrollment&.computed_project_type,
            returned_project_name: returned_enrollment&.project&.name,
            returned_project_entry_date: returned_enrollment&.entry_date,
            returned_project_enrollment_id: returned_enrollment&.enrollment&.enrollment_id,
            returned_project_project_id: returned_enrollment&.project_id,
            days_to_return: days_to_return,
          )
          report_clients[client] = report_client

          accepted_enrollments.each.with_index do |en, i|
            from_project_type = nil
            from_project_type = accepted_enrollments[i - 1].computed_project_type if i.positive?
            stay_length = (en.entry_date .. [en.exit_date, filter.end].compact.min).count
            household_id = get_hh_id(en)
            household_type = household_makeup(household_id, date)
            chronic_member = household_chronic_status(household_id, client.id)
            days_to_move_in = 0
            days_to_exit_after_move_in = nil
            days_to_move_in = en.move_in_date - en.entry_date if en.move_in_date.present?
            days_to_exit_after_move_in = en.exit_date - en.move_in_date if en.move_in_date.present? && en.exit_date.present?
            report_enrollments << Enrollment.new(
              client_id: client.id,
              report_id: id,
              from_project_type: from_project_type,
              project_id: en.project_id,
              enrollment_id: en.enrollment&.enrollment_id,
              project_type: en.computed_project_type,
              destination: en.destination,
              project_name: en.project.name,
              entry_date: en.entry_date,
              exit_date: en.exit_date,
              move_in_date: en.move_in_date,
              days_to_move_in: days_to_move_in,
              days_to_exit_after_move_in: days_to_exit_after_move_in,
              stay_length: stay_length,
              disabling_condition: en.enrollment.disabling_condition,
              relationship_to_hoh: en.enrollment.relationship_to_hoh,
              chronic_at_entry: chronic_member[:chronic_status].present?,
              household_id: household_id,
              household_type: household_type,
              final_enrollment: i == accepted_enrollments.count - 1,
            )
          end
        end

        Client.import(report_clients.values)
        Enrollment.import(report_enrollments)
        universe.add_universe_members(report_clients)
      end
    end

    private def households
      return @households if @households.present?

      @households ||= {}
      @hoh_enrollments ||= {}

      client_ids.each_slice(100) do |batch|
        enrollments_by_client_id = clients_with_enrollments(batch)
        enrollments_by_client_id.each do |_, enrollments|
          enrollments.each do |enrollment|
            @hoh_enrollments[enrollment.client_id] = enrollment if enrollment.head_of_household?
            next unless enrollment&.enrollment&.client.present?

            date = [enrollment.first_date_in_program, filter.start].max
            age = GrdaWarehouse::Hud::Client.age(date: date, dob: enrollment.enrollment.client.DOB&.to_date)
            @households[get_hh_id(enrollment)] ||= []
            @households[get_hh_id(enrollment)] << {
              client_id: enrollment.client_id,
              source_client_id: enrollment.enrollment.client.id,
              dob: enrollment.enrollment.client.DOB,
              age: age,
              veteran_status: enrollment.enrollment.client.VeteranStatus,
              chronic_status: enrollment.enrollment.chronically_homeless_at_start?,
              chronic_detail: enrollment.enrollment.chronically_homeless_at_start,
              relationship_to_hoh: enrollment.enrollment.RelationshipToHoH,
              # Include dates for determining if someone was present at assessment date
              entry_date: enrollment.first_date_in_program,
              exit_date: enrollment.last_date_in_program,
            }.with_indifferent_access
          end
        end
        GC.start
      end
      return @households
    end

    private def household_makeup(household_id, date)
      household_ages = ages_for(household_id, date)
      return :adults_and_children if adults?(household_ages) && children?(household_ages)
      return :adults_only if adults?(household_ages) && ! children?(household_ages) && ! unknown_ages?(household_ages)
      return :children_only if children?(household_ages) && ! adults?(household_ages) && ! unknown_ages?(household_ages)

      :unknown
    end

    private def ages_for(household_id, date)
      return [] unless households[household_id]

      households[household_id].map { |client| GrdaWarehouse::Hud::Client.age(date: date, dob: client[:dob]) }
    end

    private def adults?(ages)
      ages.reject(&:blank?).any? do |age|
        age >= 18
      end
    end

    private def children?(ages)
      ages.reject(&:blank?).any? do |age|
        age < 18
      end
    end

    private def unknown_ages?(ages)
      ages.any? do |age|
        # NOTE: 0 is a valid child age
        age.blank? || age.negative?
      end
    end

    private def clients_with_enrollments(batch)
      enrollment_scope.
        where(client_id: batch).
        order(first_date_in_program: :asc).
        group_by(&:client_id)
    end

    private def nbn_with_no_service?(enrollment)
      enrollment.project_tracking_method == 3 &&
        ! enrollment.service_history_services.
          bed_night.
          service_within_date_range(start_date: filter.start, end_date: filter.end).
          exists?
    end

    private def client_ids
      @client_ids ||= enrollment_scope.distinct.pluck(:client_id)
    end

    def enrollment_scope
      # For compatability with filter_scopes
      filter.project_ids = filter.effective_project_ids
      scope = GrdaWarehouse::ServiceHistoryEnrollment.
        entry.
        in_project_type(self.class.available_project_types).
        preload(:project, enrollment: [:client, :project, :disabilities_at_entry], client: :source_clients).
        joins(:project).
        open_between(start_date: filter.start_date, end_date: filter.end_date)
      filter.apply(scope, except: [:filter_for_enrollment_cocs])
    end
  end
end
