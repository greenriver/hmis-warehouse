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
    has_many :enrollments
    has_many :assessments
    has_many :events
    has_many :services
    has_many :current_living_situations
    has_many :projects
    has_many :inventories

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
        update(state: 'Failed', failed_at: Time.current)
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
        :default_project_type_codes,
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
        f = ::Filters::FilterBase.new(
          user_id: user_id,
          enforce_one_year_range: false,
          require_service_during_range: false,
        )
        f.update(options.with_indifferent_access.merge(enforce_one_year_range: false, require_service_during_range: false)) if options.present?
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

    def show_path
      hmis_data_quality_tool_warehouse_reports_report_path(self)
    end

    def index_path
      hmis_data_quality_tool_warehouse_reports_reports_path
    end

    def self.untranslated_title
      'HMIS Data Quality Tool'
    end

    def title
      _(self.class.untranslated_title)
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

    # @return filtered scope
    def report_scope
      filter.apply(report_scope_source)
    end

    def can_see_client_details?(user)
      user.can_access_some_version_of_clients?
    end

    private def populate_universe
      report_clients = clients.map { |c| [c.client_id, c] }.to_h
      Client.calculate_issues(report_clients, self)
      report_enrollments = enrollments.map { |e| [e.enrollment_id, e] }.to_h
      Enrollment.calculate_enrollment_issues(report_enrollments, self)
    end

    def household(household_id)
      return unless household_id.present?

      @household ||= {}.tap do |households|
        GrdaWarehouse::Hud::Enrollment.joins(:service_history_enrollment).
          preload(:exit, client: :warehouse_client_source).
          merge(report_scope).distinct.
          where.not(HouseholdID: nil).
          find_each do |enrollment|
            report_age_date = [enrollment.EntryDate, filter.start].max
            households[enrollment.HouseholdID] ||= []
            households[enrollment.HouseholdID] << {
              age: enrollment.client.age_on(report_age_date),
              relationship_to_hoh: enrollment.RelationshipToHoH,
            }
          end
      end
      @household[household_id]
    end

    def known_keys
      results.map(&:title)
    end

    def result_from_key(key)
      results.detect { |r| r.title == key }
    end

    def items_for(key)
      universe(key).universe_members.map(&:universe_membership)
    end

    def results
      @results || validations + dq_checks
    end

    def validations
      @validations ||= [].tap do |r|
        slug = Client.gender_issues_slug
        count = universe(slug).count
        r << OpenStruct.new(
          title: slug,
          category: 'Client',
          count: count,
          total: overall_client_count,
          percent: percent(overall_client_count, count),
          item_class: HmisDataQualityTool::Client,
        )
        slug = Client.race_issues_slug
        count = universe(slug).count
        r << OpenStruct.new(
          title: slug,
          category: 'Client',
          count: count,
          total: overall_client_count,
          percent: percent(overall_client_count, count),
          item_class: HmisDataQualityTool::Client,
        )
        slug = Enrollment.disabling_condition_issues_slug
        count = universe(slug).count
        r << OpenStruct.new(
          title: slug,
          category: 'Enrollment',
          count: count,
          total: overall_enrollment_count,
          percent: percent(overall_enrollment_count, count),
          item_class: HmisDataQualityTool::Enrollment,
        )
        slug = Enrollment.hoh_validation_issues_slug
        count = universe(slug).count
        r << OpenStruct.new(
          title: slug,
          category: 'Enrollment',
          count: count,
          total: overall_enrollment_count,
          percent: percent(overall_enrollment_count, count),
          item_class: HmisDataQualityTool::Enrollment,
        )
        slug = Enrollment.living_situation_issues_slug
        count = universe(slug).count
        r << OpenStruct.new(
          title: slug,
          category: 'Enrollment',
          count: count,
          total: overall_enrollment_count,
          percent: percent(overall_enrollment_count, count),
          item_class: HmisDataQualityTool::Enrollment,
        )
        slug = Enrollment.exit_date_issues_slug
        count = universe(slug).count
        r << OpenStruct.new(
          title: slug,
          category: 'Enrollment',
          count: count,
          total: overall_enrollment_count,
          percent: percent(overall_enrollment_count, count),
          item_class: HmisDataQualityTool::Enrollment,
        )
        slug = Enrollment.destination_issues_slug
        count = universe(slug).count
        r << OpenStruct.new(
          title: slug,
          category: 'Enrollment',
          count: count,
          total: overall_enrollment_count,
          percent: percent(overall_enrollment_count, count),
          item_class: HmisDataQualityTool::Enrollment,
        )
      end
    end

    def dq_checks
      @dq_checks ||= [].tap do |r|
      end
    end

    def overall_client_count
      @overall_client_count ||= GrdaWarehouse::Hud::Client.joins(enrollments: :service_history_enrollment).
        preload(:warehouse_client_source).
        merge(report_scope).
        distinct.
        select(:id).
        count
    end

    def overall_enrollment_count
      @overall_enrollment_count ||= report_scope.count
    end

    private def percent(total, partial)
      return 0 if total.blank? || total.zero? || partial.blank? || partial.zero?

      ((partial / total.to_f) * 100).round
    end
  end
end
