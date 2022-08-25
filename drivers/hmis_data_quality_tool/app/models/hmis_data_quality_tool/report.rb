###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisDataQualityTool
  class Report < HudReports::ReportInstance
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
      begin
        populate_universe
        # calculate_results
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
        :coc_codes,
        :project_type_codes,
        :project_ids,
        :project_group_ids,
        :data_source_ids,
        :funder_ids,
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
      'hmis_data_quality_tool/warehouse_reports/reports'
    end

    def url
      hmis_data_quality_tool_warehouse_reports_report_url(host: ENV.fetch('FQDN'), id: id, protocol: 'https')
    end

    def title
      _('HMIS Data Quality Tool')
    end

    def description
      _('A tool to track data quality across HMIS data used in HUD reports.')
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
        :hmis_data_quality_tool,
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

    private def populate_universe
      report_clients = {}
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

    private def result_types
      [
        CePerformance::Results::CategoryOne,
      ]
    end

    private def calculate_results
    end

    def goal_for(goal_column)
    end

    private def answer_clients(report, table, cell)
      preloads = { universe_membership: :hud_report_apr_living_situations }

      report.answer(question: table, cell: cell).universe_members.preload(preloads).map(&:universe_membership)
    end

    def detail_headers
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
      end.freeze
    end

    def client_value(client, column)
      return client.public_send(column) unless column.include?('source_client')

      client.source_client.public_send(column.gsub('source_client.', ''))
    end
  end
end
