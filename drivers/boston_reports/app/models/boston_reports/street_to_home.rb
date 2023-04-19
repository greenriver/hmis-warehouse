###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module BostonReports
  class StreetToHome
    include Filter::ControlSections
    include Filter::FilterScopes
    include ActionView::Helpers::NumberHelper
    include HudReports::Util
    include ArelHelper

    attr_reader :filter, :config
    attr_accessor :comparison_pattern, :project_type_codes

    def initialize(filter)
      @filter = filter
      @config = BostonReports::Config.first_or_create(&:default_colors)
    end

    def self.default_filter_options
      {
        filters: {
          cohort_column: :user_select_12,
          cohort_column_voucher_type: :user_select_9,
          cohort_column_housed_date: :housed_date,
          cohort_column_matched_date: :user_date_4,
        },
      }
    end

    def self.viewable_by(user)
      GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: url).
        viewable_by(user).exists?
    end

    def self.url
      'boston_reports/warehouse_reports/street_to_homes'
    end

    def self.available_section_types
      [
        'dashboard',
        'stage_by_cohort',
        'active_stage_by_cohort_by_voucher_type',
        'internal',
        'external',
      ]
    end

    def percent(numerator:, denominator:)
      return 0 unless numerator&.positive? && denominator&.positive?

      (numerator.to_f / denominator * 100).round
    end

    def section_ready?(_section)
      true
    end

    def multiple_project_types?
      true
    end

    protected def build_control_sections
      [
        build_general_control_section,
      ]
    end

    def report_path_array
      [
        :boston_reports,
        :warehouse_reports,
        :street_to_homes,
      ]
    end

    def filter_path_array
      [:filters] + report_path_array
    end

    def include_comparison?
      comparison_pattern != :no_comparison_period
    end

    def detail_link_base
      "#{section_subpath}details"
    end

    def section_subpath
      "#{self.class.url}/"
    end

    def detail_path_array
      [:details] + report_path_array
    end

    def housed_string
      'Moved-In'
    end

    def matched_string
      'Matched, Not Yet Housed'
    end

    def un_matched_string
      'Un-matched'
    end

    def necessary_selections_made?
      filter.cohort_ids.present? &&
      filter.cohort_column.present? &&
      filter.cohort_column_voucher_type.present? &&
      filter.cohort_column_housed_date.present? &&
      filter.cohort_column_matched_date.present?
    end

    private def build_general_control_section
      ::Filters::UiControlSection.new(id: 'general').tap do |section|
        section.add_control(
          id: 'cohorts',
          required: true,
          value: @filter.cohorts,
        )
        section.add_control(
          id: 'cohort_column',
          required: true,
          value: @filter.cohort_column,
        )
        section.add_control(
          id: 'cohort_column_voucher_type',
          required: true,
          value: @filter.cohort_column_voucher_type,
        )
        section.add_control(
          id: 'cohort_column_housed_date',
          required: true,
          value: @filter.cohort_column_housed_date,
        )
        section.add_control(
          id: 'cohort_column_matched_date',
          required: true,
          value: @filter.cohort_column_matched_date,
        )
      end
    end

    private def report_scope
      return GrdaWarehouse::CohortClient.none unless filter.cohort_ids.present? && filter.cohort_column.present?

      GrdaWarehouse::CohortClient.
        where(cohort_id: filter.cohort_ids).
        where.not(filter.cohort_column => nil). # only include clients with a cohort or the report starts to have mis-calculations
        where.not(filter.cohort_column => '').
        preload(client: :source_clients)
    end

    def detail_headers
      {
        'First Name' => ->(cc, download: false) {
          if download
            CohortColumns::FirstName.new(cohort_client: cc).value(cc)
          else
            CohortColumns::FirstName.new(cohort_client: cc).display_read_only(filter.user)
          end
        },
        'Last Name' => ->(cc, download: false) {
          if download
            CohortColumns::LastName.new(cohort_client: cc).value(cc)
          else
            CohortColumns::LastName.new(cohort_client: cc).display_read_only(filter.user)
          end
        },
        'Race' => ->(cc, download: false) { # rubocop:disable Lint/UnusedBlockArgument
          CohortColumns::Race.new(cohort_client: cc).display_read_only(filter.user)
        },
        'Ethnicity' => ->(cc, download: false) { # rubocop:disable Lint/UnusedBlockArgument
          CohortColumns::Ethnicity.new(cohort_client: cc).display_read_only(filter.user)
        },
        'Cohort' => ->(cc, download: false) { # rubocop:disable Lint/UnusedBlockArgument
          cc[filter.cohort_column]
        },
        voucher_type_instance.title => ->(cc, download: false) { # rubocop:disable Lint/UnusedBlockArgument
          voucher_type_instance.class.new(cohort_client: cc).display_read_only(filter.user)
        },
        voucher_type_instance.title => ->(cc, download: false) {
          if download
            voucher_type_instance.class.new(cohort_client: cc).value(cc)
          else
            voucher_type_instance.class.new(cohort_client: cc).display_read_only(filter.user)
          end
        },
        voucher_date_instance.title => ->(cc, download: false) {
          if download
            voucher_date_instance.class.new(cohort_client: cc).value(cc)
          else
            voucher_date_instance.class.new(cohort_client: cc).display_read_only(filter.user)
          end
        },
        housed_date_instance.title => ->(cc, download: false) {
          if download
            housed_date_instance.class.new(cohort_client: cc).value(cc)
          else
            housed_date_instance.class.new(cohort_client: cc).display_read_only(filter.user)
          end
        },
      }
    end

    def invert_columns(columns)
      columns.map.with_index do |data, i|
        if i.zero?
          data
        else
          data.map.with_index do |v, j|
            if j.zero? || v.blank?
              v
            else
              0 - v
            end
          end
        end
      end
    end

    def allowed_sets(sets)
      clients.keys & sets
    end

    def client_details(sets)
      return [] unless sets.present?

      sets.uniq!
      return unless allowed_sets(sets).sort == sets.uniq.sort

      # get the ids of any client in all sets
      ids = sets.map do |s|
        clients[s]
      end.reduce(:&)

      # Enforce only one row per client_id
      report_scope.where(client_id: ids).index_by(&:client_id).values
    end

    def clients
      @clients ||= {}.tap do |counts|
        # Setup buckets
        all_client_breakdowns.each do |(key, _)|
          counts[key.to_s] ||= Set.new
        end
        cohort_names.each do |cohort|
          counts[cohort] ||= Set.new
        end
        stages.each do |(key, _)|
          counts[key.to_s] ||= Set.new
        end
        voucher_types.each do |voucher_type|
          counts[voucher_type] ||= Set.new
        end
        races.each_value do |race|
          counts[race] ||= Set.new
        end
        ethnicities.each_value do |ethnicity|
          counts[ethnicity] ||= Set.new
        end

        report_scope.find_each do |client|
          all_client_breakdowns.each do |(key, breakdown)|
            counts[key.to_s] << client.client_id if breakdown[:calculation].call(client)
          end
          cohort_names.each do |cohort|
            counts[cohort] << client.client_id if client[filter.cohort_column] == cohort
          end
          stages.each do |(key, stage)|
            counts[key.to_s] << client.client_id if stage[:calculation].call(client)
          end
          voucher_types.each do |voucher_type|
            counts[voucher_type] << client.client_id if client[voucher_type_column] == voucher_type && client[voucher_date_instance.column].present?
          end
          # Loop over all races so we don't end up with missing categories
          races.each do |race_key, race|
            CohortColumns::Race.new.value(client).each do |value|
              counts[race] << client.client_id if value == race_key
            end
          end
          # Loop over all ethnicities so we don't end up with missing categories
          ethnicities.each_value do |ethnicity|
            CohortColumns::Ethnicity.new.value(client).each do |value|
              counts[ethnicity] << client.client_id if value == ethnicity
            end
          end
        end
      end
    end

    def summary_counts
      @summary_counts ||= {}.tap do |data|
        data['total'] = all_client_breakdowns['Total'].slice(:label, :count)
        cohort_names.each do |cohort|
          data[cohort] = {
            label: cohort,
            count: clients[cohort].count,
          }
        end
      end
    end

    def counts_by_stage
      @counts_by_stage ||= {}.tap do |data|
        data['type'] = 'bar'
        data['columns'] = []
        data['colors'] = {}
        { 'Inactive' => all_client_breakdowns['Inactive'] }.merge(stages).each.with_index do |(key, stage), i|
          row = [stage[:label], clients[key.to_s].count]
          data['columns'] << row
          data['colors'][stage[:label]] = config["breakdown_2_color_#{i}"]
        end
      end
    end

    def housed_by_cohort
      @housed_by_cohort ||= {}.tap do |data|
        active_months = stages[housed_string][:scope].pluck(housed_date_instance.column).
          reject(&:blank?).
          map(&:to_date).
          reject { |d| d < Date.new(2010, 1, 1) }. # Ignore move-in dates pre-2010 (they are probably mistakes)
          map(&:beginning_of_month).uniq.sort
        months = [active_months.first]
        month = active_months.first
        while month < active_months.last
          month += 1.months
          months << month
        end
        data['type'] = 'line'
        data['x'] = 'dates'
        data['columns'] = [['dates'] + months]
        data['colors'] = {}
        overall_for_dates = {}
        cohort_names.each.with_index do |cohort, i|
          row = [cohort]
          ids = clients[cohort] & clients[housed_string]
          dates = report_scope.where(client_id: ids).
            pluck(housed_date_instance.column).
            reject(&:blank?).
            map(&:beginning_of_month)
          months.each do |month_start|
            active_count = dates.count { |date| date == month_start }
            row << active_count

            overall_for_dates[month_start] ||= 0
            overall_for_dates[month_start] += active_count
          end
          data['columns'] << row
          data['colors'][cohort] = config["breakdown_1_color_#{i}"]
        end
        data['columns'] << ['Total'] + overall_for_dates.values
        data['colors']['Total'] = config['total_color']
      end
    end

    def matched_by_cohort
      @matched_by_cohort ||= {}.tap do |data|
        active_months = stages[matched_string][:scope].pluck(voucher_date_instance.column).
          reject(&:blank?).
          map { |d| Date.parse(d).beginning_of_month }.
          reject { |d| d < Date.new(2010, 1, 1) }. # Ignore voucher dates pre-2010 (they are probably mistakes)
          uniq.sort
        months = [active_months.first]
        month = active_months.first
        while month < active_months.last
          month += 1.months
          months << month
        end
        data['type'] = 'line'
        data['x'] = 'dates'
        data['columns'] = [['dates'] + months]
        data['colors'] = {}
        overall_for_dates = {}
        cohort_names.each.with_index do |cohort, i|
          row = [cohort]
          ids = clients[cohort] & clients[matched_string]
          dates = report_scope.where(client_id: ids).
            pluck(voucher_date_instance.column).
            reject(&:blank?).
            map { |d| Date.parse(d).beginning_of_month }

          months.each do |month_start|
            active_count = dates.count { |date| date == month_start }
            row << active_count

            overall_for_dates[month_start] ||= 0
            overall_for_dates[month_start] += active_count
          end
          data['columns'] << row
          data['colors'][cohort] = config["breakdown_1_color_#{i}"]
        end
        data['columns'] << ['Total'] + overall_for_dates.values
        data['colors']['Total'] = config['total_color']
      end
    end

    def race_by_cohort
      @race_by_cohort ||= {}.tap do |charts|
        cohort_names.each do |cohort|
          cohort_slug = cohort.parameterize(separator: '_')
          charts[cohort_slug] = {}
          charts[cohort_slug]['type'] = 'pie'
          charts[cohort_slug]['columns'] = []
          charts[cohort_slug]['colors'] = {}
          charts[cohort_slug]['labels'] = { 'colors' => {} }
          races.each_value.with_index do |race, i|
            charts[cohort_slug]['columns'] << [race, (clients[cohort] & clients[race]).count]
            charts[cohort_slug]['colors'][race] = config["breakdown_3_color_#{i}"]
            charts[cohort_slug]['labels']['colors'][race] = config.foreground_color(config["breakdown_3_color_#{i}"])
          end
        end
      end
    end

    def stacked_race_by_stage
      @stacked_race_by_stage ||= {}.tap do |data|
        data['x'] = 'x'
        data['type'] = 'bar'
        data['stack'] = { normalize: true }
        data['columns'] = [['x'] + ['Inactive'] + stages.values.map { |d| d[:label] }]
        data['groups'] = [races.values]
        data['colors'] = {}
        data['labels'] = { 'colors' => {} }
        races.each_value.with_index do |race, i|
          row = [race]
          { 'Inactive' => all_client_breakdowns['Inactive'] }.merge(stages).each_key do |k|
            row << (clients[k.to_s] & clients[race]).count
          end
          data['columns'] << row
          data['colors'][race] = config["breakdown_3_color_#{i}"]
          data['labels']['colors'][race] = config.foreground_color(config["breakdown_3_color_#{i}"])
        end
      end
    end

    def stacked_race_by_cohort
      @stacked_race_by_cohort ||= {}.tap do |data|
        data['x'] = 'x'
        data['type'] = 'bar'
        data['stack'] = { normalize: true }
        data['columns'] = [['x'] + cohort_names]
        data['groups'] = [races.values]
        data['colors'] = {}
        data['labels'] = { 'colors' => {} }
        races.each_value.with_index do |race, i|
          row = [race]
          cohort_names.each do |cohort|
            row << (clients[cohort] & clients[race]).count
          end
          data['columns'] << row
          data['colors'][race] = config["breakdown_3_color_#{i}"]
          data['labels']['colors'][race] = config.foreground_color(config["breakdown_3_color_#{i}"])
        end
      end
    end

    def stacked_stage_by_race
      @stacked_stage_by_race ||= {}.tap do |data|
        data['x'] = 'x'
        data['type'] = 'bar'
        data['stack'] = { normalize: true }
        data['columns'] = [['x'] + races.values]
        data['groups'] = [['Inactive'] + stages.values.map { |d| d[:label] }]
        data['colors'] = {}
        data['labels'] = { 'colors' => {} }
        { 'Inactive' => all_client_breakdowns['Inactive'] }.merge(stages).each.with_index do |(k, stage), i|
          row = [stage[:label]]
          races.each_value do |race|
            row << (clients[k.to_s] & clients[race]).count
          end
          data['columns'] << row
          data['colors'][stage[:label]] = config["breakdown_2_color_#{i}"]
          data['labels']['colors'][stage[:label]] = config.foreground_color(config["breakdown_2_color_#{i}"])
        end
      end
    end

    def stacked_cohort_by_race
      @stacked_cohort_by_race ||= {}.tap do |data|
        data['x'] = 'x'
        data['type'] = 'bar'
        data['stack'] = { normalize: true }
        data['columns'] = [['x'] + races.values]
        data['groups'] = [cohort_names]
        data['colors'] = {}
        data['labels'] = { 'colors' => {} }
        cohort_names.each.with_index do |cohort, i|
          row = [cohort]
          races.each_value do |race|
            row << (clients[cohort] & clients[race]).count
          end
          data['columns'] << row
          data['colors'][cohort] = config["breakdown_1_color_#{i}"]
          data['labels']['colors'][cohort] = config.foreground_color(config["breakdown_1_color_#{i}"])
        end
      end
    end

    def stacked_ethnicity_by_stage
      @stacked_ethnicity_by_stage ||= {}.tap do |data|
        data['x'] = 'x'
        data['type'] = 'bar'
        data['stack'] = { normalize: true }
        data['columns'] = [['x'] + ['Inactive'] + stages.values.map { |d| d[:label] }]
        data['groups'] = [ethnicities.values]
        data['colors'] = {}
        data['labels'] = { 'colors' => {} }
        ethnicities.each_value.with_index do |ethnicity, i|
          row = [ethnicity]
          { 'Inactive' => all_client_breakdowns['Inactive'] }.merge(stages).each_key do |k|
            row << (clients[k.to_s] & clients[ethnicity]).count
          end
          data['columns'] << row
          data['colors'][ethnicity] = config["breakdown_3_color_#{i}"]
          data['labels']['colors'][ethnicity] = config.foreground_color(config["breakdown_3_color_#{i}"])
        end
      end
    end

    def stacked_ethnicity_by_cohort
      @stacked_ethnicity_by_cohort ||= {}.tap do |data|
        data['x'] = 'x'
        data['type'] = 'bar'
        data['stack'] = { normalize: true }
        data['columns'] = [['x'] + cohort_names]
        data['groups'] = [ethnicities.values]
        data['colors'] = {}
        data['labels'] = { 'colors' => {} }
        ethnicities.each_value.with_index do |ethnicity, i|
          row = [ethnicity]
          cohort_names.each do |cohort|
            row << (clients[cohort] & clients[ethnicity]).count
          end
          data['columns'] << row
          data['colors'][ethnicity] = config["breakdown_2_color_#{i}"]
          data['labels']['colors'][ethnicity] = config.foreground_color(config["breakdown_2_color_#{i}"])
        end
      end
    end

    def stacked_stage_by_ethnicity
      @stacked_stage_by_ethnicity ||= {}.tap do |data|
        data['x'] = 'x'
        data['type'] = 'bar'
        data['stack'] = { normalize: true }
        data['columns'] = [['x'] + ethnicities.values]
        data['groups'] = [['Inactive'] + stages.values.map { |d| d[:label] }]
        data['colors'] = {}
        data['labels'] = { 'colors' => {} }
        { 'Inactive' => all_client_breakdowns['Inactive'] }.merge(stages).each.with_index do |(k, stage), i|
          row = [stage[:label]]
          ethnicities.each_value do |ethnicity|
            row << (clients[k.to_s] & clients[ethnicity]).count
          end
          data['columns'] << row
          data['colors'][stage[:label]] = config["breakdown_2_color_#{i}"]
          data['labels']['colors'][stage[:label]] = config.foreground_color(config["breakdown_2_color_#{i}"])
        end
      end
    end

    def stacked_cohort_by_ethnicity
      @stacked_cohort_by_ethnicity ||= {}.tap do |data|
        data['x'] = 'x'
        data['type'] = 'bar'
        data['stack'] = { normalize: true }
        data['columns'] = [['x'] + ethnicities.values]
        data['groups'] = [cohort_names]
        data['colors'] = {}
        data['labels'] = { 'colors' => {} }
        cohort_names.each.with_index do |cohort, i|
          row = [cohort]
          ethnicities.each_value do |ethnicity|
            row << (clients[cohort] & clients[ethnicity]).count
          end
          data['columns'] << row
          data['colors'][cohort] = config["breakdown_1_color_#{i}"]
          data['labels']['colors'][cohort] = config.foreground_color(config["breakdown_1_color_#{i}"])
        end
      end
    end

    def ethnicity_by_cohort
      @ethnicity_by_cohort ||= {}.tap do |charts|
        cohort_names.each do |cohort|
          cohort_slug = cohort.parameterize(separator: '_')
          charts[cohort_slug] = {}
          charts[cohort_slug]['type'] = 'pie'
          charts[cohort_slug]['columns'] = []
          charts[cohort_slug]['colors'] = {}
          charts[cohort_slug]['labels'] = { 'colors' => {} }
          ethnicities.each_value.with_index do |ethnicity, i|
            charts[cohort_slug]['columns'] << [ethnicity, (clients[cohort] & clients[ethnicity]).count]
            charts[cohort_slug]['colors'][ethnicity] = config["breakdown_4_color_#{i}"]
            charts[cohort_slug]['labels']['colors'][ethnicity] = config.foreground_color(config["breakdown_4_color_#{i}"])
          end
        end
      end
    end

    def stage_by_cohort
      @stage_by_cohort ||= {}.tap do |data|
        data['x'] = 'x'
        data['type'] = 'bar'
        data['groups'] = [['Inactive'] + stages.values.map { |d| d[:label] }]
        data['colors'] = {}
        data['columns'] = [['x', *cohort_names]]
        { 'Inactive' => all_client_breakdowns['Inactive'] }.merge(stages).each.with_index do |(key, stage), i|
          row = [stage[:label]]
          data['colors'][stage[:label]] = config["breakdown_2_color_#{i}"]
          cohort_names.each do |cohort|
            row << (clients[cohort] & clients[key.to_s]).count
          end
          data['columns'] << row
        end
      end
    end

    def cohort_by_stage
      @cohort_by_stage ||= {}.tap do |data|
        data['x'] = 'x'
        data['type'] = 'bar'
        data['groups'] = [cohort_names]
        data['colors'] = {}
        data['columns'] = [['x', *{ 'Inactive' => all_client_breakdowns['Inactive'] }.merge(stages).values.map { |d| d[:label] }]]
        cohort_names.each.with_index do |cohort, i|
          row = [cohort]
          data['colors'][cohort] = config["breakdown_1_color_#{i}"]
          { 'Inactive' => all_client_breakdowns['Inactive'] }.merge(stages).each do |(key, _stage)|
            row << (clients[cohort] & clients[key.to_s]).count
          end
          data['columns'] << row
        end
      end
    end

    def matched_cohort_by_voucher_type
      @matched_cohort_by_voucher_type ||= {}.tap do |data|
        data['x'] = 'x'
        data['type'] = 'bar'
        data['groups'] = [cohort_names]
        data['colors'] = {}
        data['labels'] = { 'colors' => {}, 'centered' => true }
        data['columns'] = [['x', *voucher_types]]
        data['types'] = {
          'Total' => 'scatter',
        }
        totals = voucher_types.map { |type| [type, 0] }.to_h
        cohort_names.each.with_index do |cohort, i|
          row = [cohort]
          bg_color = config["breakdown_1_color_#{i}"]
          data['colors'][cohort] = bg_color
          data['labels']['colors'][cohort] = config.foreground_color(bg_color)
          voucher_types.each do |type|
            count = (clients[matched_string] & clients[cohort] & clients[type]).count
            row << count
            totals[type] += count
          end
          data['columns'] << row
        end
        data['columns'] << ['Total'] + totals.values
        data['labels']['colors']['Total'] = config['total_color']
        data['colors']['Total'] = config['total_color']
      end
    end

    def moved_in_cohort_by_voucher_type
      @moved_in_cohort_by_voucher_type ||= {}.tap do |data|
        data['x'] = 'x'
        data['type'] = 'bar'
        data['groups'] = [cohort_names]
        data['colors'] = {}
        data['labels'] = { 'colors' => {}, 'centered' => true }
        data['columns'] = [['x', *voucher_types]]
        data['types'] = {
          'Total' => 'scatter',
        }
        totals = voucher_types.map { |type| [type, 0] }.to_h
        cohort_names.each.with_index do |cohort, i|
          row = [cohort]
          bg_color = config["breakdown_1_color_#{i}"]
          data['colors'][cohort] = bg_color
          data['labels']['colors'][cohort] = config.foreground_color(bg_color)
          voucher_types.each do |type|
            count = (clients[housed_string] & clients[cohort] & clients[type]).count
            row << count
            totals[type] += count
          end
          data['columns'] << row
        end
        data['columns'] << ['Total'] + totals.values
        data['labels']['colors']['Total'] = config['total_color']
        data['colors']['Total'] = config['total_color']
      end
    end

    private def all_client_breakdowns
      @all_client_breakdowns ||= {
        'Active' => {
          label: 'Active',
          calculation: ->(client) { client.active },
          count: report_scope.active.count,
          scope: report_scope.active,
        },
        'Inactive' => {
          label: 'Inactive',
          calculation: ->(client) { ! client.active },
          count: report_scope.inactive.count,
          scope: report_scope.inactive,
        },
        'Total' => {
          label: 'Total',
          calculation: ->(_client) { true },
          count: report_scope.count,
          scope: report_scope,
        },
      }
    end

    private def races
      ::HudLists.race_map
    end

    private def ethnicities
      ::HudLists.ethnicity_map.select { |id, _| id.in?([0, 1]) }
    end

    def cohort_names
      @cohort_names ||= report_scope.active.
        distinct.
        pluck(filter.cohort_column).sort
    end

    def all_stages
      (stages.map do |k, d|
        [k, d[:label]]
      end +
      all_client_breakdowns.map do |k, d|
        [k, d[:label]]
      end).to_h
    end

    def cohort_counts_by_all_stages
      @cohort_counts_by_all_stages || {}.tap do |data|
        cohort_names.each do |cohort|
          all_stages.each_key do |k|
            data[cohort] ||= {}
            ids = clients[cohort] & clients[k.to_s]
            data[cohort][k.to_s] = ids.count
          end
        end
        data['Total'] = {}
        cohort_names.each do |cohort|
          all_stages.each_key do |k|
            data['Total'][k.to_s] ||= 0
            data['Total'][k.to_s] += data[cohort][k.to_s]
          end
        end
      end
    end

    private def stages
      @stages ||= {}.tap do |s|
        if voucher_date_instance.present? && housed_date_instance.present?
          s[un_matched_string] = {
            label: un_matched_string,
            calculation: ->(client) { client[housed_date_instance.column].blank? && client[voucher_date_instance.column].blank? },
            scope: report_scope.active.where(c_client_t[voucher_date_instance.column].eq(nil).and(c_client_t[housed_date_instance.column].eq(nil))),
          }
          s[matched_string] = {
            label: matched_string,
            calculation: ->(client) { client[housed_date_instance.column].blank? && client[voucher_date_instance.column].present? },
            scope: report_scope.active.where(c_client_t[voucher_date_instance.column].not_eq(nil).and(c_client_t[housed_date_instance.column].eq(nil))),
          }
        end
        s[housed_string] = {
          label: housed_string,
          calculation: ->(client) { client[housed_date_instance.column].present? },
          scope: report_scope.active.where(c_client_t[housed_date_instance.column].not_eq(nil)),
        }
      end
    end

    private def voucher_type_column
      @voucher_type_column ||= voucher_type_instance&.column
    end

    private def voucher_date_instance
      @voucher_date_instance ||= GrdaWarehouse::Cohort.available_columns.detect { |c| c.column == filter.cohort_column_matched_date }
    end

    private def housed_date_instance
      @housed_date_instance ||= GrdaWarehouse::Cohort.available_columns.detect { |c| c.column == filter.cohort_column_housed_date }
    end

    private def voucher_type_instance
      @voucher_type_instance ||= GrdaWarehouse::Cohort.available_columns.detect { |c| c.column == filter.cohort_column_voucher_type }
    end

    private def voucher_types
      GrdaWarehouse::CohortColumnOption.active.ordered.
        where(cohort_column: voucher_type_column).
        pluck(:value)
    end

    def voucher_type_count
      voucher_types.count
    end

    # Get the PIT dates for the two prior years (this assumes last wednesday of January)
    def pit_dates
      @pit_dates ||= begin
        latest_date = if Date.current.month == 1
          pit_date(month: 1, before: 1.months.ago.to_date)
        else
          pit_date(month: 1, before: Date.current)
        end
        previous_date = pit_date(month: 1, before: latest_date - 11.months)
        [previous_date, latest_date]
      end
    end

    private def pit_columns
      [
        :client_id,
        *GrdaWarehouse::Hud::Client.race_fields.map { |f| c_t[f] },
        c_t[:Ethnicity],
      ]
    end

    private def pit_clients
      @pit_clients ||= GrdaWarehouse::ServiceHistoryService.joins(:client).
        where(date: pit_dates).
        pluck(*pit_columns)
    end

    def pit_races
      @pit_races ||= {}.tap do |counts|
        GrdaWarehouse::Hud::Client.race_fields.each.with_index do |key, i|
          counts[key] ||= { ids: Set.new, count: 0, pit_dates: pit_dates }
          # client_id is in the first column, followed by race fields, increment those by 1
          pit_clients.each do |row|
            counts[key][:ids] << row.first if row[i + 1] == 1
          end
          # Average last two PIT dates
          counts.each do |k, v|
            counts[k][:count] = v[:ids].count / pit_dates.count
          end
        end
      end
    end

    def pit_ethnicities
      @pit_ethnicities ||= {}.tap do |counts|
        ::HudLists.ethnicity_map.select { |id, _| id.in?([0, 1]) }.each do |key, label|
          counts[label] ||= { ids: Set.new, count: 0, pit_dates: pit_dates }
          # client_id is in the first column, ethnicity in the last
          pit_clients.each do |row|
            counts[label][:ids] << row.first if key == row.last
          end
          # Average last two PIT dates
          counts.each do |k, v|
            counts[k][:count] = v[:ids].count / pit_dates.count
          end
        end
      end
    end
  end
end
