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
      rescue Exception => e
        update(state: 'Failed', failed_at: Time.current)
        raise e
      end
      complete
      # Run results to cache them for later
      self.class.find(id).results
    end

    def start
      update(started_at: Time.current, state: 'Started')
    end

    def complete
      update(completed_at: Time.current, state: 'Completed')
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
        f = ::Filters::HudFilterBase.new(
          user_id: user_id,
          enforce_one_year_range: false,
          require_service_during_range: false,
        )
        f.update(options.with_indifferent_access.merge(enforce_one_year_range: false, require_service_during_range: false)) if options.present?
        f
      end
    end

    private def coc_code
      if filter.coc_codes.count == 1
        filter.coc_codes.first
      else
        :default
      end
    end

    # The goal config will reflect the CoC if only one CoC was chosen, otherwise we'll use the default.
    def goal_config
      @goal_config ||= HmisDataQualityTool::Goal.for_coc(coc_code)
    end

    # for compatability with HudReport Logic
    def start_date
      @start_date ||= filter.start
    end

    def end_date
      @end_date ||= filter.end
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
      GrdaWarehouse::Hud::Project::PERFORMANCE_REPORTING.values.flatten
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
    # NOTE: you'll need to apply a date range filter in the sub-classes that merge this in
    def report_scope
      # To maintain functionality with HudFilterBase
      filter.project_ids = filter.effective_project_ids
      scope = report_scope_source
      scope = filter_for_range(scope)
      filter.apply(scope)
    end

    def can_see_client_details?(user)
      user.can_access_some_version_of_clients?
    end

    private def populate_universe
      report_clients = clients.map { |c| [c.client_id, c] }.to_h
      Client.calculate(report_items: report_clients, report: self)
      report_enrollments = enrollments.map { |e| [e.enrollment_id, e] }.to_h
      Enrollment.calculate(report_items: report_enrollments, report: self)
      report_inventories = inventories.map { |i| [i.inventory_id, e] }.to_h
      Inventory.calculate(report_items: report_inventories, report: self)
      report_current_living_situations = current_living_situations.map { |e| [e.current_living_situation_id, e] }.to_h
      CurrentLivingSituation.calculate(report_items: report_current_living_situations, report: self)
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
            she = enrollment.service_history_enrollment
            # Make sure the age reflects the reporting age
            she.age = enrollment.client.age_on(report_age_date)
            households[enrollment.HouseholdID] << she
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
      universe("#{key}__invalid").universe_members.map(&:universe_membership)
    end

    private def result_groups
      {
        'Clients' => {
          name_issues: Client,
          ssn_issues: Client,
          dob_issues: Client,
          race_issues: Client,
          ethnicity_issues: Client,
          gender_issues: Client,
          veteran_issues: Client,
        },
        'Enrollments' => {
          disabling_condition_issues: Enrollment,
          disability_at_entry_collected: Enrollment,
          living_situation_issues: Enrollment,
          hoh_validation_issues: Enrollment,
          no_hoh_issues: Enrollment,
          multiple_hoh_issues: Enrollment,
          hoh_client_location_issues: Enrollment,
          destination_issues: Enrollment,
          current_living_situation_issues: CurrentLivingSituation,
          unaccompanied_youth_issues: Enrollment,
          future_exit_date_issues: Enrollment,
          move_in_prior_to_start_issues: Enrollment,
          move_in_post_exit_issues: Enrollment,
          exit_date_issues: Enrollment,
          enrollment_outside_project_operating_dates_issues: Enrollment,
          dv_at_entry: Enrollment,
        },
        'Enrollment Length' => {
          lot_es_90_issues: Enrollment,
          lot_es_180_issues: Enrollment,
          lot_es_365_issues: Enrollment,
          days_since_last_service_so_90_issues: Enrollment,
          days_since_last_service_so_180_issues: Enrollment,
          days_since_last_service_so_365_issues: Enrollment,
          days_in_ph_prior_to_move_in_90_issues: Enrollment,
          days_in_ph_prior_to_move_in_180_issues: Enrollment,
          days_in_ph_prior_to_move_in_365_issues: Enrollment,
        },
        'Income and Benefits' => {
          income_from_any_source_at_entry: Enrollment,
          income_from_any_source_at_annual: Enrollment,
          income_from_any_source_at_exit: Enrollment,
          cash_income_as_expected_at_entry: Enrollment,
          cash_income_as_expected_at_annual: Enrollment,
          cash_income_as_expected_at_exit: Enrollment,
          ncb_as_expected_at_entry: Enrollment,
          ncb_as_expected_at_annual: Enrollment,
          ncb_as_expected_at_exit: Enrollment,
        },
        'Insurance' => {
          insurance_from_any_source_at_entry: Enrollment,
          insurance_from_any_source_at_annual: Enrollment,
          insurance_from_any_source_at_exit: Enrollment,
          insurance_as_expected_at_entry: Enrollment,
          insurance_as_expected_at_annual: Enrollment,
          insurance_as_expected_at_exit: Enrollment,
        },
        'Services' => {
          overlapping_entry_exit_issues: Client,
          overlapping_post_move_in_issues: Client,
          overlapping_nbn_issues: Client,
          overlapping_pre_move_in_issues: Client,
          days_since_last_service_es_90_issues: Enrollment,
          days_since_last_service_es_180_issues: Enrollment,
          days_since_last_service_es_365_issues: Enrollment,
        },
        'Inventory' => {
          dedicated_bed_issues: Inventory,
        },
      }
    end

    private def cache_key
      [self.class.name, id]
    end

    def uncache!
      Rails.cache.delete(cache_key)
    end

    def results
      @results ||= Rails.cache.fetch(cache_key, expires_in: 1.months) do
        [].tap do |r|
          result_groups.each do |category, slugs|
            slugs.each do |slug, item_class|
              stay_length_category, stay_length_limit = item_class.stay_length_limit(slug)
              # If we're looking at a result with a stay category option and we have a goal setup with stay lengths
              # only include those that match the goal, include all for a given category if no goal was set for that category
              next if stay_length_category.present? &&
                goal_config.stay_lengths.present? &&
                goal_config.stay_lengths.detect { |k, _| k == stay_length_category }.present? &&
                ! goal_config.stay_lengths.include?([stay_length_category, stay_length_limit])

              title = item_class.section_title(slug)
              denominator_cell = universe("#{title}__denominator")
              overall_count = denominator_cell.count
              numerator_cell = universe("#{title}__invalid")
              invalid_count = numerator_cell.count
              this_result = OpenStruct.new(
                title: title,
                description: item_class.section_description(slug),
                required_for: item_class.required_for(slug),
                category: category,
                invalid_count: invalid_count,
                total: overall_count,
                percent_invalid: percent(overall_count, invalid_count),
                percent_valid: percent(overall_count, overall_count - invalid_count),
                item_class: item_class.name,
                detail_columns: item_class.detail_headers_for(slug),
                projects: {},
                project_types: {},
              )
              filter.effective_projects.each do |project|
                # Because some metrics don't include project_id, we need to
                # use client_id for those, currently those based off the Client class
                if item_class == Client
                  overall_count = denominator_cell.
                    members.
                    where(item_class.arel_table[:destination_client_id].in(client_ids_for_project(project))).
                    count
                  invalid_count = numerator_cell.
                    members.
                    where(item_class.arel_table[:destination_client_id].in(client_ids_for_project(project))).
                    count
                else
                  overall_count = denominator_cell.
                    members.
                    where(item_class.arel_table[:project_id].eq(project.id)).
                    count
                  invalid_count = numerator_cell.
                    members.
                    where(item_class.arel_table[:project_id].eq(project.id)).
                    count
                end
                this_result[:projects][project.id] = {
                  project_name: project.name(user),
                  invalid_count: invalid_count,
                  total: overall_count,
                }
                this_result[:project_types][project.project_type_to_use] ||= { invalid_count: 0, total: 0 }
                this_result[:project_types][project.project_type_to_use][:invalid_count] += invalid_count
                this_result[:project_types][project.project_type_to_use][:total] += overall_count
              end
              r << this_result
            end
          end
        end
      end
    end

    def categories
      @categories ||= ['Overall'] + result_groups.keys
    end

    def overall_client_count
      @overall_client_count ||= Client.client_scope(self).count
    end

    def overall_enrollment_count
      @overall_enrollment_count ||= report_scope.count
    end

    def overall_inventory_count
      @overall_inventory_count ||= Inventory.inventory_scope(self).count
    end

    def overall_current_living_situation_count
      @overall_current_living_situation_count ||= CurrentLivingSituation.current_living_situation_scope(self).count
    end

    def percent(total, partial)
      return 100 if total.blank? || total.zero?
      return 0 if partial.blank? || partial.zero?

      ((partial / total.to_f) * 100).round(1)
    end

    private def client_ids_for_project(project)
      @client_ids_per_project ||= enrollments.pluck(:project_id, :destination_client_id).group_by(&:shift)
      @client_ids_per_project[project.id]&.flatten
    end

    private def count_category_setup
      {}.tap do |setup|
        categories.each do |cat|
          setup[cat] = { invalid_count: 0, total: 0 }
        end
      end
    end

    # { project_name: { overall: %, clients: %, enrollments: % ...}}
    def per_project_results
      @per_project_results ||= {}.tap do |r|
        results.each do |result|
          result.projects.each do |project_id, data|
            r[project_id] ||= count_category_setup.deep_dup
            r[project_id][result.category][:invalid_count] += data[:invalid_count]
            r[project_id][result.category][:total] += data[:total]
            r[project_id]['Overall'][:invalid_count] += data[:invalid_count]
            r[project_id]['Overall'][:total] += data[:total]
          end
        end
      end
    end

    # { project_type: { overall: %, clients: %, enrollments: % ...}}
    def per_project_type
      @per_project_type ||= {}.tap do |r|
        results.each do |result|
          result.project_types.each do |project_type_id, data|
            r[project_type_id] ||= count_category_setup.deep_dup
            r[project_type_id][result.category][:invalid_count] += data[:invalid_count]
            r[project_type_id][result.category][:total] += data[:total]
            r[project_type_id]['Overall'][:invalid_count] += data[:invalid_count]
            r[project_type_id]['Overall'][:total] += data[:total]
          end
        end
      end
    end
  end
end
