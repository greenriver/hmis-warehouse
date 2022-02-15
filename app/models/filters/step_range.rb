###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
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
        scope = GrdaWarehouse::CasReport.on_route(route) # .started_between(start_date: @range.start, end_date: @range.end + 1.day)
        step_order = scope.distinct.
          pluck(:match_step, :decision_order).to_h
        steps = step_order.keys
        at = scope.arel_table
        at2 = at.dup
        at2.table_alias = 'at2'
        followups = steps.map do |step|
          followups = scope.where(
            at2.project(Arel.star).
              where(at2[:client_id].eq(at[:client_id])).
              where(at2[:match_id].eq(at[:match_id])).
              where(at2[:decision_order].lt(at[:decision_order])).
              where(at2[:match_step].eq(step)).
              exists,
          ).distinct.pluck(:match_step, :decision_order).
            map do |match_step, decision_order|
              "(#{decision_order}) #{match_step}"
            end
          [step, followups]
        end.to_h

        followups.select do |_, followup_steps|
          followup_steps.any?
        end.sort_by do |step, _|
          step_order[step]
        end.map do |step, followup_steps|
          [
            "(#{step_order[step]}) #{step}", followup_steps.sort
          ]
        end.to_h
      end
    end

    def available_routes
      @available_routes ||= GrdaWarehouse::CasReport.match_routes
    end
  end
end
