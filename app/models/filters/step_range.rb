module Filters
  class StepRange < ::ModelForm
    attribute :first,  String, lazy: true, default: -> (o,_) { o.ordered_steps&.first&.first }
    attribute :second, String, lazy: true, default: -> (o,_) { o.ordered_steps[o&.first]&.first }
    attribute :unit,   String, default: 'day'

    def units
      if Rails.env.development?
        %w( week day hour minute second )
      else
        %w( week day )
      end
    end

    # hash from steps to steps that may follow them
    def ordered_steps
      @ordered_steps ||= begin
        scope = GrdaWarehouse::CasReport#.started_between(start_date: @range.start, end_date: @range.end + 1.day)
        step_order = scope.distinct.
          pluck(:match_step, :decision_order).to_h
        steps = step_order.keys
        at = scope.arel_table
        at2 = Arel::Table.new at.table_name
        at2.table_alias = 'at2'
        followups = steps.map do |step|
          followups = scope.where(
            at2.project(Arel.star).
              where( at2[:client_id].      eq at[:client_id] ).
              where( at2[:match_id].       eq at[:match_id] ).
              where( at2[:decision_order]. lt at[:decision_order] ).
              where( at2[:match_step].     eq step ).
              exists
          ).distinct.pluck(:match_step, :decision_order).map do |match_step, decision_order|
            "(#{decision_order}) #{match_step}"
          end
          [ step, followups ]
        end.to_h
        
        followups.select do |_, followup_steps|
          followup_steps.any? 
        end.sort_by do |step,_| 
          step_order[step] 
        end.map do |step,followup_steps|
          [
            "(#{step_order[step]}) #{step}", followup_steps.sort
          ] 
        end.to_h
      end
    end
  end
end