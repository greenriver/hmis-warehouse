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

    def describe_filter_as_html
      filter.describe_filter_as_html(
        [
          :start,
          :end,
          :coc_codes,
          :project_type_codes,
          :project_ids,
          :project_group_ids,
          :data_source_ids,
          :funder_ids,
          :hoh_only,
        ],
      )
    end

    def filter=(filter_object)
      self.options = filter_object.to_h
      # force reset the filter cache
      @filter = nil
      filter
    end

    def filter
      @filter ||= begin
        f = ::Filters::HudFilterBase.new(user_id: user_id, enforce_one_year_range: false)
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

    private def populate_universe
      report_clients = {}
      add_clients(report_clients)
    end

    private def add_clients(report_clients)
      ce_apr = run_ce_apr
      ce_apr_clients = answer_clients(ce_apr, 'Q5a', 'B1')
      ce_apr_clients.each do |ce_apr_client|
        report_client = report_clients[ce_apr_client[:client_id]] || Client.new(report_id: id, client_id: ce_apr_client[:client_id], ce_apr_id: ce_apr.id)
        report_client[:dob] = ce_apr_client[:dob]
        report_client[:reporting_age] = ce_apr_client[:age]
        report_client[:veteran] = ce_apr_client[:veteran_status] == 1
        report_client[:entry_date] = ce_apr_client[:first_date_in_program]
        report_client[:exit_date] = ce_apr_client[:last_date_in_program]
        report_client[:move_in_date] = ce_apr_client[:move_in_date]
        report_client[:exit_date] = ce_apr_client[:last_date_in_program]
        report_client[:exit_date] = ce_apr_client[:last_date_in_program]
        report_client[:head_of_household] = ce_apr_client[:head_of_household]
        report_client[:prior_living_situation] = ce_apr_client[:prior_living_situation]
        report_client[:los_under_threshold] = ce_apr_client[:los_under_threshold]
        report_client[:previous_street_essh] = ce_apr_client[:date_to_street]
        report_client[:household_size] = ce_apr_client[:household_members].count
        report_client[:chronically_homeless_at_entry] = ce_apr_client[:chronically_homeless]
      end
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

    private def answer_clients(report, table, cell)
      report.answer(question: table, cell: cell).universe_members.preload(:universe_membership).map(&:universe_membership)
    end

    private def run_ce_apr
      # puts 'Running CE APR'
      questions = [
        'Question 5',
        'Question 9',
      ]

      generator = HudApr::Generators::CeApr::Fy2021::Generator
      processed_filter = ::Filters::HudFilterBase.new(user_id: user_id)
      processed_filter.update(filter.to_h)
      processed_filter.coc_codes = [filter.coc_code]
      report = HudReports::ReportInstance.from_filter(
        processed_filter,
        generator.title,
        build_for_questions: questions,
      )
      generator.new(report).run!(email: false, manual: false)
      report
    end
  end
end
