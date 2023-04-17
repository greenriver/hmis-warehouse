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

    def sanitized_node(node)
      available = available_project_types.map do |p_type|
        HudUtility.project_type_brief(p_type)
      end + destination_lookup.keys

      available.detect { |m| m == node }
    end

    def available_project_types
      [1, 2, 3, 4, 8, 9, 10, 13, 14]
    end

    private def destination_lookup
      {
        'Permanent Destinations' => 'destination_permanent',
        'Homeless Destinations' => 'destination_homeless',
        'Institutional Destinations' => 'destination_institutional',
        'Temporary Destinations' => 'destination_temporary',
        'Other Destinations' => 'destination_other',
      }
    end

    private def allowed_states
      {
        nil => [1, 2, 3, 4, 8, 9, 10, 13],
        1 => [2, 3, 9, 10, 13], # FIXME: 1 -> 4 should not be possible, which makes me think accept_enrollments isn't working correctly
        2 => [3, 9, 10, 13],
        3 => [],
        4 => [1, 2, 3, 9, 10, 13],
        8 => [2, 3, 9, 10, 13],
        9 => [],
        10 => [],
        13 => [3, 9, 10],
      }
    end

    private def accept_enrollments(subsequent_enrollments, current_project_type = nil, accepted_enrollments = [])
      return accepted_enrollments if subsequent_enrollments.blank?

      enrollment = subsequent_enrollments.first
      if enrollment.exit_date.blank? || HudUtility.destination_type(enrollment.destination) == 'Permanent'
        accepted_enrollments << enrollment
        return accepted_enrollments
      end

      if allowed_states[current_project_type].include?(enrollment.computed_project_type)
        accepted_enrollments << enrollment
        accept_enrollments(subsequent_enrollments.drop(1), enrollment.computed_project_type, accepted_enrollments)
      else
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
            next false if final_enrollment.exit_date.blank? || ! HudUtility.destination_type(final_enrollment.destination) == 'Permanent'

            en.homeless?
          end

          report_client = report_clients[client] || Client.new(
            client_id: client.id,
            report_id: id,
            first_name: client.first_name,
            last_name: client.last_name,
            personal_ids: client.source_clients.map(&:personal_id).uniq.join('; '),
            dob: client.dob,
            age: client.age(@start_date),
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
            ce: served_by_ce,
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
          )
          report_clients[client] = report_client

          accepted_enrollments.each.with_index do |en, i|
            from_project_type = nil
            from_project_type = accepted_enrollments[i - 1].computed_project_type if i.positive?
            stay_length = (en.entry_date .. [en.exit_date, filter.end].compact.min).count
            household_id = en.household_id || "#{en.enrollment_group_id}*hh"

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
              stay_length: stay_length,
              disabling_condition: en.enrollment.disabling_condition,
              relationship_to_hoh: en.enrollment.relationship_to_hoh,
              household_id: household_id,
              # FIXME: need to use HUD household calculation
              # household_type: household_type,
            )
          end
        end

        Client.import(report_clients.values)
        Enrollment.import(report_enrollments)
        universe.add_universe_members(report_clients)
      end
    end

    private def client_ids
      @client_ids ||= enrollment_scope.where(client_id: 29348).distinct.pluck(:client_id)
    end

    def enrollment_scope
      # For compatability with filter_scopes
      filter.project_ids = filter.effective_project_ids
      scope = GrdaWarehouse::ServiceHistoryEnrollment.
        entry.
        in_project_type(available_project_types).
        preload(:enrollment, :project, client: :source_clients).
        joins(:project).
        open_between(start_date: filter.start_date, end_date: filter.end_date)
      filter.apply(scope, except: [:filter_for_enrollment_cocs])
    end
  end
end
