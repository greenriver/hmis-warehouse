###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SystemPathways::ChartBase
  extend ActiveSupport::Concern

  included do
    attr_accessor :report, :filter, :config, :show_filter, :details_filter
    def initialize(report:, filter:, show_filter: nil, details_filter: nil)
      self.report = report
      self.filter = filter
      self.show_filter = show_filter
      self.details_filter = details_filter
      self.config = GrdaWarehouse::SystemColor.first
    end

    def clients
      @report.clients.joins(:enrollments)
    end

    def describe_filter_as_html(keys = nil, inline: false, limited: true)
      keys ||= known_params
      filter.describe_filter_as_html(keys, inline: inline, limited: limited)
    end

    def describe_detail_filter_as_html(keys = nil, inline: false, limited: true)
      keys ||= known_params
      details_filter&.describe_filter_as_html(keys, inline: inline, limited: limited)
    end

    def self.known_params
      [
        :ethnicities,
        :races,
        :veteran_statuses,
        :household_type,
        :hoh_only,
        :involves_ce,
        :chronic_status,
        :disabling_condition,
        :chronic_status, # don't ask, but we use this in the details section
      ]
    end

    def known_params
      self.class.known_params
    end

    def long_project_type(project_type_brief)
      number = HudUtility.project_type_number(project_type_brief)
      HudUtility.project_type(number)
    end

    def filtered_clients
      scope = clients
      scope = filter_for_race(scope)
      scope = filter_for_ethnicity(scope)
      scope = filter_for_veteran_status(scope)
      scope = filter_for_ce_involvement(scope)
      scope = filter_for_head_of_household(scope)
      scope = filter_for_chronic_at_entry(scope)
      scope = filter_for_disabling_condition(scope)
      scope
    end

    def client_word
      return 'Households' if filter.hoh_only

      'Clients'
    end

    def sanitized_node(node)
      return node if node.in?(['Returns to Homelessness', 'Served by Homeless System'])

      available = report.class.available_project_types.map do |p_type|
        HudUtility.project_type_brief(p_type)
      end + destination_lookup.keys + ph_projects.values

      available.detect { |m| m == node }
    end

    def destination_lookup
      {
        'Permanent Destinations' => 'destination_permanent',
        'Homeless Destinations' => 'destination_homeless',
        'Institutional Destinations' => 'destination_institutional',
        'Temporary Destinations' => 'destination_temporary',
        'Other Destinations' => 'destination_other',
      }
    end

    private def ph_projects
      [
        'PH - PSH',
        'PH - PH',
        'PH - OPH',
        'PH - RRH',
      ].map { |m| [m, "#{m} Pre-Move in"] }.to_h
    end

    def average(value, count)
      return 0 unless count.positive?

      value.to_f / count
    end

    private def filter_for_disabling_condition(scope)
      scope = scope.merge(SystemPathways::Enrollment.where(disabling_condition: filter.disabling_condition)) unless filter.disabling_condition.nil?
      scope = scope.merge(SystemPathways::Enrollment.where(disabling_condition: show_filter.disabling_condition)) unless show_filter&.disabling_condition.nil?
      scope = scope.merge(SystemPathways::Enrollment.where(disabling_condition: details_filter.disabling_condition)) unless details_filter&.disabling_condition.nil?
      scope
    end

    private def filter_for_chronic_at_entry(scope)
      scope = scope.merge(SystemPathways::Enrollment.where(chronic_at_entry: filter.chronic_status)) unless filter.chronic_status.nil?
      scope = scope.merge(SystemPathways::Enrollment.where(chronic_at_entry: show_filter.chronic_status)) unless show_filter&.chronic_status.nil?
      scope = scope.merge(SystemPathways::Enrollment.where(chronic_at_entry: details_filter.chronic_status)) unless details_filter&.chronic_status.nil?

      scope
    end

    private def filter_for_race(scope)
      scope = filter_for_race_with_filter(scope, filter)
      scope = filter_for_race_with_filter(scope, show_filter) if show_filter
      scope = filter_for_race_with_filter(scope, details_filter) if details_filter
      scope
    end

    private def filter_for_race_with_filter(scope, race_filter)
      race_scope = nil
      race_filter.races.each do |column|
        next if column == 'MultiRacial'

        race_scope = add_alternative(race_scope, SystemPathways::Client.where(column.underscore.to_sym => true))
      end
      # Include anyone who has more than one race listed, anded with any previous alternatives
      race_scope ||= scope
      race_scope = race_scope.where(id: multi_racial_clients(scope).select(:id)) if race_filter.races.include?('MultiRacial')
      scope.merge(race_scope)
    end

    private def multi_racial_clients(scope)
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
      scope.where(Arel.sql(columns.join(' + ')).gt(1))
    end

    private def add_alternative(scope, alternative)
      if scope.nil?
        alternative
      else
        scope.or(alternative)
      end
    end

    private def filter_for_ethnicity(scope)
      scope = scope.where(ethnicity: filter.ethnicities) if filter.ethnicities.present?
      scope = scope.where(ethnicity: show_filter.ethnicities) if show_filter&.ethnicities.present?
      scope = scope.where(ethnicity: details_filter.ethnicities) if details_filter&.ethnicities.present?
      scope
    end

    private def filter_for_veteran_status(scope)
      scope = scope.where(veteran_status: filter.veteran_statuses) if filter.veteran_statuses.present?
      scope = scope.where(veteran_status: show_filter&.veteran_statuses) if show_filter&.veteran_statuses.present?
      scope = scope.where(veteran_status: details_filter&.veteran_statuses) if details_filter&.veteran_statuses.present?
      scope
    end

    private def filter_for_ce_involvement(scope)
      scope = scope.where(involves_ce: true) if filter.involves_ce == 'Yes'
      scope = scope.where(involves_ce: true) if show_filter&.involves_ce == 'Yes'
      scope = scope.where(involves_ce: true) if details_filter&.involves_ce == 'Yes'
      scope = scope.where(involves_ce: false) if filter.involves_ce == 'No'
      scope = scope.where(involves_ce: false) if show_filter&.involves_ce == 'No'
      scope = scope.where(involves_ce: false) if details_filter&.involves_ce == 'No'
      scope = scope.where(ce_assessment: true) if filter.involves_ce == 'With CE Assessment'
      scope = scope.where(ce_assessment: true) if show_filter&.involves_ce == 'With CE Assessment'
      scope = scope.where(ce_assessment: true) if details_filter&.involves_ce == 'With CE Assessment'

      scope
    end

    private def filter_for_head_of_household(scope)
      scope.merge(SystemPathways::Enrollment.where(relationship_to_hoh: 1)) if filter.hoh_only
      scope.merge(SystemPathways::Enrollment.where(relationship_to_hoh: 1)) if show_filter&.hoh_only
      scope.merge(SystemPathways::Enrollment.where(relationship_to_hoh: 1)) if details_filter&.hoh_only
      scope
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
      if to.in?(destination_lookup.values)
        final_transition_clients(from, to)
      elsif to.nil? || to == 'Returns to Homelessness'
        # join final enrollment because everyone should only have one
        SystemPathways::Enrollment.where(final_enrollment: true).
          joins(:client).
          merge(filtered_clients.where.not(returned_project_type: nil)).
          distinct
      else
        SystemPathways::Enrollment.where(from_project_type: from, project_type: to).
          joins(:client).
          merge(filtered_clients.joins(:enrollments)).
          distinct
      end
    end

    def final_transition_clients(exit_from, destination_category)
      SystemPathways::Enrollment.
        where(project_type: exit_from, final_enrollment: true).
        where(sp_e_t[:destination].eq(sp_c_t[:destination])).
        joins(:client).
        merge(filtered_clients.where(destination_category => true)).
        distinct
    end

    def node_clients(node)
      if node == 'Served by Homeless System'
        # join final enrollment because everyone should only have one
        SystemPathways::Enrollment.where(final_enrollment: true).
          joins(:client).
          merge(filtered_clients).
          distinct
      elsif node.in?(destination_lookup.keys)
        destination_category = destination_lookup[node]
        SystemPathways::Enrollment.where(final_enrollment: true).
          where(sp_e_t[:destination].eq(sp_c_t[:destination])).
          joins(:client).
          merge(filtered_clients.where(destination_category => true)).
          distinct
      elsif node.in?(ph_projects.values)
        to_project_type = HudUtility.project_type_number(ph_projects.invert[node])
        SystemPathways::Enrollment.where(project_type: to_project_type).
          where.not(days_to_move_in: nil).
          joins(:client).
          merge(filtered_clients).
          distinct
      elsif node == 'Returns to Homelessness'
        # join final enrollment because everyone should only have one
        SystemPathways::Enrollment.where(final_enrollment: true).
          joins(:client).
          merge(filtered_clients.where.not(returned_project_type: nil)).
          distinct
      else
        to_project_type = HudUtility.project_type_number(node)
        SystemPathways::Enrollment.where(project_type: to_project_type).
          joins(:client).
          merge(filtered_clients).
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

    private def veteran_statuses
      @veteran_statuses ||= HudLists.no_yes_reasons_for_missing_data_map
    end

    private def chronic_at_entries
      @chronic_at_entries ||= { false => 'No', true => 'Yes' }
    end

    private def involves_ces
      @involves_ces ||= { false => 'No', true => 'Yes' }
    end

    private def disabling_conditions
      @disabling_conditions ||= HudLists.no_yes_reasons_for_missing_data_map
    end

    private def as_table(data, headers)
      [].tap do |table|
        table << headers
        data.each do |k, values|
          table << [k] + values.values
        end
      end
    end

    private def remove_all_zero_rows(columns)
      all_zero = {}
      columns.drop(1).each do |row|
        row.each.with_index do |v, i|
          if i.zero?
            all_zero[i] = false
            next
          end

          all_zero[i] = true if all_zero[i].nil?
          all_zero[i] = false if v.positive?
        end
      end
      zeros = all_zero.values
      zero_columns = zeros.each_index.select { |i| zeros[i] == true }
      columns.each do |row|
        row.reject!.with_index { |_, i| i.in?(zero_columns) }
      end
      columns
    end

    private def race_columns
      @report.race_col_lookup.map { |k, hud_k| [k, HudUtility.race(hud_k)] }.to_h
    end

    private def race_col_lookup
      @report.race_col_lookup
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
          project_type: 13,
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
