###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Filters
  class StepRange < ::Filters::FilterBase
    attribute :route, String, lazy: false, default: ->(o, _) { o.available_routes.first }
    attribute :first_step, String, lazy: false, default: ->(o, _) { o.ordered_steps&.first&.first }
    attribute :second_step, String, lazy: false, default: ->(o, _) { o.ordered_steps[o.ordered_steps&.first&.first]&.first }
    attribute :unit, String, default: 'day'
    attribute :interesting_date, String, default: 'created'

    def units
      if Rails.env.development?
        ['week', 'day', 'hour', 'minute', 'second']
      else
        ['week', 'day']
      end
    end

    def available_interesting_dates
      {
        'Match Started' => 'created',
        'Move-in Date' => 'move_in',
      }
    end

    def interesting_column
      return :client_move_in_date if interesting_date == 'move_in'

      :match_started_at
    end

    # hash from steps to steps that may follow them
    def ordered_steps
      @ordered_steps ||= begin
        scope = GrdaWarehouse::CasReport.on_route(route)
        step_order = scope.distinct.
          pluck(:match_step, :decision_order).to_h

        # Build SQL to find followup steps
        sql = <<~SQL
          WITH followup_steps AS (
            SELECT DISTINCT d1.match_step,
                          d2.match_step as followup_step,
                          d2.decision_order as followup_order
            FROM cas_reports d1
            INNER JOIN cas_reports d2
              ON d2.client_id = d1.client_id
              AND d2.match_id = d1.match_id
              AND d2.decision_order < d1.decision_order
            WHERE d1.match_route = ?
          )
          SELECT match_step,
                 array_agg('(' || followup_order || ') ' || followup_step ORDER BY followup_order) as followups
          FROM followup_steps
          GROUP BY match_step
          HAVING array_length(array_agg(followup_step), 1) > 0
        SQL

        followups = scope.connection.execute(
          scope.sanitize_sql_array([sql, route])
        ).each_with_object({}) do |row, hash|
          hash[row['match_step']] = row['followups'].tr('{}', '').split(',')
        end

        followups.sort_by { |step, _| step_order[step] }.map do |step, followup_steps|
          ["(#{step_order[step]}) #{step}", followup_steps]
        end.to_h
      end
    end

    def available_routes
      @available_routes ||= GrdaWarehouse::CasReport.match_routes
    end
  end
end
