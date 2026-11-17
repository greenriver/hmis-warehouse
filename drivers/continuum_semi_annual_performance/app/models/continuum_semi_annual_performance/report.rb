###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module ContinuumSemiAnnualPerformance
  class Report < SimpleReports::ReportInstance
    include ::Filter::ControlSections
    include Reporting::Status
    include Rails.application.routes.url_helpers
    include ReportArchival

    belongs_to :user, optional: true
    has_many :approvals, class_name: 'ContinuumSemiAnnualPerformance::Approval', foreign_key: :report_instance_id, inverse_of: :report, dependent: nil

    has_many_attached :report_cells_csv

    scope :ordered, -> { order(updated_at: :desc) }

    after_initialize :filter

    PERFORMANCE_KEYS = { es: :es, hp: :prevention, so: :so, rrh: :rrh }.freeze

    def self.definition_viewable_by?(user)
      GrdaWarehouse::WarehouseReports::ReportDefinition.url_viewable_by?(url, user)
    end

    # run_and_save! deletes the previous attempt's cells and runs new APR instances.
    def self.supports_idempotent_retry? = true

    def self.url
      raise NotImplementedError
    end

    def self.controller_class
      raise NotImplementedError
    end

    def project_types
      raise NotImplementedError
    end

    def row_set
      raise NotImplementedError
    end

    def url
      public_send("#{route_resource_name}_url", host: ENV.fetch('FQDN'), id: id, protocol: 'https')
    end

    def show_path
      public_send("#{route_resource_name}_path", self)
    end

    def index_path
      public_send("#{route_resource_name.pluralize}_path")
    end

    def title
      raise NotImplementedError
    end

    def description
      raise NotImplementedError
    end

    def report_path_array
      [
        :continuum_semi_annual_performance,
        :warehouse_reports,
        self.class.url.split('/').last.to_sym,
      ]
    end

    def coc_code
      filter.coc_codes.first
    end

    def default_project_type_codes
      HudHelper.util.performance_reporting.keys
    end

    def describe_filter_as_html(keys = nil, inline: false)
      keys ||= [
        :coc_codes,
        :project_type_codes,
        :project_ids,
        :organization_ids,
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
        :project_ids,
        :project_type_codes,
        :organization_ids,
        :data_source_ids,
        :project_group_ids,
      ]
    end

    def filter=(filter_object)
      self.options = filter_object.to_h
      # force reset the filter cache
      reset_memos
      filter
    end

    def reload(*)
      reset_memos
      super
    end

    def filter
      @filter ||= begin
        f = ContinuumSemiAnnualPerformance::Filter.new(
          user_id: user_id,
          enforce_one_year_range: false,
        )
        f.update(options.with_indifferent_access.merge(enforce_one_year_range: false)) if options.present?
        f
      end
    end

    def selected_project_ids
      @selected_project_ids ||= filter.effective_project_ids - [0]
    end

    def project_ids_for(project_type)
      project_type = project_type.to_sym
      return selected_project_ids if project_type == :ce_tab

      numbers = HudHelper.util.performance_reporting.fetch(PERFORMANCE_KEYS.fetch(project_type))
      GrdaWarehouse::Hud::Project.where(id: selected_project_ids).with_project_type(numbers).pluck(:id)
    end

    # Project type numbers the form should limit its project list to, or nil when every type is used.
    def supported_project_type_ids
      return if project_types.include?(:ce_tab)

      project_types.flat_map { |project_type| HudHelper.util.performance_reporting.fetch(PERFORMANCE_KEYS.fetch(project_type)) }
    end

    def included_project_ids
      project_types.flat_map { |project_type| project_ids_for(project_type) }.uniq
    end

    def run_and_save!
      # A re-run is not complete until it finishes, and clears the previous attempt's failure
      update(started_at: Time.current, failed_at: nil, completed_at: nil)
      reset_summary_data
      report_cells.with_deleted.delete_all
      ContinuumSemiAnnualPerformance::SubReportRunner.new(self).run.each do |project_type, hud_report|
        ContinuumSemiAnnualPerformance::CellSnapshot.new(report: self, project_type: project_type, hud_report: hud_report).save!
      end
      complete
    ensure
      reset_summary_data
      update(failed_at: Time.current) unless completed?
    end

    # Logs only a change of state; returns nil when the report is already in the requested state.
    # The row lock keeps two overlapping saves from both logging the same change.
    def approve!(user:, approved:)
      with_lock do
        next if approved == approved?

        approvals.create!(user_id: user.id, approved: approved)
      end
    end

    def approved?
      approvals.newest_first.first&.approved || false
    end

    def archival_csv_config
      report_type = self.class.name.gsub('::', '-').underscore
      {
        report_cells_csv: {
          association: :report_cells,
          filename: -> { "#{report_type}-report_cells-#{id}.csv" },
        },
      }
    end

    def tabs
      present = summary_data.keys
      [:summary] + project_types.select { |project_type| present.include?(project_type) }
    end

    def rows_for(project_type)
      prefix = "#{project_type}.r"
      cells = report_cells.where('name LIKE ?', "#{self.class.sanitize_sql_like(prefix)}%").to_a
      cells.sort_by { |cell| cell.name.delete_prefix(prefix).to_i }.map do |cell|
        ContinuumSemiAnnualPerformance::DisplayRow.new(**cell.structured_data.symbolize_keys)
      end
    end

    def summary_rows
      project_types.filter_map do |project_type|
        data = summary_data[project_type]
        next unless data

        { project_type: project_type, projects: data['projects'], persons: data['persons'], households: data['households'] }
      end
    end

    def hud_report_ids
      summary_data.transform_values { |data| data['hud_report_id'] }
    end

    private def reset_memos
      @filter = nil
      @selected_project_ids = nil
      reset_summary_data
    end

    private def reset_summary_data
      @summary_data = nil
    end

    private def summary_data
      @summary_data ||= report_cells.where('name LIKE ?', '%.summary').to_a.each_with_object({}) do |cell, data|
        data[cell.name.delete_suffix('.summary').to_sym] = cell.structured_data
      end
    end

    private def route_resource_name
      "continuum_semi_annual_performance_warehouse_reports_#{self.class.url.split('/').last.singularize}"
    end

    private def build_control_sections
      []
    end
  end
end
