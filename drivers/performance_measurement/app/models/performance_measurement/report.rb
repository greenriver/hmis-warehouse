###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
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

    acts_as_paranoid

    belongs_to :user
    has_many :clients
    has_many :projects
    has_many :results
    has_many :client_projects

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
      @reporting_spm_id ||= clients&.first&.reporting_spm_id
    end

    def comparison_spm_id
      @comparison_spm_id ||= clients&.first&.comparison_spm_id
    end

    def self.default_project_type_codes
      GrdaWarehouse::Hud::Project::SPM_PROJECT_TYPE_CODES
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
        :coc_code,
        :project_type_codes,
        :project_ids,
        :project_group_ids,
        :data_source_ids,
      ]
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
        f = ::Filters::HudFilterBase.new(user_id: filter_user_id)
        f.update((options || {}).merge(comparison_pattern: :prior_year).with_indifferent_access)
        f.update(start: f.end - 1.years + 1.days)
        f
      end
    end

    def self.known_params
      return ::Filters::HudFilterBase.new.known_params if PerformanceMeasurement::Goal.include_project_options?

      [:end, :coc_code]
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
      @goal_config ||= PerformanceMeasurement::Goal.for_coc(coc_code)
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
      _('CoC Performance Measurement Dashboard')
    end

    def multiple_project_types?
      true
    end

    def default_project_types
      GrdaWarehouse::Hud::Project::SPM_PROJECT_TYPE_CODES
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

    private def add_clients(report_clients)
      # Run CoC-wide SPMs for year prior to selected date and period 2 years prior
      # add records for each client to indicate which projects they were enrolled in within the report window
      project_clients = Set.new
      involved_projects = Set.new
      run_spm.each do |variant_name, spec|
        spm_fields.each do |parts|
          cells = parts[:cells]
          cells.each do |cell|
            spm_clients = answer_clients(spec[:report], *cell)
            spm_clients.each do |spm_client|
              report_client = report_clients[spm_client[:client_id]] || Client.new(report_id: id, client_id: spm_client[:client_id])
              report_client[:dob] = spm_client[:dob]
              report_client[:veteran] = spm_client[:veteran]
              report_client[:source_client_personal_ids] ||= spm_client[:source_client_personal_ids]
              # Age may vary based on which SPM questions the client is included in, just pick the first one.
              report_client["#{variant_name}_age"] ||= spm_client["#{parts[:measure]}_reporting_age"]
              # HoH status may vary, just note if they were ever an HoH
              report_client["#{variant_name}_hoh"] ||= spm_client["#{parts[:measure]}_head_of_household"] || false
              project_id = spm_client[parts[:project_source]]
              involved_projects << project_id
              parts[:questions].each do |question|
                report_client["#{variant_name}_#{question[:name]}"] = question[:value_calculation].call(spm_client)
                project_clients << {
                  report_id: id,
                  client_id: spm_client[:client_id],
                  project_id: project_id,
                  for_question: question[:name], # allows limiting for a specific response
                  period: variant_name,
                }
              end
              if parts.key?(:client_project_rows)
                parts[:client_project_rows].each do |cpr|
                  project_clients << cpr.call(spm_client, project_id, variant_name)
                end
              end

              report_client["#{variant_name}_spm_id"] = spec[:report].id
              report_clients[spm_client[:client_id]] = report_client
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

            parts[:value_calculation].call(:project_ids, client_id, data).each do |project_id|
              involved_projects << project_id
              project_clients << {
                report_id: id,
                client_id: client_id,
                project_id: project_id,
                for_question: parts[:key], # allows limiting for a specific response
                period: variant_name,
              }
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

            # These are only system level
            project_clients << {
              report_id: id,
              client_id: client_id,
              project_id: nil,
              for_question: parts[:key], # allows limiting for a specific response
              period: variant_name,
            }
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
      ClientProject.import!(project_clients.to_a.compact, batch_size: 5_000)
      universe.add_universe_members(report_clients)
    end

    private def answer(report, table, cell)
      report.answer(question: table, cell: cell).summary
    end

    private def answer_clients(report, table, cell)
      report.answer(question: table, cell: cell).universe_members.preload(:universe_membership).map(&:universe_membership)
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

    private def extra_calculations # rubocop:disable Metrics/AbcSize
      extras = [
        {
          key: :served_on_pit_date,
          data: ->(filter) {
            {}.tap do |project_types_by_client_id|
              report_scope.joins(:service_history_services, :project, :client).
                where(shs_t[:date].eq(filter.pit_date)).
                homeless.distinct.
                pluck(:client_id, c_t[:DOB], p_t[:id], :housing_status_at_entry, :head_of_household).
                each do |client_id, dob, project_id, housing_status_at_entry, head_of_household|
                  project_types_by_client_id[client_id] ||= {
                    value: true,
                    project_ids: Set.new,
                    dob: dob,
                    housing_status_at_entry: housing_status_at_entry,
                    head_of_household: head_of_household,
                  }
                  project_types_by_client_id[client_id][:project_ids] << project_id
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
              report_scope.joins(:service_history_services, :project, :client).
                # where(shs_t[:date].eq(filter.pit_date)). # removed to become yearly to match SPM M3 3.2
                so.distinct.
                pluck(:client_id, c_t[:DOB], p_t[:id], :housing_status_at_entry, :head_of_household).
                each do |client_id, dob, project_id, housing_status_at_entry, head_of_household|
                  project_types_by_client_id[client_id] ||= {
                    value: true,
                    project_ids: Set.new,
                    dob: dob,
                    housing_status_at_entry: housing_status_at_entry,
                    head_of_household: head_of_household,
                  }
                  project_types_by_client_id[client_id][:project_ids] << project_id
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
                in_project_type([1, 2, 4, 8]).
                distinct
              dobs = scope.pluck(:client_id, c_t[:DOB]).to_h
              scope.group(:client_id, p_t[:id]).
                count(shs_t[:date]).
                each do |(client_id, project_id), days|
                  days_by_client_id[client_id] ||= { value: [], project_ids: Set.new, dob: nil }
                  days_by_client_id[client_id][:value] << { project_id => days }
                  days_by_client_id[client_id][:project_ids] << project_id
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
                in_project_type([1, 2, 4, 8]).
                distinct
              dobs = scope.pluck(:client_id, c_t[:DOB]).to_h
              scope.group(:client_id, p_t[:id]).
                count(shs_t[:date]).
                each do |(client_id, project_id), days|
                  days_by_client_id[client_id] ||= { value: 0, project_ids: Set.new, dob: nil }
                  days_by_client_id[client_id][:value] += days
                  days_by_client_id[client_id][:project_ids] << project_id
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
                in_project_type([1, 2, 4, 8]).
                distinct
              dobs = scope.pluck(:client_id, c_t[:DOB]).to_h
              scope.group(:client_id, p_t[:id]).
                count(shs_t[:date]).
                each do |(client_id, project_id), days|
                  days_by_client_id[client_id] ||= { value: 0, project_ids: Set.new, dob: nil }
                  days_by_client_id[client_id][:value] += days
                  days_by_client_id[client_id][:project_ids] << project_id
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
                in_project_type([1, 2, 4, 8]).
                distinct
              dobs = scope.pluck(:client_id, c_t[:DOB]).to_h
              scope.group(:client_id, p_t[:id]).
                count(shs_t[:date]).
                each do |(client_id, project_id), days|
                  days_by_client_id[client_id] ||= { value: [], project_ids: Set.new, dob: nil }
                  days_by_client_id[client_id][:value] << { project_id => days }
                  days_by_client_id[client_id][:project_ids] << project_id
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
                  days = (move_in - entry_date).to_i
                  days_by_client_id[client_id] ||= { value: 0, project_ids: Set.new, dob: nil }
                  days_by_client_id[client_id][:value] += days
                  days_by_client_id[client_id][:project_ids] << project_id
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
                  days_by_client_id[client_id] ||= { value: [], project_ids: Set.new, dob: nil }
                  days_by_client_id[client_id][:value] << { project_id => days }
                  days_by_client_id[client_id][:project_ids] << project_id
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
                  days_by_client_id[client_id] ||= { value: 0, project_ids: Set.new, dob: nil }
                  days_by_client_id[client_id][:value] += days
                  days_by_client_id[client_id][:project_ids] << project_id
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
                  days_by_client_id[client_id] ||= { value: 0, project_ids: Set.new, dob: nil }
                  days_by_client_id[client_id][:value] += days
                  days_by_client_id[client_id][:project_ids] << project_id
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
                  days_by_client_id[client_id] ||= { value: [], project_ids: Set.new, dob: nil }
                  days_by_client_id[client_id][:value] << { project_id => days }
                  days_by_client_id[client_id][:project_ids] << project_id
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

    private def summary_calculations
      [
        {
          key: :seen_in_range,
          value_calculation: ->(client, variant_name) {
            client["#{variant_name}_served_on_pit_date_sheltered"] ||
            client["#{variant_name}_served_on_pit_date_unsheltered"]
          },
        },
        {
          key: :retention_or_positive_destination,
          value_calculation: ->(client, variant_name) {
            return true if HudSpmReport::Generators::Fy2020::Base::PERMANENT_DESTINATIONS.include?(client.send("#{variant_name}_so_destination"))
            return true if HudSpmReport::Generators::Fy2020::Base::PERMANENT_DESTINATIONS.include?(client.send("#{variant_name}_es_sh_th_rrh_destination"))
            return true if HudSpmReport::Generators::Fy2020::Base::PERMANENT_DESTINATIONS_OR_STAYER.include?(client.send("#{variant_name}_moved_in_destination"))

            false
          },
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
      generator = HudSpmReport::Generators::Fy2020::Generator
      variants.each do |_, spec|
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
            start: filter.start - 1.years,
            end: filter.end - 1.years,
          },
        },
      }
    end

    def spm_fields # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      [
        {
          cells: [['3.2', 'C2']],
          title: 'Sheltered Clients',
          measure: :m3,
          history_source: :m3_history,
          project_source: :m3_project_id,
          questions: [
            {
              name: :served_on_pit_date_sheltered, # Poorly named, this is actually a yearly count
              value_calculation: ->(spm_client) { spm_client[:m3_active_project_types].present? },
            },
          ],
        },
        {
          cells: [['5.1', 'C4']],
          title: 'First Time',
          measure: :m5,
          history_source: :m5_history,
          project_source: :m5_project_id,
          questions: [
            {
              name: :first_time,
              value_calculation: ->(spm_client) { spm_client[:m5_active_project_types].present? && spm_client[:m5_recent_project_types].blank? },
            },
          ],
        },
        {
          cells: [['1a', 'C3']],
          title: 'Length of Time Homeless in ES, SH, TH',
          measure: :m1,
          history_source: :m1_history,
          questions: [
            {
              name: :days_homeless_es_sh_th,
              value_calculation: ->(spm_client) { spm_client[:m1a_es_sh_th_days] },
            },
          ],
        },
        {
          cells: [['1b', 'C3']],
          title: 'Length of Time Homeless in ES, SH, TH, PH',
          measure: :m1,
          history_source: :m1_history,
          questions: [
            {
              name: :days_homeless_es_sh_th_ph,
              value_calculation: ->(spm_client) { spm_client[:m1b_es_sh_th_ph_days] },
            },
          ],
        },
        {
          cells: [['7a.1', 'C2']],
          title: 'Exits from SO',
          measure: :m7,
          history_source: :m7_history,
          project_source: :m7a1_project_id,
          questions: [
            {
              name: :so_destination,
              value_calculation: ->(spm_client) { spm_client[:m7a1_destination] },
            },
          ],
          client_project_rows: [
            ->(spm_client, project_id, variant_name) {
              return unless spm_client[:m7a1_destination].present?

              {
                report_id: id,
                client_id: spm_client[:client_id],
                project_id: project_id,
                for_question: :so_destination,
                period: variant_name,
              }
            },
            ->(spm_client, project_id, variant_name) {
              # list from drivers/hud_spm_report/app/models/hud_spm_report/generators/fy2020/measure_seven.rb
              # represents institutional and permanent destinations for 7a.1 C3 and C4
              return unless spm_client[:m7a1_destination].present? && spm_client[:m7a1_destination].in?(HudSpmReport::Generators::Fy2020::Base::PERMANENT_DESTINATIONS + [1, 15, 14, 27, 4, 18, 12, 13, 5, 2, 25, 32])

              {
                report_id: id,
                client_id: spm_client[:client_id],
                project_id: project_id,
                for_question: :so_destination_positive,
                period: variant_name,
              }
            },
          ],
        },
        {
          cells: [['7b.1', 'C2']],
          title: 'Exits from ES, SH, TH, RRH, PH with No Move-in',
          measure: :m7,
          history_source: :m7b_history,
          project_source: :m7b_project_id,
          questions: [
            {
              name: :es_sh_th_rrh_destination,
              value_calculation: ->(spm_client) { spm_client[:m7b1_destination] },
            },
          ],
          client_project_rows: [
            ->(spm_client, project_id, variant_name) {
              return unless spm_client[:m7b1_destination].present?

              {
                report_id: id,
                client_id: spm_client[:client_id],
                project_id: project_id,
                for_question: :es_sh_th_rrh_destination,
                period: variant_name,
              }
            },
            ->(spm_client, project_id, variant_name) {
              return unless spm_client[:m7b1_destination].present? && spm_client[:m7b1_destination].in?(HudSpmReport::Generators::Fy2020::Base::PERMANENT_DESTINATIONS)

              {
                report_id: id,
                client_id: spm_client[:client_id],
                project_id: project_id,
                for_question: :es_sh_th_rrh_destination_positive,
                period: variant_name,
              }
            },
          ],
        },
        {
          cells: [['7b.2', 'C2']],
          title: 'RRH, PH with Move-in or Permanent Exit',
          measure: :m7,
          history_source: :m7b_history,
          project_source: :m7b_project_id,
          questions: [
            {
              name: :moved_in_destination, # NOTE: destination 0 == stayer in the SPM
              value_calculation: ->(spm_client) { spm_client[:m7b2_destination] },
            },
          ],
          client_project_rows: [
            ->(spm_client, project_id, variant_name) {
              return unless spm_client[:m7b2_destination].present?

              {
                report_id: id,
                client_id: spm_client[:client_id],
                project_id: project_id,
                for_question: :moved_in_destination,
                period: variant_name,
              }
            },
            ->(spm_client, project_id, variant_name) {
              return unless spm_client[:m7b2_destination].present? && spm_client[:m7b2_destination].in?(HudSpmReport::Generators::Fy2020::Base::PERMANENT_DESTINATIONS_OR_STAYER)

              {
                report_id: id,
                client_id: spm_client[:client_id],
                project_id: project_id,
                for_question: :moved_in_destination_positive,
                period: variant_name,
              }
            },
          ],
        },
        {
          cells: [['2', 'B7']],
          title: 'Returned to Homelessness Within 6 months',
          measure: :m2,
          history_source: :m2_history,
          project_source: :m2_project_id,
          questions: [
            {
              name: :days_to_return,
              value_calculation: ->(spm_client) { spm_client[:m2_reentry_days] },
            },
            {
              name: :destination,
              value_calculation: ->(spm_client) { spm_client[:m2_exit_to_destination] },
            },
          ],
          # This needs to introspect on the number of days to re-entry and save off extra client_project records
          client_project_rows: [
            ->(spm_client, project_id, variant_name) {
              return unless spm_client[:m2_reentry_days].present? && spm_client[:m2_reentry_days].between?(1, 180)

              {
                report_id: id,
                client_id: spm_client[:client_id],
                project_id: project_id,
                for_question: :returned_in_six_months,
                period: variant_name,
              }
            },
            ->(spm_client, project_id, variant_name) {
              return unless spm_client[:m2_reentry_days].present? && spm_client[:m2_reentry_days].between?(1, 730)

              {
                report_id: id,
                client_id: spm_client[:client_id],
                project_id: project_id,
                for_question: :returned_in_two_years,
                period: variant_name,
              }
            },
            ->(spm_client, project_id, variant_name) {
              return unless spm_client[:m2_exit_to_destination].present? && HudSpmReport::Generators::Fy2020::Base::PERMANENT_DESTINATIONS.include?(spm_client[:m2_exit_to_destination])

              {
                report_id: id,
                client_id: spm_client[:client_id],
                project_id: project_id,
                for_question: :exited_to_permanent_destination,
                period: variant_name,
              }
            },
          ],
        },
        {
          cells: [['4.3', 'C2']],
          title: 'Stayers with Increased Income',
          measure: :m4,
          history_source: :m4_history,
          project_source: :m4_project_id,
          questions: [
            {
              name: :income_stayer,
              value_calculation: ->(spm_client) { spm_client[:m4_stayer] },
            },
            {
              name: :increased_income,
              value_calculation: ->(spm_client) { (spm_client[:m4_latest_income].presence || 0) > (spm_client[:m4_earliest_income].presence || 0) },
            },
          ],
          client_project_rows: [
            ->(spm_client, project_id, variant_name) {
              return unless spm_client[:m4_stayer] && (spm_client[:m4_latest_income].presence || 0) > (spm_client[:m4_earliest_income].presence || 0)

              {
                report_id: id,
                client_id: spm_client[:client_id],
                project_id: project_id,
                for_question: :increased_income__income_stayer,
                period: variant_name,
              }
            },
          ],
        },
        {
          cells: [['4.1', 'C2']],
          title: 'Stayers with Increased Earned Income',
          measure: :m4,
          history_source: :m4_history,
          project_source: :m4_project_id,
          questions: [
            {
              name: :earned_income_stayer,
              value_calculation: ->(spm_client) { (spm_client[:m4_latest_earned_income].presence || 0) > (spm_client[:m4_earliest_earned_income].presence || 0) },
            },
          ],
          client_project_rows: [
            ->(spm_client, project_id, variant_name) {
              return unless spm_client[:m4_stayer] && (spm_client[:m4_latest_earned_income].presence || 0) > (spm_client[:m4_earliest_earned_income].presence || 0)

              {
                report_id: id,
                client_id: spm_client[:client_id],
                project_id: project_id,
                for_question: :increased_income__earned_income_stayer,
                period: variant_name,
              }
            },
          ],
        },
        {
          cells: [['4.2', 'C2']],
          title: 'Stayers with Increased Non-Cash Income',
          measure: :m4,
          history_source: :m4_history,
          project_source: :m4_project_id,
          questions: [
            {
              name: :non_employment_income_stayer,
              value_calculation: ->(spm_client) { (spm_client[:m4_latest_non_earned_income].presence || 0) > (spm_client[:m4_earliest_non_earned_income].presence || 0) },
            },
          ],
          client_project_rows: [
            ->(spm_client, project_id, variant_name) {
              return unless spm_client[:m4_stayer] && (spm_client[:m4_latest_non_earned_income].presence || 0) > (spm_client[:m4_earliest_non_earned_income].presence || 0)

              {
                report_id: id,
                client_id: spm_client[:client_id],
                project_id: project_id,
                for_question: :increased_income__non_earned_income_stayer,
                period: variant_name,
              }
            },
          ],
        },
        {
          cells: [['4.6', 'C2']],
          title: 'Leavers with Increased Income',
          measure: :m4,
          history_source: :m4_history,
          project_source: :m4_project_id,
          questions: [
            {
              name: :income_leaver,
              value_calculation: ->(spm_client) { spm_client[:m4_stayer] == false },
            },
            {
              name: :increased_income,
              value_calculation: ->(spm_client) { (spm_client[:m4_latest_income].presence || 0) > (spm_client[:m4_earliest_income].presence || 0) },
            },
          ],
          client_project_rows: [
            ->(spm_client, project_id, variant_name) {
              return unless ! spm_client[:m4_stayer] && (spm_client[:m4_latest_income].presence || 0) > (spm_client[:m4_earliest_income].presence || 0)

              {
                report_id: id,
                client_id: spm_client[:client_id],
                project_id: project_id,
                for_question: :increased_income__income_leaver,
                period: variant_name,
              }
            },
          ],
        },
        {
          cells: [['4.4', 'C2']],
          title: 'Leavers with Increased Earned Income',
          measure: :m4,
          history_source: :m4_history,
          project_source: :m4_project_id,
          questions: [
            {
              name: :earned_income_leaver,
              value_calculation: ->(spm_client) { (spm_client[:m4_latest_earned_income].presence || 0) > (spm_client[:m4_earliest_earned_income].presence || 0) },
            },
          ],
          client_project_rows: [
            ->(spm_client, project_id, variant_name) {
              return unless ! spm_client[:m4_stayer] && (spm_client[:m4_latest_earned_income].presence || 0) > (spm_client[:m4_earliest_earned_income].presence || 0)

              {
                report_id: id,
                client_id: spm_client[:client_id],
                project_id: project_id,
                for_question: :increased_income__earned_income_leaver,
                period: variant_name,
              }
            },
          ],
        },
        {
          cells: [['4.5', 'C2']],
          title: 'Leavers with Increased Non-Cash Income',
          measure: :m4,
          history_source: :m4_history,
          project_source: :m4_project_id,
          questions: [
            {
              name: :non_employment_income_leaver,
              value_calculation: ->(spm_client) { (spm_client[:m4_latest_non_earned_income].presence || 0) > (spm_client[:m4_earliest_non_earned_income].presence || 0) },
            },
          ],
          client_project_rows: [
            ->(spm_client, project_id, variant_name) {
              return unless ! spm_client[:m4_stayer] && (spm_client[:m4_latest_non_earned_income].presence || 0) > (spm_client[:m4_earliest_non_earned_income].presence || 0)

              {
                report_id: id,
                client_id: spm_client[:client_id],
                project_id: project_id,
                for_question: :increased_income__non_earned_income_leaver,
                period: variant_name,
              }
            },
          ],
        },
      ]
    end
  end
end
