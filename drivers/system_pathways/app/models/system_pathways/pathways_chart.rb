###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https:#//github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
require 'memery'

module SystemPathways
  class PathwaysChart
    include ArelHelper
    include Memery
    include SystemPathways::ChartBase

    # returns an object with arrays for entering and leaving
    memoize def combinations_for(label)
      incoming = combinations.select { |row| row[:target] == label }.sort_by { |m| node_weights[m[:source]] }.reverse
      outgoing = combinations.select { |row| row[:source] == label }.sort_by { |m| node_weights[m[:target]] }.reverse
      enrolled_count = incoming.map { |m| m[:value] }.sum # should be equivalent to node_clients(label).distinct.count but without the query
      days_enrolled = node_clients(label).pluck(sp_e_t[:stay_length])
      days_before_move_in = node_clients(label).pluck(sp_e_t[:days_to_move_in]).reject(&:blank?)
      days_after_move_in_to_exit = node_clients(label).pluck(sp_e_t[:days_to_exit_after_move_in]).reject(&:blank?)
      OpenStruct.new(
        label: label,
        enrolled: enrolled_count,
        days_enrolled: average(days_enrolled.sum, days_enrolled.count).round,
        days_before_move_in: average(days_before_move_in.sum, days_before_move_in.count).round,
        days_after_move_in_to_exit: average(days_after_move_in_to_exit.sum, days_after_move_in_to_exit.count).round,
        incoming: incoming,
        outgoing: outgoing,
      )
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

          destination_lookup.map do |destination_label, dest|
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
  end
end
