###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SystemPathways::ChartBase
  extend ActiveSupport::Concern

  included do
    attr_accessor :report, :filter, :config
    def initialize(report:, filter:)
      self.report = report
      self.filter = filter
      # TODO: this config should be moved to a more general Report config
      self.config = BostonReports::Config.first_or_create(&:default_colors)
    end

    def clients
      @report.clients.joins(:enrollments)
    end

    def filtered_clients
      scope = clients
      scope = filter_for_race(scope)
      scope = filter_for_ethnicity(scope)
      scope = filter_for_veteran_status(scope)
      scope = filter_for_ce_involvement(scope)
      scope = filter_for_head_of_household(scope)
      scope
    end

    def client_word
      return 'Households' if filter.hoh_only

      'Clients'
    end

    def average(value, count)
      return 0 unless count.positive?

      value.to_f / count
    end

    def chart_data(chart)
      data = case chart.to_s
      when 'ethnicity'
        {
          chart: 'ethnicity',
          data: ethnicity_data,
          table: as_table(ethnicity_counts, ['Project Type'] + ethnicities.values),
        }
      when 'race'
        {
          chart: 'race',
          data: race_data,
          table: as_table(race_counts, ['Project Type'] + races.values),
        }
      else
        {}
      end

      data
    end

    private def filter_for_race(scope)
      return scope unless filter.races.present?

      race_scope = nil
      filter.races.each do |column|
        next if column == 'MultiRacial'

        race_scope = add_alternative(race_scope, SystemPathways::Client.where(column.underscore.to_sym => true))
      end

      # Include anyone who has more than one race listed, anded with any previous alternatives
      race_scope ||= scope
      race_scope = race_scope.where(id: multi_racial_clients.select(:id)) if filter.races.include?('MultiRacial')
      scope.merge(race_scope)
    end

    private def multi_racial_clients
      # Looking at all races with responses of 1, where we have a sum > 1
      a_t = SystemPathways::Client.arel_table
      columns = [
        :am_ind_ak_native,
        :asian,
        :black_af_american,
        :native_hi_pacific,
        :white,
      ].map do |col|
        "CASE WHEN #{a_t[col].to_sql} THEN 1 ELSE 0 END"
      end
      scope.where(Arel.sql(columns.join(' + ')).between(2..98))
    end

    private def add_alternative(scope, alternative)
      if scope.nil?
        alternative
      else
        scope.or(alternative)
      end
    end

    private def filter_for_ethnicity(scope)
      return scope unless filter.ethnicities.present?

      scope.where(ethnicity: filter.ethnicities)
    end

    private def filter_for_veteran_status(scope)
      return scope unless filter.veteran_statuses.present?

      scope.where(veteran_status: filter.veteran_statuses)
    end

    private def filter_for_ce_involvement(scope)
      return scope unless filter.involves_ce

      scope.where(ce: true)
    end

    private def filter_for_head_of_household(scope)
      return scope unless filter.hoh_only

      scope.merge(Enrollment.where(relationship_to_hoh: 1))
    end

    def bg_color(label)
      target_colors[label]
    end

    def target_colors
      nodes.map { |k, data| [k, data[:color]] }.to_h
    end

    def node_weights
      nodes.map { |k, data| [k, data[:weight]] }.to_h
    end

    def node_columns
      nodes.map { |k, data| [k, data[:column]] }.to_h
    end

    def node_names
      nodes.keys
    end

    def project_type_node_names
      nodes.select { |_, n| n.key?(:project_type) }.keys
    end

    def project_type_node_names_with_data
      project_type_node_names.select do |label|
        combinations_for(label).enrolled.positive?
      end
    end

    def uses_move_in?(label)
      label.to_s.in?(['PH - RRH', 'PH - PSH', 'PH - PH', 'PH - OPH'])
    end

    def transition_clients(from, to)
      if to.in?(report.destination_lookup.values)
        final_transition_clients(from, to)
      elsif to.nil? || to == 'Returns to Homelessness'
        filtered_clients.where.not(returned_project_type: nil).
          distinct
      else
        filtered_clients.joins(:enrollments).
          merge(SystemPathways::Enrollment.where(from_project_type: from, project_type: to)).
          distinct
      end
    end

    def final_transition_clients(exit_from, destination_category)
      filtered_clients.where(destination_category => true).
        joins(:enrollments).
        merge(
          SystemPathways::Enrollment.
            where(project_type: exit_from, final_enrollment: true).
            where(sp_e_t[:destination].eq(sp_c_t[:destination])),
        ).
        distinct
    end

    def node_clients(node)
      if node == 'Served by Homeless System'
        filtered_clients.distinct
      elsif node.in?(report.destination_lookup.keys)
        destination_category = report.destination_lookup[node]
        filtered_clients.where(destination_category => true).
          joins(:enrollments).
          merge(
            SystemPathways::Enrollment.where(final_enrollment: true).
              where(sp_e_t[:destination].eq(sp_c_t[:destination])),
          ).distinct
      elsif node == 'Returns to Homelessness'
        filtered_clients.where.not(returned_project_type: nil).
          distinct
      else
        to_project_type = HudUtility.project_type_number(node)
        filtered_clients.joins(:enrollments).
          merge(SystemPathways::Enrollment.where(project_type: to_project_type)).
          distinct
      end
    end

    private def sp_c_t
      SystemPathways::Client.arel_table
    end

    private def sp_e_t
      SystemPathways::Enrollment.arel_table
    end

    private def pluck_to_hash(columns, scope)
      scope.pluck(*columns.keys).map do |row|
        Hash[columns.keys.zip(row)]
      end
    end

    private def races
      @races ||= HudLists.race_map
    end

    private def ethnicities
      @ethnicities ||= HudLists.ethnicity_map
    end

    private def as_table(data, headers)
      [].tap do |table|
        table << headers
        data.each do |k, values|
          table << [k] + values.values
        end
      end
    end

    private def race_columns
      HudLists.race_map.transform_keys(&:underscore)
    end

    private def race_col_lookup
      {
        'am_ind_ak_native' => 'AmIndAKNative',
        'asian' => 'Asian',
        'black_af_american' => 'BlackAfAmerican',
        'native_hi_pacific' => 'NativeHIPacific',
        'white' => 'White',
        'race_none' => 'RaceNone',
      }
    end

    private def nodes
      {
        'Served by Homeless System' => {
          color: '#5878A3',
          weight: 0,
          column: 0,
        },
        'ES' => {
          color: '#85B5B2',
          weight: -1,
          column: 2,
          project_type: 1,
        },
        'SH' => {
          color: '#85B5B2',
          weight: -1,
          column: 2,
          project_type: 8,
        },
        'TH' => {
          color: '#A77C9F',
          weight: 2,
          column: 3,
          project_type: 2,
        },
        'SO' => {
          color: '#E49344',
          weight: 5,
          column: 1,
          project_type: 4,
        },
        'PH - RRH' => {
          color: '#D1605E',
          weight: 0,
          column: 4,
        },
        'PH - PSH' => {
          color: '#E7CA60',
          weight: 11,
          column: 5,
          project_type: 3,
        },
        'PH - PH' => {
          color: '#E7CA60',
          weight: 11,
          column: 5,
          project_type: 9,
        },
        'PH - OPH' => {
          color: '#E7CA60',
          weight: 11,
          column: 5,
          project_type: 10,
        },
        'Institutional Destinations' => {
          color: '#808080',
          weight: 6,
          column: 6,
        },
        'Temporary Destinations' => {
          color: '#808080',
          weight: 5,
          column: 6,
        },
        'Other Destinations' => {
          color: '#808080',
          weight: 4,
          column: 6,
        },
        'Homeless Destinations' => {
          color: '#808080',
          weight: 3,
          column: 6,
        },
        'Permanent Destinations' => {
          color: '#6A9F58',
          weight: 10,
          column: 6,
        },
        'Returns to Homelessness' => {
          color: '#967762',
          weight: 11,
          column: 7,
        },
      }
    end
  end
end
