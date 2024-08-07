###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'memery'

module PerformanceMeasurement
  class Report < SimpleReports::ReportInstance
    include Memery
    include Filter::ControlSections
    include Filter::FilterScopes
    include Reporting::Status
    include SpmBasedReports
    include Rails.application.routes.url_helpers
    include ActionView::Helpers::NumberHelper
    include ArelHelper
    include PerformanceMeasurement::ResultCalculation
    include PerformanceMeasurement::Details

    include ::WarehouseReports::Publish

    attr_accessor :households

    belongs_to :user
    belongs_to :goal_configuration, class_name: 'PerformanceMeasurement::Goal'
    has_many :clients
    has_many :projects
    has_many :results
    has_many :client_projects
    has_many :published_reports, dependent: :destroy, class_name: '::GrdaWarehouse::PublishedReport'

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

    def reporting_spm_id
      @reporting_spm_id ||= clients.detect { |c| c.reporting_spm_id.present? }&.reporting_spm_id
    end

    def comparison_spm_id
      @comparison_spm_id ||= clients.detect { |c| c.comparison_spm_id.present? }&.comparison_spm_id
    end

    def using_static_spm_for_comparison?
      existing_static_comparison_spm.present?
    end

    def self.default_project_type_codes
      HudUtility2024.spm_project_type_codes
    end

    def run_and_save!
      start
      begin
        create_universe
        add_capacities
        save_results
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
        :comparison_pattern,
        :coc_code,
        :project_type_codes,
        :project_ids,
        :project_group_ids,
        :data_source_ids,
      ]
    end

    def comparison_patterns
      filter.comparison_patterns.except('None', 'Same period, prior year')
    end

    def filter=(filter_object)
      # enforce default project types if we can't choose
      filter_object.project_type_codes = self.class.default_project_type_codes unless PerformanceMeasurement::Goal.include_project_options?

      self.options = filter_object.to_h
      # force reset the filter cache
      @filter = nil
      filter
    end

    def filter
      @filter ||= begin
        f = ::Filters::HudFilterBase.new(user_id: filter_user_id, comparison_pattern: :prior_fiscal_year)
        f.default_project_type_codes = self.class.default_project_type_codes
        f.update((options || {}).with_indifferent_access)
        f.update(start: f.end - 1.years + 1.days)
        f
      end
    end

    def self.known_params
      return ::Filters::HudFilterBase.new.known_params if PerformanceMeasurement::Goal.include_project_options?

      [:end, :coc_code, :comparison_pattern]
    end

    # The filter user is dependent on the configuration
    private def filter_user_id
      return user_id if PerformanceMeasurement::Goal.include_project_options?

      User.system_user.id
    end

    def show_spm_link?
      return true if user.can_view_all_hud_reports?
      return true if user.can_view_own_hud_reports? && PerformanceMeasurement::Goal.include_project_options?

      false
    end

    def coc_code
      filter.coc_code
    end

    def goal_config
      @goal_config ||= begin
        update_goal_configuration! if persisted? && goal_configuration.blank?
        goal_configuration
      end
    end

    def update_goal_configuration!
      update(goal_configuration_id: PerformanceMeasurement::Goal.for_coc(filter.coc_code)&.id)
    end

    private def existing_static_comparison_spm
      @existing_static_comparison_spm ||= goal_config.static_spms.
        order(id: :desc).
        find_by(
          report_start: filter.comparison_range.first,
          report_end: filter.comparison_range.end,
        )
    end

    private def reset_filter
      @filter = nil
      filter
    end

    def self.viewable_by(user)
      GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: url).
        viewable_by(user).exists?
    end

    def self.url
      'performance_measurement/warehouse_reports/reports'
    end

    def url
      performance_measurement_warehouse_reports_report_url(host: ENV.fetch('FQDN'), id: id, protocol: 'https')
    end

    def title
      Translation.translate('CoC Performance Measurement Dashboard')
    end
    alias instance_title title

    private def public_s3_directory
      'performance_measurement'
    end

    def controller_class
      PerformanceMeasurement::WarehouseReports::ReportsController
    end

    def raw_layout
      'performance_measurement_external'
    end

    def multiple_project_types?
      true
    end

    def default_project_types
      HudUtility2024.spm_project_type_codes
    end

    def report_path_array
      [
        :performance_measurement,
        :warehouse_reports,
        :reports,
      ]
    end

    # @return filtered scope
    def report_scope
      processed_filter = filter
      # report uses only one coc_code, need to adjust for the HUD filter that needs coc_codes
      processed_filter.coc_codes = [processed_filter.coc_code]
      processed_filter.project_ids = processed_filter.effective_project_ids
      scope = processed_filter.apply(report_scope_source)
      scope = filter_for_range(scope)

      reset_filter
      scope
    end

    def report_scope_source
      GrdaWarehouse::ServiceHistoryEnrollment.entry
    end

    def can_see_client_details?(user)
      user.can_access_some_version_of_clients?
    end

    private def create_universe
      clients.delete_all
      projects.delete_all
      report_clients = {}
      add_clients(report_clients)
    end

    private def add_capacities
      variants.each do |period, _|
        range = if period == :reporting
          filter.as_date_range
        else
          filter.comparison_as_date_range
        end
        projects.preload(hud_project: :inventories).each do |project|
          next unless project.project_id

          average_capacity = project.hud_project.inventories.within_range(range).map do |inventory|
            inventory.average_daily_inventory(
              range: range,
              field: :BedInventory,
            )
          end.sum
          project.update("#{period}_ave_bed_capacity_per_night" => average_capacity)
        end
      end
    end

    private def spm_enrollments_from_answer_member(member)
      case member
      when HudSpmReport::Fy2023::SpmEnrollment
        [member]
      when HudSpmReport::Fy2023::Episode
        member.enrollments
      when HudSpmReport::Fy2023::Return
        [member.exit_enrollment]
      else
        raise "unknown type #{member.class.name}"
      end
    end

    private def add_clients(report_clients)
      # Run CoC-wide SPMs for year prior to selected date and period 2 years prior
      # add records for each client to indicate which projects they were enrolled in within the report window
      project_clients = {}
      involved_projects = Set.new
      run_spm.each do |variant_name, spec|
        spm_fields.each do |parts|
          cells = parts[:cells]
          cells.each do |cell|
            next if spec[:static_spm_available]

            members = cell_members(spec[:report], *cell)
            # Force household calculation for cell members
            calculate_households_for_spm(members)
            members.each do |member|
              hud_client = member.client
              spm_enrollments = spm_enrollments_from_answer_member(member)
              report_client = report_clients[hud_client.id] || Client.new(report_id: id, client_id: hud_client.id)
              report_client[:dob] = hud_client.dob
              report_client[:veteran] = hud_client.veteran?
              # SpmEnrollment.client_id seems to be the destination client
              report_client[:source_client_personal_ids] ||= spm_enrollments.map(&:client_id).sort.uniq.join('; ')
              report_client["#{variant_name}_age"] ||= spm_enrollments.map(&:age).compact&.max
              # HoH status may vary, just note if they were ever an HoH
              report_client["#{variant_name}_hoh"] ||= spm_enrollments.any? { |e| e.enrollment.head_of_household? }
              hud_project_ids = spm_enrollments.map { |e| e.enrollment.project.id }.uniq
              involved_projects += hud_project_ids
              parts[:questions].each do |question|
                report_client["#{variant_name}_#{question[:name]}"] = question[:value_calculation].call(member)
                hud_project_ids.each do |project_id|
                  pc_data = {
                    report_id: id,
                    client_id: hud_client.id,
                    project_id: project_id,
                    for_question: question[:name], # allows limiting for a specific response
                    period: variant_name,
                    household_type: household_type_for_spm(member),
                  }
                  project_clients = add_to_project_clients(project_clients, hud_client.id, pc_data)
                end
              end
              parts[:client_project_rows]&.each do |cpr|
                project_client_attrs = cpr.call(member)
                next unless project_client_attrs

                pc_data = project_client_attrs.reverse_merge(
                  report_id: id,
                  client_id: hud_client.id,
                  period: variant_name,
                  household_type: household_type_for_spm(member),
                )
                project_clients = add_to_project_clients(project_clients, hud_client.id, pc_data)
              end

              report_client["#{variant_name}_spm_id"] = spec[:report].id
              report_clients[member.client_id] = report_client
            end
          end
        end
        # Augment clients with non-SPM related data
        extra_calculations.each do |parts|
          filter.update(spec[:options])
          data = parts[:data].call(filter)
          data.each_key do |client_id|
            report_client = report_clients[client_id] || Client.new(report_id: id, client_id: client_id)
            report_client[:dob] = parts[:value_calculation].call(:dob, client_id, data)
            report_client[:source_client_personal_ids] ||= source_client_personal_ids(filter)[client_id]&.uniq&.join('; ')
            report_client["#{variant_name}_#{parts[:key]}"] = parts[:value_calculation].call(:value, client_id, data)
            # A client may have multiple Prior Living Situations, just use the first one
            report_client["#{variant_name}_prior_living_situation"] ||= parts[:value_calculation].call(:housing_status_at_entry, client_id, data)
            # HoH status may vary, just note if they were ever an HoH
            report_client["#{variant_name}_hoh"] ||= parts[:value_calculation].call(:head_of_household, client_id, data) || false

            parts[:value_calculation].call(:project_ids, client_id, data).each do |project_id, hh_type|
              involved_projects << project_id
              pc_data = {
                report_id: id,
                client_id: client_id,
                project_id: project_id,
                for_question: parts[:key], # allows limiting for a specific response
                period: variant_name,
                household_type: hh_type,
              }
              project_clients = add_to_project_clients(project_clients, client_id, pc_data)
            end
            report_clients[client_id] = report_client
          end
          reset_filter
        end
        # Summary calculations, all based on existing data
        summary_calculations.each do |parts|
          report_clients.each do |client_id, client|
            value = parts[:value_calculation].call(client, variant_name) || false
            client["#{variant_name}_#{parts[:key]}"] = value
            next unless value

            # Use the previously calculated household_type, for now, just get the first for the client
            # that matches one of the prior calculations
            project_client = project_clients[client_id]&.detect do |pc|
              pc[:for_question].in?(parts[:household_type_keys])
            end

            # These are only system level
            pc_data = {
              report_id: id,
              client_id: client_id,
              project_id: nil,
              for_question: parts[:key], # allows limiting for a specific response
              period: variant_name,
              household_type: project_client.try(:[], :household_type),
            }
            project_clients = add_to_project_clients(project_clients, client_id, pc_data)
          end
        end
      end

      Client.import!(
        report_clients.values,
        batch_size: 5_000,
        on_duplicate_key_update: {
          conflict_target: [:id],
          columns: Client.attribute_names.map(&:to_sym),
        },
      )
      Project.import!([:report_id, :project_id], involved_projects.map { |p_id| [id, p_id] }, batch_size: 5_000)
      # Enforce that the hashes in project_clients have all the necessary columns defined by converting it to an array of ClientProject records
      ClientProject.import!(project_clients.values.flat_map(&:to_a).compact.map { |attr| ClientProject.new(attr) }, batch_size: 5_000)
      universe.add_universe_members(report_clients)
    end

    private def add_to_project_clients(project_clients, client_id, data)
      project_clients[client_id] ||= Set.new
      project_clients[client_id] << data
      project_clients
    end

    private def answer(report, table, cell)
      report.answer(question: table, cell: cell).summary
    end

    # @return [SpmEnrollment, Episode, Return] Cells have different member entity types
    private def cell_members(report, table, cell)
      scope = report.answer(question: table, cell: cell).universe_members.preload(universe_membership: :client)
      preloaded_scope = case table
      when '1a', '1b'
        # Episode
        # universe membership has spm_enrollments which have hud enrollments
        scope.preload(universe_membership: { enrollments: { enrollment: :project } })
      when '2a and 2b'
        # Return
        scope.preload(universe_membership: { exit_enrollment: { enrollment: :project } })
      else
        # SpmEnrollment
        scope.preload(universe_membership: { enrollment: :project })
      end
      preloaded_scope.map(&:universe_membership)
    end

    private def source_client_personal_ids(filter)
      @source_client_personal_ids ||= {}.tap do |data|
        report_scope.joins(:service_history_services, :project, :client).
          preload(client: :source_clients).
          where(shs_t[:date].eq(filter.pit_date)).
          find_each(batch_size: 10_000) do |she|
            client = she.client
            data[client.id] = client.source_clients.map(&:PersonalID)
          end
      end
    end

    private def household_type_for_extra(ages)
      adult = ages.any? { |age| age.present? && age >= 18 }
      child = ages.any? { |age| age.present? && age.between?(0, 18) }
      unknown = ages.any?(&:blank?)

      return HudUtility2024.household_type('Households with at least one adult and one child', true) if adult && child
      return nil if unknown
      return HudUtility2024.household_type('Households without children', true) if ages.all? { |age| age.present? && age >= 18 }

      HudUtility2024.household_type('Households with only children', true) if ages.all? { |age| age.present? && age.between?(0, 18) }
    end

    # Use the household ID if present, otherwise a made-up one for the enrollment
    private def hh_id_for_row(hh_id, enrollment_id)
      hh_id.presence || "en-#{enrollment_id}"
    end

    private def calculate_households_for_extra(rows, columns, date = filter.start)
      @households = rows.map do |row|
        row = columns.zip(row).to_h
        [
          hh_id_for_row(row[:hh_id], row[:enrollment_id]),
          GrdaWarehouse::Hud::Client.age(date: date, dob: row[:dob]),
        ]
      end.group_by(&:shift)
    end

    # Generate some household data for clients where all we have is a client id and project id
    private def household_types_for_all_report_scope_project_client_combinations
      @household_types_for_all_report_scope_project_client_combinations ||= {}.tap do |data|
        cols = {
          client_id: :client_id,
          project_id: p_t[:id],
          household_id: e_t[:HouseholdID],
          dob: c_t[:dob],
        }
        # only calculate household-type for enrollments with household ids
        households = {}
        report_scope.joins(:project, :enrollment, :client).
          where(e_t[:HouseholdID].not_eq(nil)).
          pluck(*cols.values).each do |row|
            row = cols.keys.zip(row).to_h
            households[row[:household_id]] ||= []
            households[row[:household_id]] << row
          end
        households.each do |_, rows|
          ages = rows.map do |row|
            GrdaWarehouse::Hud::Client.age(date: filter.start, dob: row[:dob])
          end
          # Since we don't know the enrollment_id later, we're just going to take the first one we find for each member of the household
          rows.each do |row|
            data[client_project_hh_key(row[:client_id], row[:project_id])] ||= household_type_for_extra(ages)
          end
        end
      end
    end

    private def client_project_hh_key(client_id, project_id)
      ['c--', client_id, 'p--', project_id].join('_')
    end

    private def extra_calculations # rubocop:disable Metrics/AbcSize
      extras = [
        {
          key: :served_on_pit_date,
          data: ->(filter) {
            {}.tap do |project_types_by_client_id|
              cols = {
                client_id: :client_id,
                dob: c_t[:DOB],
                project_id: p_t[:id],
                housing_status_at_entry: e_t[:LivingSituation],
                head_of_household: :head_of_household,
                hh_id: e_t[:HouseholdID],
                enrollment_id: e_t[:id],
              }
              rows = report_scope.joins(:service_history_services, :project, :client, :enrollment).
                where(shs_t[:date].eq(filter.pit_date)).
                homeless.distinct.
                pluck(*cols.values)

              calculate_households_for_extra(rows, cols.keys, filter.pit_date)

              rows.each do |row|
                row = cols.keys.zip(row).to_h
                hh_id = hh_id_for_row(row[:hh_id], row[:enrollment_id])
                ages = households[hh_id].flatten
                project_types_by_client_id[row[:client_id]] ||= {
                  value: true,
                  project_ids: {},
                  dob: row[:dob],
                  housing_status_at_entry: row[:housing_status_at_entry],
                  head_of_household: row[:head_of_household],
                  household_id: hh_id,
                }
                project_types_by_client_id[row[:client_id]][:project_ids][row[:project_id]] = household_type_for_extra(ages)
              end
            end
          },
          value_calculation: ->(calculation, client_id, data) {
            details = data[client_id]
            return unless details.present?

            details[calculation]
          },
        },
        {
          key: :served_on_pit_date_unsheltered, # note, actually yearly overall count
          data: ->(_) {
            {}.tap do |project_types_by_client_id|
              cols = {
                client_id: :client_id,
                dob: c_t[:DOB],
                project_id: p_t[:id],
                housing_status_at_entry: e_t[:LivingSituation],
                head_of_household: :head_of_household,
                hh_id: e_t[:HouseholdID],
                enrollment_id: e_t[:id],
              }
              rows = report_scope.joins(:service_history_services, :project, :client, :enrollment).
                # where(shs_t[:date].eq(filter.pit_date)). # removed to become yearly to match SPM M3 3.2
                so.distinct.
                pluck(*cols.values)
              # NOTE: even though we're pullin for the full year, we're using age on the PIT date for now.
              calculate_households_for_extra(rows, cols.keys, filter.pit_date)
              rows.each do |row|
                row = cols.keys.zip(row).to_h
                hh_id = hh_id_for_row(row[:hh_id], row[:enrollment_id])
                ages = households[hh_id].flatten
                project_types_by_client_id[row[:client_id]] ||= {
                  value: true,
                  project_ids: {},
                  dob: row[:dob],
                  housing_status_at_entry: row[:housing_status_at_entry],
                  head_of_household: row[:head_of_household],
                  household_id: hh_id,
                }
                project_types_by_client_id[row[:client_id]][:project_ids][row[:project_id]] = household_type_for_extra(ages)
              end
            end
          },
          value_calculation: ->(calculation, client_id, data) {
            details = data[client_id]
            return unless details.present?

            details[calculation]
          },
        },
        {
          key: :days_in_homeless_bed_details,
          data: ->(_filter) {
            {}.tap do |days_by_client_id|
              scope = report_scope.joins(:service_history_services, :project, :client).
                in_project_type([0, 1, 2, 4, 8]).
                distinct
              dobs = scope.pluck(:client_id, c_t[:DOB]).to_h
              scope.group(:client_id, p_t[:id]).
                count(shs_t[:date]).
                each do |(client_id, project_id), days|
                  days_by_client_id[client_id] ||= {
                    value: [],
                    project_ids: {},
                    dob: nil,
                    household_id: client_project_hh_key(client_id, project_id),
                  }
                  days_by_client_id[client_id][:value] << { project_id => days }
                  days_by_client_id[client_id][:project_ids][project_id] = household_types_for_all_report_scope_project_client_combinations[client_project_hh_key(client_id, project_id)]
                  days_by_client_id[client_id][:dob] = dobs[client_id]
                end
            end
          },
          value_calculation: ->(calculation, client_id, data) {
            details = data[client_id]
            return unless details.present?

            details[calculation]
          },
        },
        {
          key: :days_in_homeless_bed,
          data: ->(_filter) {
            {}.tap do |days_by_client_id|
              scope = report_scope.joins(:service_history_services, :project, :client).
                in_project_type([0, 1, 2, 4, 8]).
                distinct
              dobs = scope.pluck(:client_id, c_t[:DOB]).to_h
              scope.group(:client_id, p_t[:id]).
                count(shs_t[:date]).
                each do |(client_id, project_id), days|
                  days_by_client_id[client_id] ||= {
                    value: 0,
                    project_ids: {},
                    dob: nil,
                    household_id: client_project_hh_key(client_id, project_id),
                  }
                  days_by_client_id[client_id][:value] += days
                  days_by_client_id[client_id][:project_ids][project_id] = household_types_for_all_report_scope_project_client_combinations[client_project_hh_key(client_id, project_id)]
                  days_by_client_id[client_id][:dob] = dobs[client_id]
                end
            end
          },
          value_calculation: ->(calculation, client_id, data) {
            details = data[client_id]
            return unless details.present?

            details[calculation]
          },
        },
        {
          key: :days_in_homeless_bed_in_period,
          data: ->(_filter) {
            {}.tap do |days_by_client_id|
              scope = report_scope.joins(:service_history_services, :project, :client).
                merge(GrdaWarehouse::ServiceHistoryService.where(date: filter.range)).
                in_project_type([0, 1, 2, 4, 8]).
                distinct
              dobs = scope.pluck(:client_id, c_t[:DOB]).to_h
              scope.group(:client_id, p_t[:id]).
                count(shs_t[:date]).
                each do |(client_id, project_id), days|
                  days_by_client_id[client_id] ||= {
                    value: 0,
                    project_ids: {},
                    dob: nil,
                    household_id: client_project_hh_key(client_id, project_id),
                  }
                  days_by_client_id[client_id][:value] += days
                  days_by_client_id[client_id][:project_ids][project_id] = household_types_for_all_report_scope_project_client_combinations[client_project_hh_key(client_id, project_id)]
                  days_by_client_id[client_id][:dob] = dobs[client_id]
                end
            end
          },
          value_calculation: ->(calculation, client_id, data) {
            details = data[client_id]
            return unless details.present?

            details[calculation]
          },
        },
        {
          key: :days_in_homeless_bed_details_in_period,
          data: ->(_filter) {
            {}.tap do |days_by_client_id|
              scope = report_scope.joins(:service_history_services, :project, :client).
                merge(GrdaWarehouse::ServiceHistoryService.where(date: filter.range)).
                in_project_type([0, 1, 2, 4, 8]).
                distinct
              dobs = scope.pluck(:client_id, c_t[:DOB]).to_h
              scope.group(:client_id, p_t[:id]).
                count(shs_t[:date]).
                each do |(client_id, project_id), days|
                  days_by_client_id[client_id] ||= {
                    value: [],
                    project_ids: {},
                    dob: nil,
                    household_id: client_project_hh_key(client_id, project_id),
                  }
                  days_by_client_id[client_id][:value] << { project_id => days }
                  days_by_client_id[client_id][:project_ids][project_id] = household_types_for_all_report_scope_project_client_combinations[client_project_hh_key(client_id, project_id)]
                  days_by_client_id[client_id][:dob] = dobs[client_id]
                end
            end
          },
          value_calculation: ->(calculation, client_id, data) {
            details = data[client_id]
            return unless details.present?

            details[calculation]
          },
        },
        {
          key: :days_homeless_before_move_in,
          data: ->(_filter) {
            {}.tap do |days_by_client_id|
              # NOTE for later, the following should get days before move-in including those with no move in
              # scope = report_scope.joins(:service_history_services, :project, :client).
              #   permanent_housing.
              #   # After move-in, homeless is marked false
              #   merge(GrdaWarehouse::ServiceHistoryService.where(homeless: nil)).
              #   distinct
              # dobs = scope.pluck(:client_id, c_t[:DOB]).to_h
              # scope.group(:client_id, p_t[:id]).
              #   count(shs_t[:date]).

              # For now, we're going to only include client's who have moved in
              scope = report_scope.joins(:project, :client).
                permanent_housing.
                where.not(move_in_date: nil).
                distinct
              dobs = scope.pluck(:client_id, c_t[:DOB]).to_h
              scope.pluck(:client_id, p_t[:id], :first_date_in_program, :move_in_date).
                each do |client_id, project_id, entry_date, move_in|
                  days = if move_in < entry_date
                    # Catch anyone who entered the enrollment
                    # after the HoH move-in (children born, other household members added later, etc.)
                    0
                  else
                    (move_in - entry_date).to_i
                  end
                  days_by_client_id[client_id] ||= {
                    value: 0,
                    project_ids: {},
                    dob: nil,
                    household_id: client_project_hh_key(client_id, project_id),
                  }
                  days_by_client_id[client_id][:value] += days
                  days_by_client_id[client_id][:project_ids][project_id] = household_types_for_all_report_scope_project_client_combinations[client_project_hh_key(client_id, project_id)]
                  days_by_client_id[client_id][:dob] = dobs[client_id]
                end
            end
          },
          value_calculation: ->(calculation, client_id, data) {
            details = data[client_id]
            return unless details.present?

            details[calculation]
          },
        },
        {
          key: :destination,
          data: ->(_filter) {
            {}.tap do |destination_client_id|
              scope = report_scope.joins(:project, :client).
                where.not(last_date_in_program: nil, destination: nil).
                distinct
              dobs = scope.pluck(:client_id, c_t[:DOB]).to_h
              scope.pluck(:client_id, p_t[:id], :destination).
                each do |client_id, project_id, destination|
                  destination_client_id[client_id] ||= {
                    value: nil,
                    project_ids: {},
                    dob: nil,
                    household_id: client_project_hh_key(client_id, project_id),
                  }
                  destination_client_id[client_id][:value] = destination
                  destination_client_id[client_id][:project_ids][project_id] = household_types_for_all_report_scope_project_client_combinations[client_project_hh_key(client_id, project_id)]
                  destination_client_id[client_id][:dob] = dobs[client_id]
                end
            end
          },
          value_calculation: ->(calculation, client_id, data) {
            details = data[client_id]
            return unless details.present?

            details[calculation]
          },
        },
      ]
      [:es, :sh, :so, :th, :psh, :oph, :rrh].each do |p_type|
        extras << {
          key: "days_in_#{p_type}_bed_details".to_sym,
          data: ->(_filter) {
            {}.tap do |days_by_client_id|
              scope = report_scope.joins(:service_history_services, :project, :client).
                send(p_type).
                distinct
              dobs = scope.pluck(:client_id, c_t[:DOB]).to_h
              scope.group(:client_id, p_t[:id]).
                count(shs_t[:date]).
                each do |(client_id, project_id), days|
                  days_by_client_id[client_id] ||= {
                    value: [],
                    project_ids: {},
                    dob: nil,
                    household_id: client_project_hh_key(client_id, project_id),
                  }
                  days_by_client_id[client_id][:value] << { project_id => days }
                  days_by_client_id[client_id][:project_ids][project_id] = household_types_for_all_report_scope_project_client_combinations[client_project_hh_key(client_id, project_id)]
                  days_by_client_id[client_id][:dob] = dobs[client_id]
                end
            end
          },
          value_calculation: ->(calculation, client_id, data) {
            details = data[client_id]
            return unless details.present?

            details[calculation]
          },
        }
        extras << {
          key: "days_in_#{p_type}_bed".to_sym,
          data: ->(_filter) {
            {}.tap do |days_by_client_id|
              scope = report_scope.joins(:service_history_services, :project, :client).
                send(p_type).
                distinct
              dobs = scope.pluck(:client_id, c_t[:DOB]).to_h
              scope.group(:client_id, p_t[:id]).
                count(shs_t[:date]).
                each do |(client_id, project_id), days|
                  days_by_client_id[client_id] ||= {
                    value: 0,
                    project_ids: {},
                    dob: nil,
                    household_id: client_project_hh_key(client_id, project_id),
                  }
                  days_by_client_id[client_id][:value] += days
                  days_by_client_id[client_id][:project_ids][project_id] = household_types_for_all_report_scope_project_client_combinations[client_project_hh_key(client_id, project_id)]
                  days_by_client_id[client_id][:dob] = dobs[client_id]
                end
            end
          },
          value_calculation: ->(calculation, client_id, data) {
            details = data[client_id]
            return unless details.present?

            details[calculation]
          },
        }
        extras << {
          key: "days_in_#{p_type}_bed_in_period".to_sym,
          data: ->(_filter) {
            {}.tap do |days_by_client_id|
              scope = report_scope.joins(:service_history_services, :project, :client).
                merge(GrdaWarehouse::ServiceHistoryService.where(date: filter.range)).
                send(p_type).
                distinct
              dobs = scope.pluck(:client_id, c_t[:DOB]).to_h
              scope.group(:client_id, p_t[:id]).
                count(shs_t[:date]).
                each do |(client_id, project_id), days|
                  days_by_client_id[client_id] ||= {
                    value: 0,
                    project_ids: {},
                    dob: nil,
                    household_id: client_project_hh_key(client_id, project_id),
                  }
                  days_by_client_id[client_id][:value] += days
                  days_by_client_id[client_id][:project_ids][project_id] = household_types_for_all_report_scope_project_client_combinations[client_project_hh_key(client_id, project_id)]
                  days_by_client_id[client_id][:dob] = dobs[client_id]
                  # FIXME: needs household type
                end
            end
          },
          value_calculation: ->(calculation, client_id, data) {
            details = data[client_id]
            return unless details.present?

            details[calculation]
          },
        }
        extras << {
          key: "days_in_#{p_type}_bed_details_in_period".to_sym,
          data: ->(_filter) {
            {}.tap do |days_by_client_id|
              scope = report_scope.joins(:service_history_services, :project, :client).
                merge(GrdaWarehouse::ServiceHistoryService.where(date: filter.range)).
                send(p_type).
                distinct
              dobs = scope.pluck(:client_id, c_t[:DOB]).to_h
              scope.group(:client_id, p_t[:id]).
                count(shs_t[:date]).
                each do |(client_id, project_id), days|
                  days_by_client_id[client_id] ||= {
                    value: [],
                    project_ids: {},
                    dob: nil,
                    household_id: client_project_hh_key(client_id, project_id),
                  }
                  days_by_client_id[client_id][:value] << { project_id => days }
                  days_by_client_id[client_id][:project_ids][project_id] = household_types_for_all_report_scope_project_client_combinations[client_project_hh_key(client_id, project_id)]
                  days_by_client_id[client_id][:dob] = dobs[client_id]
                end
            end
          },
          value_calculation: ->(calculation, client_id, data) {
            details = data[client_id]
            return unless details.present?

            details[calculation]
          },
        }
      end
      extras
    end

    PERMANENT_DESTINATIONS = HudSpmReport::Generators::Fy2023::MeasureSeven::PERMANENT_DESTINATIONS
    PERMANENT_DESTINATIONS_OR_STAYER = (PERMANENT_DESTINATIONS + [0]).freeze
    PERMANENT_TEMPORARY_AND_INSTITUTIONAL_DESTINATIONS = (
      PERMANENT_DESTINATIONS +
      HudSpmReport::Generators::Fy2023::MeasureSeven::TEMPORARY_AND_INSTITUTIONAL_DESTINATIONS
    ).freeze

    private def summary_calculations
      [
        {
          key: :seen_in_range,
          value_calculation: ->(client, variant_name) {
            client["#{variant_name}_served_on_pit_date_sheltered"] ||
            client["#{variant_name}_served_on_pit_date_unsheltered"]
          },
          household_type_keys: [
            :served_on_pit_date_sheltered,
            :served_on_pit_date_unsheltered,
          ],
        },
        {
          key: :retention_or_positive_destination,
          value_calculation: ->(client, variant_name) {
            return true if PERMANENT_DESTINATIONS.include?(client.send("#{variant_name}_so_destination"))
            return true if PERMANENT_DESTINATIONS.include?(client.send("#{variant_name}_es_sh_th_rrh_destination"))
            return true if PERMANENT_DESTINATIONS_OR_STAYER.include?(client.send("#{variant_name}_moved_in_destination"))

            false
          },
          household_type_keys: [
            :so_destination,
            :es_sh_th_rrh_destination,
            :moved_in_destination,
          ],
        },
      ]
    end

    private def run_spm
      # puts 'Running SPM'
      questions = [
        'Measure 1',
        'Measure 2',
        'Measure 3',
        'Measure 4',
        'Measure 5',
        'Measure 7',
      ]

      options = filter.to_h
      # Because we want data back for all projects in the CoC we need to run this as the System User who will have access to everything
      options[:user_id] = filter_user_id

      # Re-enable the following if you don't want to have to run SPMs during development
      # if Rails.env.development?
      #   variants.values.reverse.each.with_index do |spec, i|
      #     spec[:report] = HudReports::ReportInstance.automated.complete.order(id: :desc).first(2)[i]
      #   end
      # else
      generator = HudSpmReport.current_generator
      variants.each do |_, spec|
        next if spec[:static_spm_available]

        processed_filter = ::Filters::HudFilterBase.new(user_id: options[:user_id])
        processed_filter.update(options.deep_merge(spec[:options]))
        processed_filter.comparison_pattern = :no_comparison_period
        # report uses only one coc_code, need to adjust for the HUD filter that needs coc_codes
        processed_filter.coc_codes = [filter.coc_code]
        report = HudReports::ReportInstance.from_filter(
          processed_filter,
          generator.title,
          build_for_questions: questions,
        )
        generator.new(report).run!(email: false, manual: false)
        spec[:report] = report
        # end
      end
      # return @variants with reports for each question
      variants
    end

    def variants
      @variants ||= {
        reporting: {
          options: {},
        },
        comparison: {
          options: {
            start: filter.comparison_range.first,
            end: filter.comparison_range.end,
          },
          static_spm_available: existing_static_comparison_spm.present?,
        },
      }
    end

    private def household_type_for_spm(member)
      ages = households[hh_id_for_spm(member)]
      adult = ages.any? { |age| age.present? && age >= 18 }
      child = ages.any? { |age| age.present? && age.between?(0, 18) }
      unknown = ages.any?(&:blank?)

      return HudUtility2024.household_type('Households with at least one adult and one child', true) if adult && child
      return nil if unknown
      return HudUtility2024.household_type('Households without children', true) if ages.all? { |age| age.present? && age >= 18 }
      return HudUtility2024.household_type('Households with only children', true) if ages.all? { |age| age.present? && age.between?(0, 18) }
    end

    # Use the household ID if present, otherwise a made-up one for the enrollment
    private def hh_id_for_spm(member)
      spm_enrollment = relevant_spm_enrollment_for(member)
      spm_enrollment.enrollment.household_id.presence || "en-#{spm_enrollment.enrollment.id}"
    end

    # members can take a handful of forms, so grab the last associated enrollment
    private def relevant_spm_enrollment_for(member)
      spm_enrollments_from_answer_member(member).last
    end

    # For all SPM enrollments, that are used in calculations, determine the household type
    private def calculate_households_for_spm(members)
      @households = {}.tap do |hh|
        members.each do |member|
          hh_id = hh_id_for_spm(member)
          hh[hh_id] ||= []
          hh[hh_id] << relevant_spm_enrollment_for(member).age
        end
      end
    end

    def spm_fields
      default_calculation = ->(spm_enrollment) { spm_enrollment.present? }
      days_homeless_calculation = ->(spm_episode) { spm_episode.days_homeless }
      destination_calculation = ->(spm_enrollment) { spm_enrollment.destination }
      days_to_return_calculation = ->(spm_return) { spm_return.days_to_return }
      exit_destination_calculation = ->(spm_return) { spm_return.exit_destination }
      increased_non_employment_income_calculation = ->(spm_enrollment) {
        spm_enrollment.current_non_employment_income.to_f > spm_enrollment.previous_non_employment_income.to_f
      }
      increased_total_income_calculation = ->(spm_enrollment) {
        spm_enrollment.current_total_income.to_f > spm_enrollment.previous_total_income.to_f
      }
      increased_earned_income_calculation = ->(spm_enrollment) {
        spm_enrollment.current_earned_income.to_f > spm_enrollment.previous_earned_income.to_f
      }
      [
        {
          cells: [['3.2', 'C2']],
          title: 'Sheltered Clients',
          measure: :m3,
          history_source: :m3_history,
          questions: [
            {
              name: :served_on_pit_date_sheltered, # Poorly named, this is actually a yearly count
              # value_calculation: ->(spm_client) { spm_client[:m3_active_project_types].present? },
              value_calculation: default_calculation,
            },
          ],
        },
        {
          cells: [['5.1', 'C4']],
          title: 'First Time',
          measure: :m5,
          history_source: :m5_history,
          questions: [
            {
              name: :first_time,
              value_calculation: default_calculation,
            },
          ],
        },
        {
          cells: [['1a', 'B2']],
          title: 'Length of Time Homeless in ES, SH, TH',
          measure: :m1,
          history_source: :m1_history,
          questions: [
            {
              name: :days_homeless_es_sh_th,
              value_calculation: days_homeless_calculation,
            },
          ],
        },
        {
          cells: [['1b', 'B2']],
          title: 'Length of Time Homeless in ES, SH, TH, PH',
          measure: :m1,
          history_source: :m1_history,
          questions: [
            {
              name: :days_homeless_es_sh_th_ph,
              value_calculation: days_homeless_calculation,
            },
          ],
        },
        {
          cells: [['7a.1', 'C2']],
          title: 'Exits from SO',
          measure: :m7,
          history_source: :m7_history,
          questions: [
            {
              name: :so_destination,
              value_calculation: destination_calculation,
            },
          ],
          client_project_rows: [
            ->(spm_enrollment) {
              return unless destination_calculation.call(spm_enrollment)

              {
                project_id: spm_enrollment.enrollment.project.id,
                for_question: :so_destination,
              }
            },
            ->(spm_enrollment) {
              # list from drivers/hud_spm_report/app/models/hud_spm_report/generators/fy2020/measure_seven.rb
              # represents institutional and permanent destinations for 7a.1 C3 and C4
              return unless destination_calculation.call(spm_enrollment).in?(PERMANENT_TEMPORARY_AND_INSTITUTIONAL_DESTINATIONS)

              {
                project_id: spm_enrollment.enrollment.project.id,
                for_question: :so_destination_positive,
              }
            },
          ],
        },
        {
          cells: [['7b.1', 'C2']],
          title: 'Exits from ES, SH, TH, RRH, PH with No Move-in',
          measure: :m7,
          history_source: :m7b_history,
          questions: [
            {
              name: :es_sh_th_rrh_destination,
              value_calculation: destination_calculation,
            },
          ],
          client_project_rows: [
            ->(spm_enrollment) {
              return unless destination_calculation.call(spm_enrollment)

              {
                project_id: spm_enrollment.enrollment.project.id,
                for_question: :es_sh_th_rrh_destination,
              }
            },
            ->(spm_enrollment) {
              return unless destination_calculation.call(spm_enrollment).in?(PERMANENT_DESTINATIONS)

              {
                project_id: spm_enrollment.enrollment.project.id,
                for_question: :es_sh_th_rrh_destination_positive,
              }
            },
          ],
        },
        {
          cells: [['7b.2', 'C2']],
          title: 'RRH, PH with Move-in or Permanent Exit',
          measure: :m7,
          history_source: :m7b_history,
          questions: [
            {
              name: :moved_in_destination, # NOTE: destination 0 == stayer in the SPM
              value_calculation: destination_calculation,
            },
          ],
          client_project_rows: [
            ->(spm_enrollment) {
              return unless destination_calculation.call(spm_enrollment)

              {
                project_id: spm_enrollment.enrollment.project.id,
                for_question: :moved_in_destination,
              }
            },
            ->(spm_enrollment) {
              return unless destination_calculation.call(spm_enrollment).in?(PERMANENT_DESTINATIONS_OR_STAYER)

              {
                project_id: spm_enrollment.enrollment.project.id,
                for_question: :moved_in_destination_positive,
              }
            },
          ],
        },
        {
          cells: [['2a and 2b', 'B7']],
          title: 'Returned to Homelessness Within 6 months',
          measure: :m2,
          history_source: :m2_history,
          questions: [
            {
              name: :days_to_return,
              value_calculation: days_to_return_calculation,
            },
            {
              name: :prior_destination,
              value_calculation: exit_destination_calculation,
            },
          ],
          # This needs to introspect on the number of days to re-entry and save off extra client_project records
          client_project_rows: [
            ->(spm_return) {
              return unless days_to_return_calculation.call(spm_return)&.between?(1, 180)

              {
                project_id: spm_return.exit_enrollment.enrollment.project.id,
                for_question: :returned_in_six_months,
              }
            },
            ->(spm_return) {
              return unless days_to_return_calculation.call(spm_return)&.between?(1, 365)

              {
                project_id: spm_return.exit_enrollment.enrollment.project.id,
                for_question: :returned_in_one_year,
              }
            },
            ->(spm_return) {
              return unless days_to_return_calculation.call(spm_return)&.between?(1, 730)

              {
                project_id: spm_return.exit_enrollment.enrollment.project.id,
                for_question: :returned_in_two_years,
              }
            },
            ->(spm_return) {
              return unless exit_destination_calculation.call(spm_return).in?(PERMANENT_DESTINATIONS)

              {
                project_id: spm_return.exit_enrollment.enrollment.project.id,
                for_question: :exited_to_permanent_destination,
              }
            },
          ],
        },
        {
          cells: [['4.3', 'C2']],
          title: 'Stayers with Increased Income',
          measure: :m4,
          history_source: :m4_history,
          questions: [
            {
              name: :income_stayer,
              value_calculation: default_calculation,
            },
            {
              name: :increased_income,
              value_calculation: increased_total_income_calculation,
            },
          ],
          client_project_rows: [
            ->(spm_enrollment) {
              return unless increased_total_income_calculation.call(spm_enrollment)

              {
                project_id: spm_enrollment.enrollment.project.id,
                for_question: :increased_income__income_stayer,
              }
            },
          ],
        },
        {
          cells: [['4.1', 'C2']],
          title: 'Stayers with Increased Earned Income',
          measure: :m4,
          history_source: :m4_history,
          questions: [
            {
              name: :earned_income_stayer,
              value_calculation: increased_earned_income_calculation,
            },
          ],
          client_project_rows: [
            ->(spm_enrollment) {
              return unless increased_earned_income_calculation.call(spm_enrollment)

              {
                project_id: spm_enrollment.enrollment.project.id,
                for_question: :increased_income__earned_income_stayer,
              }
            },
          ],
        },
        {
          cells: [['4.2', 'C2']],
          title: 'Stayers with Increased Non-Cash Income',
          measure: :m4,
          history_source: :m4_history,
          questions: [
            {
              name: :non_employment_income_stayer,
              value_calculation: increased_non_employment_income_calculation,
            },
          ],
          client_project_rows: [
            ->(spm_enrollment) {
              return unless increased_non_employment_income_calculation.call(spm_enrollment)

              {
                project_id: spm_enrollment.enrollment.project.id,
                for_question: :increased_income__non_earned_income_stayer,
              }
            },
          ],
        },
        {
          cells: [['4.6', 'C2']],
          title: 'Leavers with Increased Income',
          measure: :m4,
          history_source: :m4_history,
          questions: [
            {
              name: :income_leaver,
              value_calculation: default_calculation,
            },
            {
              name: :increased_income,
              value_calculation: increased_total_income_calculation,
            },
          ],
          client_project_rows: [
            ->(spm_enrollment) {
              return unless increased_total_income_calculation.call(spm_enrollment)

              {
                project_id: spm_enrollment.enrollment.project.id,
                for_question: :increased_income__income_leaver,
              }
            },
          ],
        },
        {
          cells: [['4.4', 'C2']],
          title: 'Leavers with Increased Earned Income',
          measure: :m4,
          history_source: :m4_history,
          questions: [
            {
              name: :earned_income_leaver,
              value_calculation: increased_earned_income_calculation,
            },
          ],
          client_project_rows: [
            ->(spm_enrollment) {
              return unless increased_earned_income_calculation.call(spm_enrollment)

              {
                project_id: spm_enrollment.enrollment.project.id,
                for_question: :increased_income__earned_income_leaver,
              }
            },
          ],
        },
        {
          cells: [['4.5', 'C2']],
          title: 'Leavers with Increased Non-Cash Income',
          measure: :m4,
          history_source: :m4_history,
          questions: [
            {
              name: :non_employment_income_leaver,
              value_calculation: increased_non_employment_income_calculation,
            },
          ],
          client_project_rows: [
            ->(spm_enrollment) {
              return unless increased_non_employment_income_calculation.call(spm_enrollment)

              {
                project_id: spm_enrollment.enrollment.project.id,
                for_question: :increased_income__non_earned_income_leaver,
              }
            },
          ],
        },
      ]
    end

    # Publishing
    def publish_summary?
      true
    end

    def publish_summary_url
      return unless publish_summary?
      return unless published_report.present?

      published_report.published_url.gsub('index.html', 'summary.html')
    end

    def publish_summary_embed_code
      return unless publish_summary?
      return unless published_report.present?

      published_report.embed_code.gsub(published_report.published_url, publish_summary_url)
    end

    def view_summary_template
      :raw_summary
    end

    def summary_as_html
      return controller_class.render(view_summary_template, layout: raw_layout, assigns: { report: self }) unless view_template.is_a?(Array)

      view_template.map do |template|
        string = html_section_start(template)
        string << controller_class.render(template, layout: raw_layout, assigns: { report: self })
        string << html_section_end(template)
      end.join
    end

    def publish_files
      [
        {
          name: 'index.html',
          content: -> { as_html },
          type: 'text/html',
        },
        {
          name: 'summary.html',
          content: -> { summary_as_html },
          type: 'text/html',
        },
        {
          name: 'application.css',
          content: -> {
            css = Rails.application.assets['application.css'].to_s
            # need to replace the paths to the font files
            [
              'icons.ttf',
              'icons.svg',
              'icons.eot',
              'icons.woff',
              'icons.woff2',
            ].each do |filename|
              css.gsub!("url(/assets/#{Rails.application.assets[filename].digest_path}", "url(#{filename}")
              # Also replace development version of assets url
              css.gsub!("url(/dev-assets/#{Rails.application.assets[filename].digest_path}", "url(#{filename}")
            end
            css
          },
          type: 'text/css',
        },
        {
          name: 'icons.ttf',
          content: -> { Rails.application.assets['icons.ttf'].to_s },
          type: 'text/css',
        },
        {
          name: 'icons.svg',
          content: -> { Rails.application.assets['icons.svg'].to_s },
          type: 'text/css',
        },
        {
          name: 'icons.eot',
          content: -> { Rails.application.assets['icons.eot'].to_s },
          type: 'text/css',
        },
        {
          name: 'icons.woff',
          content: -> { Rails.application.assets['icons.woff'].to_s },
          type: 'text/css',
        },
        {
          name: 'icons.woff2',
          content: -> { Rails.application.assets['icons.woff'].to_s },
          type: 'text/css',
        },
      ]
    end

    private def asset_path(asset)
      Rails.root.join('app', 'assets', 'javascripts', 'warehouse_reports', 'performance_measurement', asset)
    end
  end
end
