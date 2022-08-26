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
      report_clients = gender_issues(report_clients)
      race_issues(report_clients)
    end

    private def gender_issues(report_clients)
      intermediate_report_clients = {}
      GrdaWarehouse::Hud::Client.joins(enrollments: :service_history_enrollment).
        preload(:warehouse_client_source).
        merge(report_scope).distinct.
        where(gender_issues_query).
        find_each do |client|
          report_client = report_clients[client] || Client.new(
            report_id: id,
            client_id: client.id,
            destination_client_id: client.warehouse_client_source.destination_id,
          )
          report_client.first_name = client.FirstName
          report_client.last_name = client.LastName
          report_client.personal_id = client.PersonalID
          report_client.data_source_id = client.data_source_id
          report_client.male = client.Male
          report_client.female = client.Female
          report_client.no_single_gender = client.NoSingleGender
          report_client.transgender = client.Transgender
          report_client.questioning = client.Questioning
          intermediate_report_clients[client] = report_client
        end

      Client.import!(
        intermediate_report_clients.values,
        batch_size: 5_000,
        on_duplicate_key_update: {
          conflict_target: [:id],
          columns: Client.attribute_names.map(&:to_sym),
        },
      )
      universe(gender_issues_slug).add_universe_members(intermediate_report_clients) if intermediate_report_clients.present?

      report_clients.merge(intermediate_report_clients)
    end

    private def gender_issues_query
      yes = 1
      no_not_collected = [0, 99]
      # any fall outside accepted options
      c_t[:Female].not_in(HUD.yes_no_missing_options.keys).
        or(c_t[:Male].not_in(HUD.yes_no_missing_options.keys)).
        or(c_t[:NoSingleGender].not_in(HUD.yes_no_missing_options.keys)).
        or(c_t[:Transgender].not_in(HUD.yes_no_missing_options.keys)).
        or(c_t[:Questioning].not_in(HUD.yes_no_missing_options.keys)).
        or(
          # any are yes and GenderNone is present
          c_t[:Female].eq(yes).
          or(c_t[:Male].eq(yes)).
          or(c_t[:NoSingleGender].eq(yes)).
          or(c_t[:Transgender].eq(yes)).
          or(c_t[:Questioning].eq(yes)).
          and(c_t[:GenderNone].not_eq(nil)),
        ).
        or(
          # all are no or not collected and GenderNone is not in 8, 9, 99
          c_t[:Female].not_in(no_not_collected).
          and(c_t[:Male].not_in(no_not_collected)).
          and(c_t[:NoSingleGender].not_in(no_not_collected)).
          and(c_t[:Transgender].not_in(no_not_collected)).
          and(c_t[:Questioning].not_in(no_not_collected)).
          and(c_t[:GenderNone].not_in([8, 9, 99])),
        )
    end

    private def race_issues(report_clients)
      intermediate_report_clients = {}
      GrdaWarehouse::Hud::Client.joins(enrollments: :service_history_enrollment).
        preload(:warehouse_client_source).
        merge(report_scope).distinct.
        where(race_issues_query).
        find_each do |client|
          report_client = report_clients[client] || Client.new(
            report_id: id,
            client_id: client.id,
            destination_client_id: client.warehouse_client_source.destination_id,
          )
          report_client.first_name = client.FirstName
          report_client.last_name = client.LastName
          report_client.personal_id = client.PersonalID
          report_client.data_source_id = client.data_source_id
          report_client.male = client.Male
          report_client.am_ind_ak_native = client.AmIndAKNative
          report_client.asian = client.Asian
          report_client.black_af_american = client.BlackAfAmerican
          report_client.native_hi_pacific = client.NativeHIPacific
          report_client.white = client.White
          report_client.race_none = client.RaceNone
          intermediate_report_clients[client] = report_client
        end

      Client.import!(
        intermediate_report_clients.values,
        batch_size: 5_000,
        on_duplicate_key_update: {
          conflict_target: [:id],
          columns: Client.attribute_names.map(&:to_sym),
        },
      )

      universe(race_issues_slug).add_universe_members(intermediate_report_clients) if intermediate_report_clients.present?

      report_clients.merge(intermediate_report_clients)
    end

    private def race_issues_query
      yes = 1
      no_not_collected = [0, 99]
      # any fall outside accepted options
      c_t[:AmIndAKNative].not_in(HUD.yes_no_missing_options.keys).
        or(c_t[:Asian].not_in(HUD.yes_no_missing_options.keys)).
        or(c_t[:BlackAfAmerican].not_in(HUD.yes_no_missing_options.keys)).
        or(c_t[:NativeHIPacific].not_in(HUD.yes_no_missing_options.keys)).
        or(c_t[:White].not_in(HUD.yes_no_missing_options.keys)).
        or(
          # any are yes and RaceNone is present
          c_t[:AmIndAKNative].eq(yes).
          or(c_t[:Asian].eq(yes)).
          or(c_t[:BlackAfAmerican].eq(yes)).
          or(c_t[:NativeHIPacific].eq(yes)).
          or(c_t[:White].eq(yes)).
          and(c_t[:RaceNone].not_eq(nil)),
        ).
        or(
          # all are no or not collected and RaceNone is not in 8, 9, 99
          c_t[:AmIndAKNative].not_in(no_not_collected).
          and(c_t[:Asian].not_in(no_not_collected)).
          and(c_t[:BlackAfAmerican].not_in(no_not_collected)).
          and(c_t[:NativeHIPacific].not_in(no_not_collected)).
          and(c_t[:White].not_in(no_not_collected)).
          and(c_t[:RaceNone].not_in([8, 9, 99])),
        )
    end

    private def gender_issues_slug
      'Gender'
    end

    private def race_issues_slug
      'Race'
    end

    def known_keys
      results.map(&:title)
    end

    def result_from_key(key)
      results.detect { |r| r.title == key }
    end

    def clients_for(key)
      universe(key).universe_members.map(&:universe_membership)
    end

    def results
      @results || validations + dq_checks
    end

    def validations
      @validations ||= [].tap do |r|
        count = universe(gender_issues_slug).count
        r << OpenStruct.new(
          title: gender_issues_slug,
          category: 'Client',
          count: count,
          total: overall_client_count,
          percent: percent(overall_client_count, count),
          item_class: HmisDataQualityTool::Client,
        )
        count = universe(race_issues_slug).count
        r << OpenStruct.new(
          title: race_issues_slug,
          category: 'Client',
          count: count,
          total: overall_client_count,
          percent: percent(overall_client_count, count),
          item_class: HmisDataQualityTool::Client,
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

    private def percent(total, partial)
      return 0 if total.blank? || total.zero? || partial.blank? || partial.zero?

      ((partial / total.to_f) * 100).round
    end
  end
end
