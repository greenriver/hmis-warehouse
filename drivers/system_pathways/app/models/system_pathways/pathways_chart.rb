###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https:#//github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SystemPathways
  class PathwaysChart
    include ArelHelper
    attr_accessor :report, :filter
    def initialize(report:, filter:)
      self.report = report
      self.filter = filter
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

    def transition_clients(from, to)
      if to.in?(report.destination_lookup.values)
        final_transition_clients(from, to)
      elsif to.nil? # 'Returns to Homelessness'
        clients.where.not(returned_project_type: nil).
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
      if node.in?(report.destination_lookup.keys)
        destination_category = report.destination_lookup[node]
        filtered_clients.where(destination_category => true).
          joins(:enrollments).
          merge(
            SystemPathways::Enrollment.where(final_enrollment: true).
              where(sp_e_t[:destination].eq(sp_c_t[:destination])),
          ).distinct
      elsif node == 'Returns to Homelessness'
        clients.where.not(returned_project_type: nil).
          distinct
      else
        to_project_type = HudUtility.project_type_number(node)
        filtered_clients.joins(:enrollments).
          merge(SystemPathways::Enrollment.where(project_type: to_project_type)).
          distinct
      end
    end

    private def sp_c_t
      Client.arel_table
    end

    private def sp_e_t
      Enrollment.arel_table
    end

    # returns an object with arrays for entering and leaving
    def combinations_for(label)
      incoming = combinations.select { |row| row[:target] == label }.sort_by { |m| node_weights[m[:source]] }.reverse
      outgoing = combinations.select { |row| row[:source] == label }.sort_by { |m| node_weights[m[:target]] }.reverse
      enrolled_count = incoming.map { |m| m[:value] }.sum # should be equivalent to node_clients(label).distinct.count but without the query
      days_enrolled = node_clients(label).pluck(sp_e_t[:stay_length])
      days_before_move_in = node_clients(label).pluck(sp_e_t[:days_to_move_in]).reject(&:blank?)
      days_after_move_in_to_exit = node_clients(label).pluck(sp_e_t[:days_to_exit_after_move_in]).reject(&:blank?)
      {
        label: label,
        enrolled: enrolled_count,
        days_enrolled: average(days_enrolled.sum, days_enrolled.count).round,
        days_before_move_in: average(days_before_move_in.sum, days_before_move_in.count).round,
        days_after_move_in_to_exit: average(days_after_move_in_to_exit.sum, days_after_move_in_to_exit.count).round,
        incoming: incoming,
        outgoing: outgoing,
      }
    end

    def average(value, count)
      return 0 unless count.positive?

      value.to_f / count
    end

    private def combinations
      @combinations ||= report.allowed_states.map do |source, project_types|
        project_types.map do |target|
          source_label = project_type_label_lookup(source)
          target_label = project_type_label_lookup(target)
          count = transition_clients(source, target).count
          combination = []
          combination << {
            source: source_label,
            target: target_label,
            value: count,
          }

          next combination unless source.nil?

          report.destination_lookup.map do |destination_label, dest|
            destination_count = transition_clients(target, dest).count
            next unless destination_count.positive?

            combination << {
              source: target_label,
              target: destination_label,
              value: destination_count,
            }
          end
          combination
        end
      end.compact.flatten << {
        source: 'Permanent Destinations',
        target: 'Returns to Homelessness',
        value: transition_clients('Permanent Destinations', 'Returns to Homelessness').count,
      }
    end

    private def project_type_label_lookup(key)
      return 'Served by Homeless System' unless key.present?

      HudUtility.project_type_brief(key)
    end

    def chart_data
      combinations
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

    private def nodes
      {
        'Served by Homeless System': {
          color: '#5878A3',
          weight: 0,
          column: 0,
        },
        'ES': {
          color: '#85B5B2',
          weight: -1,
          column: 2,
        },
        'SH': {
          color: '#85B5B2',
          weight: -1,
          column: 2,
        },
        'TH': {
          color: '#A77C9F',
          weight: 2,
          column: 3,
        },
        'SO': {
          color: '#E49344',
          weight: 5,
          column: 1,
        },
        'PH - RRH': {
          color: '#D1605E',
          weight: 0,
          column: 4,
        },
        'PH - PSH': {
          color: '#E7CA60',
          weight: 11,
          column: 5,
        },
        'PH - PH': {
          color: '#E7CA60',
          weight: 11,
          column: 5,
        },
        'PH - OPH': {
          color: '#E7CA60',
          weight: 11,
          column: 5,
        },
        'Institutional Destinations': {
          color: '#808080',
          weight: 6,
          column: 6,
        },
        'Temporary Destinations': {
          color: '#808080',
          weight: 5,
          column: 6,
        },
        'Other Destinations': {
          color: '#808080',
          weight: 4,
          column: 6,
        },
        'Homeless Destinations': {
          color: '#808080',
          weight: 3,
          column: 6,
        },
        'Permanent Destinations': {
          color: '#6A9F58',
          weight: 10,
          column: 6,
        },
        'Returns to Homelessness': {
          color: '#967762',
          weight: 11,
          column: 7,
        },
      }
    end
  end
end
